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
      title: 'Order Service API',
      version: '1.0.0',
      description:
        'REST API for placing and managing food delivery orders. All write operations require an Idempotency-Key header.',
    },
    servers: [
      {
        url: 'http://localhost:3002',
        description: 'Local development server',
      },
    ],
    components: {
      schemas: {
        OrderItem: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            order_id: { type: 'string', format: 'uuid' },
            menu_item_id: { type: 'string', format: 'uuid' },
            name: { type: 'string' },
            price_at_time: { type: 'number' },
            quantity: { type: 'integer' },
          },
        },
        Order: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            restaurant_id: { type: 'string', format: 'uuid' },
            driver_id: { type: 'string', format: 'uuid', nullable: true },
            status: {
              type: 'string',
              enum: ['PENDING', 'CONFIRMED', 'PREPARING', 'PICKED_UP', 'DELIVERED', 'CANCELLED'],
            },
            total_amount: { type: 'number' },
            payment_status: { type: 'string', enum: ['PENDING', 'SUCCESS', 'FAILED'] },
            payment_txn_id: { type: 'string', nullable: true },
            created_at: { type: 'string', format: 'date-time' },
            updated_at: { type: 'string', format: 'date-time' },
            items: {
              type: 'array',
              items: { $ref: '#/components/schemas/OrderItem' },
            },
          },
        },
        CreateOrderBody: {
          type: 'object',
          required: ['restaurantId', 'items'],
          properties: {
            restaurantId: { type: 'string', format: 'uuid', example: 'b1e2c3d4-...' },
            items: {
              type: 'array',
              minItems: 1,
              items: {
                type: 'object',
                required: ['menuItemId', 'quantity'],
                properties: {
                  menuItemId: { type: 'string', format: 'uuid' },
                  quantity: { type: 'integer', minimum: 1 },
                },
              },
            },
          },
        },
        UpdateOrderStatusBody: {
          type: 'object',
          required: ['status'],
          properties: {
            status: {
              type: 'string',
              enum: ['PENDING', 'CONFIRMED', 'PREPARING', 'PICKED_UP', 'DELIVERED', 'CANCELLED'],
            },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            error: { type: 'string' },
            detail: { type: 'string' },
            details: { type: 'array', items: { type: 'string' } },
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
