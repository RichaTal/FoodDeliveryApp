import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import swaggerUi from 'swagger-ui-express';
import restaurantRouter from './routes/restaurants.js';
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
 *                   example: restaurant-menu-service
 */
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'restaurant-menu-service' });
});

// ── Routes ───────────────────────────────────────────────────────────────────

app.use('/', restaurantRouter);

// ── Global error handler ─────────────────────────────────────────────────────

interface PgError extends Error {
  code?: string;
}

app.use((err: PgError, _req: Request, res: Response, _next: NextFunction) => {
  // No logging to avoid performance overhead

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

// ── Start (only when run directly, not when imported in tests) ────────────────

export async function start(): Promise<void> {
  const PORT = parseInt(process.env['RESTAURANT_MENU_PORT'] ?? '3001', 10);

  try {
    if (redisClient.status !== 'ready' && redisClient.status !== 'connecting') {
      await redisClient.connect();
      // No logging to avoid performance overhead
    }
  } catch (err) {
    // Silently handle connection failure - no logging to avoid performance overhead
    void err; // Suppress unused variable warning
  }

  app.listen(PORT, () => {
    console.info(`[restaurant-menu-service] Listening on port ${PORT}`);
    console.info(`[restaurant-menu-service] Swagger UI: http://localhost:${PORT}/api-docs`);
  });
}

// Only start server when this file is the entry point (not during tests/imports)
if (process.env['NODE_ENV'] !== 'test') {
  start();
}

export default app;
