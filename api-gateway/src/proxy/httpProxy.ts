import { createProxyMiddleware } from 'http-proxy-middleware';
import { Request, Response } from 'express';
import { SERVICE_URLS } from '../config/routes.js';

export function createProxy(target: string, pathRewrite?: Record<string, string>): ReturnType<typeof createProxyMiddleware> {
  const proxyOptions: any = {
    target,
    changeOrigin: true,
    pathRewrite,
    onError: (err: Error, req: Request, res: Response) => {
      console.error(`Proxy error for ${req.path}:`, err.message);
      if (!res.headersSent) {
        res.status(502).json({ error: 'Upstream service unavailable' });
      }
    },
    onProxyReq: (proxyReq: any, req: Request) => {
      // Forward X-Request-ID header
      const requestId = req.headers['x-request-id'];
      if (requestId) {
        proxyReq.setHeader('X-Request-ID', requestId as string);
      }
    },
  };

  return createProxyMiddleware(proxyOptions);
}

export const restaurantMenuProxy = createProxy(SERVICE_URLS.restaurantMenu, {
  '^/api/restaurants': '/restaurants',
});

export const orderProxy = createProxy(SERVICE_URLS.order, {
  '^/api/orders': '/orders',
});

export const driverLocationProxy = createProxy(SERVICE_URLS.driverLocation, {
  '^/api/drivers': '/drivers',
});
