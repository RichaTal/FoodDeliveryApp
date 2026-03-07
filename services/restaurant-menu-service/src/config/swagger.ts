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
      title: 'Restaurant Menu Service API',
      version: '1.0.0',
      description:
        'REST API for managing restaurants and their menus in the Food Delivery platform.',
    },
    servers: [
      {
        url: 'http://localhost:3001',
        description: 'Local development server',
      },
    ],
    components: {
      schemas: {
        Restaurant: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            name: { type: 'string' },
            address: { type: 'string' },
            lat: { type: 'number' },
            lng: { type: 'number' },
            is_open: { type: 'boolean' },
            created_at: { type: 'string', format: 'date-time' },
            updated_at: { type: 'string', format: 'date-time' },
          },
        },
        MenuItem: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            category_id: { type: 'string', format: 'uuid' },
            restaurant_id: { type: 'string', format: 'uuid' },
            name: { type: 'string' },
            description: { type: 'string' },
            price: { type: 'number' },
            is_available: { type: 'boolean' },
          },
        },
        MenuCategory: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            restaurant_id: { type: 'string', format: 'uuid' },
            name: { type: 'string' },
            display_order: { type: 'integer' },
            items: {
              type: 'array',
              items: { $ref: '#/components/schemas/MenuItem' },
            },
          },
        },
        FullMenu: {
          type: 'object',
          properties: {
            restaurant: { $ref: '#/components/schemas/Restaurant' },
            categories: {
              type: 'array',
              items: { $ref: '#/components/schemas/MenuCategory' },
            },
          },
        },
        CreateRestaurantPayload: {
          type: 'object',
          required: ['name', 'address', 'lat', 'lng'],
          properties: {
            name: { type: 'string', example: 'Pizza Palace' },
            address: { type: 'string', example: '123 Main St, Springfield' },
            lat: { type: 'number', example: 40.7128 },
            lng: { type: 'number', example: -74.006 },
            is_open: { type: 'boolean', default: true },
          },
        },
        UpdateMenuItemPayload: {
          type: 'object',
          properties: {
            name: { type: 'string' },
            description: { type: 'string' },
            price: { type: 'number' },
            is_available: { type: 'boolean' },
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
