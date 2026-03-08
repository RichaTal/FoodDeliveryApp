import { WebSocket, WebSocketServer } from 'ws';
import { v4 as uuidv4 } from 'uuid';
import { registerSession, removeSession, refreshSession } from '../services/sessionService.js';
import { WebSocketMessage } from '../types/index.js';

const INSTANCE_ID = process.env['INSTANCE_ID'] || uuidv4();

// In-memory map of orderId -> WebSocket connection for this instance
const customerConnections = new Map<string, WebSocket>();

let wss: WebSocketServer | null = null;

/**
 * Initialize the WebSocket server attached to the HTTP server
 */
export function initializeWebSocketServer(server: any): void {
  wss = new WebSocketServer({
    server,
    // No path filter - we'll manually check the path in the connection handler
  });

  wss.on('connection', (ws: WebSocket, request: any) => {
    // Parse orderId from URL path (e.g., /track/abc-123)
    const requestUrl = request.url || '';
    const pathMatch = requestUrl.match(/^\/track\/([^\/\?]+)/);
    
    if (!pathMatch) {
      console.warn(`[WebSocket] Invalid path: ${requestUrl}`);
      ws.close(4000, 'Invalid path. Expected /track/{orderId}');
      return;
    }

    const orderId = pathMatch[1];

    // Validate orderId is a valid UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!orderId || !uuidRegex.test(orderId)) {
      console.warn(`[WebSocket] Invalid orderId: ${orderId}`);
      ws.close(4000, 'Invalid orderId format');
      return;
    }

    // Register session in Redis
    registerSession(orderId, INSTANCE_ID)
      .then(() => {
        // Store WebSocket connection in local map
        customerConnections.set(orderId, ws);
        console.info(`[WebSocket] Customer connected for orderId: ${orderId} (instance: ${INSTANCE_ID})`);

        // Send initial confirmation frame
        const connectedMessage: WebSocketMessage = {
          type: 'CONNECTED',
          payload: { orderId },
        };
        ws.send(JSON.stringify(connectedMessage));
      })
      .catch((err) => {
        console.error(`[WebSocket] Failed to register session for ${orderId}:`, err);
        ws.close(4001, 'Failed to register session');
      });

    // Handle close
    ws.on('close', () => {
      customerConnections.delete(orderId);
      removeSession(orderId).catch((err) => {
        console.error(`[WebSocket] Failed to remove session for ${orderId}:`, err);
      });
      console.info(`[WebSocket] Customer disconnected for orderId: ${orderId}`);
    });

    // Handle errors
    ws.on('error', (error: Error) => {
      console.error(`[WebSocket] Error for orderId ${orderId}:`, error);
    });

    // Heartbeat: ping every 15 seconds
    const pingInterval = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      } else {
        clearInterval(pingInterval);
      }
    }, 15000);

    // Timeout: if no pong received within 30 seconds, close connection
    let pongReceived = true;
    ws.on('pong', () => {
      pongReceived = true;
    });

    const timeoutInterval = setInterval(() => {
      if (!pongReceived) {
        console.warn(`[WebSocket] No pong received for orderId ${orderId}, closing connection`);
        ws.terminate();
        clearInterval(timeoutInterval);
        clearInterval(pingInterval);
      } else {
        pongReceived = false;
      }
    }, 30000);

    ws.on('close', () => {
      clearInterval(pingInterval);
      clearInterval(timeoutInterval);
    });
  });

  console.info('[WebSocket] Customer WebSocket server initialized on /track');
}

/**
 * Send a message to a customer WebSocket connection
 * Returns true if message was sent, false if customer is not on this instance or disconnected
 */
export function sendToCustomer(orderId: string, message: WebSocketMessage): boolean {
  const ws = customerConnections.get(orderId);
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    return false;
  }

  try {
    ws.send(JSON.stringify(message));
    // Refresh session TTL on activity
    refreshSession(orderId).catch((err) => {
      console.error(`[WebSocket] Failed to refresh session for ${orderId}:`, err);
    });
    return true;
  } catch (error) {
    console.error(`[WebSocket] Failed to send message to ${orderId}:`, error);
    return false;
  }
}

/**
 * Get the number of active customer connections on this instance
 */
export function getActiveCustomerCount(): number {
  return customerConnections.size;
}

/**
 * Get the instance ID
 */
export function getInstanceId(): string {
  return INSTANCE_ID;
}
