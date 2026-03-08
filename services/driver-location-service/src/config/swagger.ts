import swaggerJsdoc from 'swagger-jsdoc';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Detect if running from compiled dist directory (Docker/production)
const isProduction = __dirname.includes('dist');
const fileExtension = isProduction ? 'js' : 'ts';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Driver Location Service API',
      version: '1.0.0',
      description: `REST API for real-time driver location tracking in the Food Delivery platform.

**WebSocket Endpoint:**
- \`ws://localhost:3003/drivers/connect\` — Drivers connect here to stream GPS pings via WebSocket.
  - Messages sent: \`{ driverId, orderId, lat, lng, timestamp }\`
`,
    },
    servers: [
      {
        url: 'http://localhost:3003',
        description: 'Local development server',
      },
    ],
    components: {
      schemas: {
        Driver: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            name: { type: 'string' },
            phone: { type: 'string' },
            vehicle: { type: 'string' },
            is_active: { type: 'boolean' },
            created_at: { type: 'string', format: 'date-time' },
          },
        },
        DriverLocation: {
          type: 'object',
          properties: {
            driverId: { type: 'string', format: 'uuid' },
            lat: { type: 'number', example: 40.7128 },
            lng: { type: 'number', example: -74.006 },
          },
        },
        NearbyDriver: {
          type: 'object',
          properties: {
            driverId: { type: 'string', format: 'uuid' },
            lat: { type: 'number' },
            lng: { type: 'number' },
            distance: { type: 'number', description: 'Distance in km' },
          },
        },
        PathPoint: {
          type: 'object',
          properties: {
            lat: { type: 'number' },
            lng: { type: 'number' },
            timestamp: { type: 'integer', description: 'Unix timestamp in milliseconds' },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            error: { type: 'string' },
          },
        },
      },
    },
  },
  apis: [
    join(__dirname, `../routes/*.${fileExtension}`),
    join(__dirname, `../index.${fileExtension}`),
  ],
};

export const swaggerSpec = swaggerJsdoc(options);
