import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import swaggerUi from 'swagger-ui-express';
import orderRouter from './routes/orders.js';
import { initializeRabbitMQ } from './config/rabbitmq.js';
import redisClient from './config/redis.js';
import { swaggerSpec } from './config/swagger.js';

const app = express();

// ── Middleware ───────────────────────────────────────────────────────────────

app.use(express.json());

// ── Swagger UI ───────────────────────────────────────────────────────────────

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/api-docs.json', (_req: Request, res: Response) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// ── Health check ─────────────────────────────────────────────────────────────

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
 *                   example: order-service
 */
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'order-service' });
});

// ── Routes ───────────────────────────────────────────────────────────────────

app.use('/', orderRouter);

// ── Global error handler ─────────────────────────────────────────────────────

interface PgError extends Error {
  code?: string;
}

app.use((err: PgError, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Error]', err.message, err.stack);

  // PostgreSQL unique violation
  if (err.code === '23505') {
    res.status(409).json({ error: 'Resource already exists', detail: err.message });
    return;
  }

  // PostgreSQL not-null / check constraint violation
  if (err.code === '23502' || err.code === '23514') {
    res.status(400).json({ error: 'Invalid data', detail: err.message });
    return;
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    res.status(422).json({ error: 'Referenced resource does not exist', detail: err.message });
    return;
  }

  res.status(500).json({ error: 'Internal server error' });
});

// ── Start ────────────────────────────────────────────────────────────────────

const PORT = parseInt(process.env['ORDER_SERVICE_PORT'] ?? '3002', 10);

// Initialize Redis and RabbitMQ connections on startup
(async () => {
  try {
    // Connect Redis
    if (redisClient.status !== 'ready' && redisClient.status !== 'connecting') {
      await redisClient.connect();
      console.info('[order-service] Redis connected');
    }

    // Connect RabbitMQ
    await initializeRabbitMQ();
    console.info('[order-service] RabbitMQ connected');

    app.listen(PORT, () => {
      console.info(`[order-service] Listening on port ${PORT}`);
      console.info(`[order-service] Swagger UI: http://localhost:${PORT}/api-docs`);
    });
  } catch (err) {
    console.error('[order-service] Failed to initialize:', err);
    process.exit(1);
  }
})();

export default app;
