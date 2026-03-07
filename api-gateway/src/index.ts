import dotenv from 'dotenv';
import express, { Request, Response } from 'express';
import cors from 'cors';
import * as http from 'http';
import { requestLogger } from './middleware/requestLogger.js';
import {
  restaurantMenuProxy,
  orderProxy,
  driverLocationProxy,
} from './proxy/httpProxy.js';
import { setupWebSocketProxy } from './proxy/wsProxy.js';
import { SERVICE_URLS } from './config/routes.js';

dotenv.config();

const app = express();
const server = http.createServer(app);

// Middleware order: logger first (tags every request), then JSON parser
app.use(requestLogger);
app.use(express.json());

// CORS configuration
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests from localhost in development
    if (!origin || origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
      callback(null, true);
    } else {
      callback(null, false);
    }
  },
  credentials: true,
  exposedHeaders: ['X-Request-ID'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key', 'X-Request-ID'],
}));

// Health check endpoint (handled locally)
app.get('/api/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'api-gateway',
    uptime: process.uptime(),
  });
});

// HTTP Routes - Restaurant Menu Service
app.get('/api/restaurants*', restaurantMenuProxy);
app.post('/api/restaurants*', restaurantMenuProxy);
app.put('/api/restaurants*', restaurantMenuProxy);

// HTTP Routes - Order Service
app.get('/api/orders*', orderProxy);
app.post('/api/orders', orderProxy);
app.patch('/api/orders*', orderProxy);

// HTTP Routes - Driver Location Service
app.get('/api/drivers*', driverLocationProxy);

// 404 handler for unmatched routes
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Setup WebSocket proxy
setupWebSocketProxy(server);

const PORT = process.env.API_GATEWAY_PORT || 8080;

// Log upstream service URLs at startup
console.log('API Gateway starting...');
console.log('Upstream service URLs:');
console.log(`  Restaurant Menu: ${SERVICE_URLS.restaurantMenu}`);
console.log(`  Order Service: ${SERVICE_URLS.order}`);
console.log(`  Driver Location: ${SERVICE_URLS.driverLocation}`);
console.log(`  Notification: ${SERVICE_URLS.notification}`);

server.listen(PORT, () => {
  console.log(`API Gateway listening on port ${PORT}`);
});
