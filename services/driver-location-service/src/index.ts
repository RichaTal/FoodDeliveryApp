import express, { type Request, type Response, type ErrorRequestHandler } from 'express';
import { createServer } from 'http';
import dotenv from 'dotenv';
import swaggerUi from 'swagger-ui-express';
import { createDriverSocketServer, getActiveConnectionCount } from './websocket/driverSocket.js';
import { initializeKafka, disconnectKafka } from './config/kafka.js';
import redisClient from './config/redis.js';
import { cleanupExpiredDrivers } from './services/locationService.js';
import { startBatchWriter, stopBatchWriter } from './services/batchWriterService.js';
import driversRouter from './routes/drivers.js';
import { swaggerSpec } from './config/swagger.js';

dotenv.config();

const app = express();
const httpServer = createServer(app);

// Middleware
app.use(express.json());

// ── Swagger UI ───────────────────────────────────────────────────────────────

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/api-docs.json', (_req: Request, res: Response) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// Health check endpoint

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Health check
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Service is healthy
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: ok
 *                 service:
 *                   type: string
 *                   example: driver-location-service
 *                 activeConnections:
 *                   type: integer
 *                   description: Number of active WebSocket driver connections
 */
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'ok',
    service: 'driver-location-service',
    activeConnections: getActiveConnectionCount(),
  });
});

// Mount routes
app.use('/', driversRouter);

// Global error middleware
const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  console.error('[Express] Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
};
app.use(errorHandler);

// Initialize services and start server
async function start() {
  try {
    // Initialize Redis connection (only if not already connected/connecting)
    if (redisClient.status !== 'ready' && redisClient.status !== 'connecting') {
      await redisClient.connect();
      console.info('[Redis] Connected');
    } else {
      console.info('[Redis] Already connected or connecting');
    }

    // Initialize Kafka producer
    await initializeKafka();
    console.info('[Kafka] Producer initialized');

    // Create WebSocket server
    createDriverSocketServer(httpServer);
    console.info('[WebSocket] Server created on path /drivers/connect');

    // Start periodic TTL cleanup job (every 10 seconds)
    setInterval(async () => {
      try {
        const evictedCount = await cleanupExpiredDrivers();
        if (evictedCount > 0) {
          console.info(`[Cleanup] Evicted ${evictedCount} expired driver(s) from GEO set`);
        }
      } catch (err) {
        const error = err as Error;
        console.error('[Cleanup] Error during TTL cleanup:', error.message);
      }
    }, 10_000); // 10 seconds

    // Start batch writer for PostgreSQL path history
    startBatchWriter();

    // Start HTTP server
    const port = parseInt(process.env['DRIVER_LOCATION_PORT'] || '3003', 10);
    httpServer.listen(port, () => {
      console.info(`[Server] Driver Location Service listening on port ${port}`);
      console.info(`[Server] WebSocket endpoint: ws://localhost:${port}/drivers/connect`);
      console.info(`[Server] Swagger UI: http://localhost:${port}/api-docs`);
    });
  } catch (err) {
    const error = err as Error;
    console.error('[Startup] Fatal error:', error.message);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGTERM', async () => {
  console.info('[Shutdown] SIGTERM received, shutting down gracefully...');
  await stopBatchWriter();
  await disconnectKafka();
  httpServer.close(() => {
    console.info('[Shutdown] HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  console.info('[Shutdown] SIGINT received, shutting down gracefully...');
  await stopBatchWriter();
  await disconnectKafka();
  httpServer.close(() => {
    console.info('[Shutdown] HTTP server closed');
    process.exit(0);
  });
});

start();
