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
      title: 'Notification Service API',
      version: '1.0.0',
      description: `REST API and WebSocket gateway for real-time customer notifications in the Food Delivery platform.

**WebSocket Endpoint:**
- \`ws://localhost:3004/track/{orderId}\` — Customers connect here to receive real-time order status and driver location updates.
  - Messages received: \`{ type: "order_update" | "location_update", payload: { ... } }\`

**Message Consumers:**
- Listens on RabbitMQ for order events published by the Order Service.
- Listens on Kafka for driver GPS pings published by the Driver Location Service.
`,
    },
    servers: [
      {
        url: 'http://localhost:3004',
        description: 'Local development server',
      },
    ],
    components: {
      schemas: {
        HealthResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'ok' },
            service: { type: 'string', example: 'notification-service' },
            instanceId: { type: 'string', format: 'uuid' },
            activeCustomers: { type: 'integer' },
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
    join(__dirname, `../index.${fileExtension}`),
  ],
};

export const swaggerSpec = swaggerJsdoc(options);
