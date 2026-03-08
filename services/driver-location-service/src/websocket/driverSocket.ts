import { WebSocketServer, WebSocket } from 'ws';
import { Server as HttpServer } from 'http';
import { query } from '../config/db.js';
import { updateDriverPosition } from '../services/locationService.js';
import { publishLocationUpdate } from '../services/publisher.js';
import { getActiveOrderId } from '../services/orderLookupService.js';
import type { GpsPing } from '../types/index.js';
import { validate as validateUUID } from 'uuid';

// In-memory map of active driver connections
const activeConnections = new Map<string, WebSocket>();

// Heartbeat tracking: map of driverId -> last pong timestamp
const heartbeatMap = new Map<string, number>();

const HEARTBEAT_INTERVAL_MS = 15_000; // 15 seconds
const HEARTBEAT_TIMEOUT_MS = 30_000; // 30 seconds

/**
 * Create and configure WebSocket server for driver connections
 */
export function createDriverSocketServer(httpServer: HttpServer): WebSocketServer {
  const wss = new WebSocketServer({
    server: httpServer,
    path: '/drivers/connect',
  });

  wss.on('connection', async (ws: WebSocket, req) => {
    // Extract driverId from query string
    // req.url format: /drivers/connect?driverId=xxx
    const url = new URL(req.url || '', `http://${req.headers.host || 'localhost'}`);
    const driverId = url.searchParams.get('driverId');

    // Validate driverId is present and valid UUID
    if (!driverId || !validateUUID(driverId)) {
      ws.close(4001, 'Unauthorized: Invalid driverId');
      return;
    }

    // Query PostgreSQL to verify driver exists and is active
    try {
      const result = await query<{ id: string; is_active: boolean }>(
        'SELECT id, is_active FROM drivers WHERE id = $1',
        [driverId],
      );

      if (result.rows.length === 0 || !result.rows[0].is_active) {
        ws.close(4001, 'Unauthorized: Driver not found or inactive');
        return;
      }

      // Register connection
      activeConnections.set(driverId, ws);
      heartbeatMap.set(driverId, Date.now());
      console.info(`[WebSocket] Driver ${driverId} connected`);

      // Handle messages
      ws.on('message', async (data: Buffer) => {
        try {
          const message = JSON.parse(data.toString());
          const { lat, lng, timestamp } = message;

          // Validate GPS data
          if (
            typeof lat !== 'number' ||
            typeof lng !== 'number' ||
            typeof timestamp !== 'number' ||
            lat < -90 ||
            lat > 90 ||
            lng < -180 ||
            lng > 180
          ) {
            ws.send(
              JSON.stringify({
                error: 'Invalid GPS data: lat must be -90 to 90, lng must be -180 to 180',
              }),
            );
            return;
          }

          const ping: GpsPing = {
            driverId,
            lat,
            lng,
            timestamp: timestamp || Date.now(),
          };

          // Lookup active orderId for this driver (fire-and-forget, cached)
          getActiveOrderId(driverId)
            .then((orderId) => {
              // Run Redis write (with path storage) and RabbitMQ publish in parallel
              Promise.allSettled([
                updateDriverPosition(ping, orderId),
                publishLocationUpdate(ping, orderId || undefined),
              ]).catch((err) => {
                console.error(`[WebSocket] Error processing GPS ping for driver ${driverId}:`, err);
                // Don't crash - just log the error
              });
            })
            .catch((err) => {
              // If order lookup fails, still update position without orderId
              console.warn(`[WebSocket] Error looking up order for driver ${driverId}:`, err);
              Promise.allSettled([
                updateDriverPosition(ping),
                publishLocationUpdate(ping),
              ]).catch((err2) => {
                console.error(`[WebSocket] Error processing GPS ping for driver ${driverId}:`, err2);
              });
            });
        } catch (err) {
          // Invalid JSON or other parse error
          ws.send(JSON.stringify({ error: 'Invalid message format' }));
          // Do NOT crash the process
        }
      });

      // Handle pong (response to ping)
      ws.on('pong', () => {
        heartbeatMap.set(driverId, Date.now());
      });

      // Handle close
      ws.on('close', (code, reason) => {
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        console.info(`[WebSocket] Driver ${driverId} disconnected (code: ${code}, reason: ${reason.toString()})`);
      });

      // Handle errors
      ws.on('error', (err) => {
        console.error(`[WebSocket] Error for driver ${driverId}:`, err.message);
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        // Do NOT crash the process
      });
    } catch (err) {
      const error = err as Error;
      console.error(`[WebSocket] Error validating driver ${driverId}:`, error.message);
      ws.close(4001, 'Unauthorized: Database error');
    }
  });

  // Start heartbeat: send ping frames every 15 seconds
  setInterval(() => {
    const now = Date.now();
    for (const [driverId, ws] of activeConnections.entries()) {
      const lastPong = heartbeatMap.get(driverId) || now;
      
      // If no pong received within timeout, terminate connection
      if (now - lastPong > HEARTBEAT_TIMEOUT_MS) {
        console.warn(`[WebSocket] Terminating dead connection for driver ${driverId}`);
        ws.terminate();
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        continue;
      }

      // Send ping frame
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      }
    }
  }, HEARTBEAT_INTERVAL_MS);

  return wss;
}

/**
 * Get count of active WebSocket connections
 */
export function getActiveConnectionCount(): number {
  return activeConnections.size;
}
