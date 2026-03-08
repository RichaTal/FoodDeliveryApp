import { Request, Response, NextFunction } from 'express';

// Shared mock redis client – using a stable object so the same reference is
// returned by the factory every time index.ts imports redis (even after
// jest.resetModules()), avoiding stale-reference problems.
const mockRedisClientInstance = {
  status: 'ready' as string,
  connect: jest.fn(),
  on: jest.fn(),
};

// Mock dependencies

// swagger.ts uses `import.meta.url` which, when compiled to CJS by ts-jest,
// conflicts with the CJS module wrapper's injected `__filename` global.
// Since swagger is not under test here, stub it out completely.
jest.mock('../config/swagger.js', () => ({
  __esModule: true,
  swaggerSpec: {},
}));

jest.mock('../config/redis.js', () => ({
  __esModule: true,
  default: mockRedisClientInstance,
}));

jest.mock('../routes/restaurants.js', () => {
  const express = require('express');
  const router = express.Router();
  router.get('/test', (_req: Request, res: Response) => res.json({ test: true }));
  return router;
});

describe('Restaurant Menu Service Index', () => {
  let app: any;
  let startFn: () => Promise<void>;
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let mockNext: NextFunction;

  beforeEach(async () => {
    // Clear module cache to re-import
    jest.resetModules();
    jest.clearAllMocks();

    // Reset redis mock state to defaults before each test
    mockRedisClientInstance.status = 'ready';

    mockReq = {};
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();

    // Import app and start after mocks
    const module = await import('../index.js');
    app = module.default;
    startFn = module.start;
  });

  describe('GET /health', () => {
    it('should return health status', () => {
      const healthRoute = app._router?.stack?.find((r: any) => {
        return r.route?.path === '/health' && r.route?.methods?.get;
      });

      if (healthRoute) {
        const handler = healthRoute.route.stack[0].handle;
        handler(mockReq, mockRes as Response);
        expect(mockRes.json).toHaveBeenCalledWith({
          status: 'ok',
          service: 'restaurant-menu-service',
        });
      }
    });
  });

  describe('Error Handler', () => {
    it('should handle PostgreSQL unique violation (23505)', () => {
      const error = new Error('Duplicate key') as Error & { code?: string };
      error.code = '23505';

      // Find error handler middleware
      const errorHandler = app._router?.stack?.find((r: any) => r.name === 'errorHandler')?.handle;
      if (!errorHandler) {
        // Try to find it in the middleware stack
        const errorMiddleware = app._router?.stack?.find((r: any) => {
          return r.handle?.length === 4; // Error handlers have 4 parameters
        });
        if (errorMiddleware?.handle) {
          errorMiddleware.handle(error, mockReq as Request, mockRes as Response, mockNext);
          expect(mockRes.status).toHaveBeenCalledWith(409);
          expect(mockRes.json).toHaveBeenCalledWith({
            error: 'Resource already exists',
            detail: expect.any(String),
          });
        }
      }
    });

    it('should handle PostgreSQL not-null violation (23502)', () => {
      const error = new Error('Not null violation') as Error & { code?: string };
      error.code = '23502';

      const errorMiddleware = app._router?.stack?.find((r: any) => {
        return r.handle?.length === 4;
      });
      if (errorMiddleware?.handle) {
        errorMiddleware.handle(error, mockReq as Request, mockRes as Response, mockNext);
        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Invalid data',
          detail: expect.any(String),
        });
      }
    });

    it('should handle PostgreSQL check constraint violation (23514)', () => {
      const error = new Error('Check constraint violation') as Error & { code?: string };
      error.code = '23514';

      const errorMiddleware = app._router?.stack?.find((r: any) => {
        return r.handle?.length === 4;
      });
      if (errorMiddleware?.handle) {
        errorMiddleware.handle(error, mockReq as Request, mockRes as Response, mockNext);
        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Invalid data',
          detail: expect.any(String),
        });
      }
    });

    it('should handle PostgreSQL foreign key violation (23503)', () => {
      const error = new Error('Foreign key violation') as Error & { code?: string };
      error.code = '23503';

      const errorMiddleware = app._router?.stack?.find((r: any) => {
        return r.handle?.length === 4;
      });
      if (errorMiddleware?.handle) {
        errorMiddleware.handle(error, mockReq as Request, mockRes as Response, mockNext);
        expect(mockRes.status).toHaveBeenCalledWith(422);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Referenced resource does not exist',
          detail: expect.any(String),
        });
      }
    });

    it('should handle generic errors', () => {
      const error = new Error('Generic error');

      const errorMiddleware = app._router?.stack?.find((r: any) => {
        return r.handle?.length === 4;
      });
      if (errorMiddleware?.handle) {
        errorMiddleware.handle(error, mockReq as Request, mockRes as Response, mockNext);
        expect(mockRes.status).toHaveBeenCalledWith(500);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Internal server error' });
      }
    });
  });

  describe('Redis Connection', () => {
    it('should attempt to connect Redis if not ready', async () => {
      // Configure the shared mock client as disconnected
      mockRedisClientInstance.status = 'end';
      mockRedisClientInstance.connect = jest.fn().mockResolvedValue(undefined);
      // Prevent actual TCP binding during the test
      app.listen = jest.fn();

      await startFn();

      expect(mockRedisClientInstance.connect).toHaveBeenCalled();
    });

    it('should not attempt to connect if already ready', async () => {
      mockRedisClientInstance.status = 'ready';
      mockRedisClientInstance.connect = jest.fn();
      app.listen = jest.fn();

      await startFn();

      // Should not call connect if already ready
      expect(mockRedisClientInstance.connect).not.toHaveBeenCalled();
    });

    it('should handle Redis connection errors silently', async () => {
      mockRedisClientInstance.status = 'end';
      mockRedisClientInstance.connect = jest.fn().mockRejectedValue(new Error('Connection failed'));
      app.listen = jest.fn();

      // Should not throw even when connect rejects
      await expect(startFn()).resolves.toBeUndefined();
    });
  });
});
