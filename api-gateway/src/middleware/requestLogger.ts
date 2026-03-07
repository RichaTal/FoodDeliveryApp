import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

export interface RequestWithId extends Request {
  requestId?: string;
}

export function requestLogger(req: RequestWithId, res: Response, next: NextFunction): void {
  const requestId = req.headers['x-request-id'] as string || uuidv4();
  req.requestId = requestId;
  res.setHeader('X-Request-ID', requestId);

  const startTime = Date.now();
  const timestamp = new Date().toISOString();

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const downstreamService = getDownstreamService(req.path);
    console.log(
      `[${timestamp}] ${req.method} ${req.path} → ${downstreamService} (${res.statusCode}) ${duration}ms [${requestId}]`
    );
  });

  next();
}

function getDownstreamService(path: string): string {
  if (path.startsWith('/api/restaurants')) return 'restaurant-menu-service';
  if (path.startsWith('/api/orders')) return 'order-service';
  if (path.startsWith('/api/drivers')) return 'driver-location-service';
  if (path.startsWith('/ws/drivers')) return 'driver-location-service';
  if (path.startsWith('/ws/track')) return 'notification-service';
  if (path.startsWith('/api/health')) return 'api-gateway';
  return 'unknown';
}
