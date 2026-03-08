import express from 'express';
import { createServer } from 'http';
import dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';
import swaggerUi from 'swagger-ui-express';
import redisClient from './config/redis.js';
import { initializeRabbitMQ } from './config/rabbitmq.js';
import { initializeWebSocketServer, getActiveCustomerCount, getInstanceId } from './websocket/customerSocket.js';
import { startOrderConsumer } from './consumers/orderConsumer.js';
import { startLocationConsumer } from './consumers/locationConsumer.js';
import { swaggerSpec } from './config/swagger.js';

dotenv.config();

const INSTANCE_ID = process.env['INSTANCE_ID'] || uuidv4();
const PORT = parseInt(process.env['NOTIFICATION_PORT'] || '3004', 10);

const app = express();
const server = createServer(app);

// Middleware
app.use(express.json());

// ── Swagger UI ───────────────────────────────────────────────────────────────

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/api-docs.json', (_req: express.Request, res: express.Response) => {
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
 *               $ref: '#/components/schemas/HealthResponse'
 */
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'notification-service',
    instanceId: getInstanceId(),
    activeCustomers: getActiveCustomerCount(),
  });
});

// Global error handler
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('[Express] Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Startup sequence
async function start(): Promise<void> {
  try {
    console.info(`[NotificationService] Starting with instanceId: ${INSTANCE_ID}`);

    // 1. Connect Redis (only if not already connected/connecting)
    console.info('[NotificationService] Connecting to Redis...');
    if (redisClient.status !== 'ready' && redisClient.status !== 'connecting') {
      await redisClient.connect();
      console.info('[NotificationService] Redis connected');
    } else {
      console.info('[NotificationService] Redis already connected or connecting');
    }

    // 2. Connect RabbitMQ and initialize channel
    console.info('[NotificationService] Connecting to RabbitMQ...');
    await initializeRabbitMQ();
    console.info('[NotificationService] RabbitMQ connected');

    // 3. Start WebSocket server (attach to HTTP server)
    console.info('[NotificationService] Initializing WebSocket server...');
    initializeWebSocketServer(server);
    console.info('[NotificationService] WebSocket server initialized');

    // 4. Start Order consumer
    console.info('[NotificationService] Starting order consumer...');
    await startOrderConsumer();
    console.info('[NotificationService] Order consumer started');

    // 5. Start Location consumer
    console.info('[NotificationService] Starting location consumer...');
    await startLocationConsumer();
    console.info('[NotificationService] Location consumer started');

    // 6. Start HTTP server
    server.listen(PORT, () => {
      console.info(`[NotificationService] Server listening on port ${PORT}`);
      console.info(`[NotificationService] WebSocket endpoint: ws://localhost:${PORT}/track/{orderId}`);
      console.info(`[NotificationService] Swagger UI: http://localhost:${PORT}/api-docs`);
    });
  } catch (error) {
    const err = error as Error;
    console.error('[NotificationService] Failed to start:', err);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.info('[NotificationService] SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.info('[NotificationService] HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  console.info('[NotificationService] SIGINT received, shutting down gracefully...');
  server.close(() => {
    console.info('[NotificationService] HTTP server closed');
    process.exit(0);
  });
});

// Start the service
start();
