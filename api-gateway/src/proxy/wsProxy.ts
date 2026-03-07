import httpProxy from 'http-proxy';
import { IncomingMessage } from 'http';
import { Socket } from 'net';
import { SERVICE_URLS } from '../config/routes.js';

const proxy = httpProxy.createProxyServer({});

export function setupWebSocketProxy(server: any): void {
  server.on('upgrade', (req: IncomingMessage, socket: Socket, head: Buffer) => {
    const url = new URL(req.url || '/', `http://${req.headers.host}`);
    const pathname = url.pathname;
    const search = url.search; // Preserve query string
    const requestId = req.headers['x-request-id'] || 'unknown';

    let target: string | null = null;

    if (pathname === '/ws/drivers/connect') {
      // Preserve query string (e.g., ?driverId=xxx)
      target = `${SERVICE_URLS.driverLocation}/drivers/connect${search}`;
    } else if (pathname.startsWith('/ws/track/')) {
      // Preserve the trailing path and query string (e.g., /ws/track/123 → /track/123)
      const trackPath = pathname.replace('/ws/track', '/track');
      target = `${SERVICE_URLS.notification}${trackPath}${search}`;
    }

    if (!target) {
      console.error(`[${requestId}] Unknown WebSocket path: ${pathname}`);
      socket.write('HTTP/1.1 400 Bad Request\r\n\r\n');
      socket.destroy();
      return;
    }

    console.log(`[${requestId}] WebSocket upgrade: ${pathname}${search} → ${target}`);

    proxy.ws(req, socket, head, {
      target,
      changeOrigin: true,
    }, (err: Error) => {
      console.error(`[${requestId}] WebSocket proxy error:`, err.message);
      socket.destroy();
    });
  });
}
