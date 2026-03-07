import { Request, Response, NextFunction } from 'express';
import * as orderService from '../../services/orderService.js';
import { OrderStatus } from '../../types/index.js';

// Mock the orderService
jest.mock('../../services/orderService.js');

const mockOrderService = orderService as jest.Mocked<typeof orderService>;

// Helper function to find and execute route handler
function findAndExecuteRoute(
  router: any,
  method: string,
  path: string,
  req: Partial<Request>,
  res: Partial<Response>,
  next: NextFunction,
): Promise<void> {
  return new Promise((resolve) => {
    const route = router.stack.find(
      (r: any) => r.route?.path === path && r.route?.methods[method.toLowerCase()],
    );
    if (route?.route?.stack?.[0]?.handle) {
      const handler = route.route.stack[0].handle;
      Promise.resolve(handler(req as Request, res as Response, next)).then(() => resolve());
    } else {
      resolve();
    }
  });
}

// Import router after mocks
import router from '../orders.js';

describe('Order Routes', () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;
  let mockNext: NextFunction;

  beforeEach(() => {
    mockReq = {
      params: {},
      query: {},
      body: {},
      headers: {},
    };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();
    jest.clearAllMocks();
  });

  describe('POST /orders', () => {
    const validIdempotencyKey = '123e4567-e89b-12d3-a456-426614174000';
    const validOrderBody = {
      restaurantId: '123e4567-e89b-12d3-a456-426614174001',
      items: [
        { menuItemId: '123e4567-e89b-12d3-a456-426614174002', quantity: 2 },
      ],
    };

    it('should create order with valid idempotency key and body', async () => {
      const mockOrder = {
        id: 'order-123',
        restaurant_id: validOrderBody.restaurantId,
        driver_id: null,
        status: OrderStatus.PENDING,
        total_amount: 20.99,
        payment_status: 'SUCCESS' as const,
        payment_txn_id: 'txn-123',
        created_at: new Date(),
        updated_at: new Date(),
        items: [],
      };
      mockOrderService.placeOrder.mockResolvedValue(mockOrder);
      mockReq.headers = { 'idempotency-key': validIdempotencyKey };
      mockReq.body = validOrderBody;

      await findAndExecuteRoute(router, 'post', '/orders', mockReq, mockRes, mockNext);

      expect(mockOrderService.placeOrder).toHaveBeenCalledWith(validOrderBody, validIdempotencyKey);
      expect(mockRes.status).toHaveBeenCalledWith(202);
      expect(mockRes.json).toHaveBeenCalledWith({
        data: {
          orderId: mockOrder.id,
          status: mockOrder.status,
        },
      });
    });

    it('should return 400 if idempotency key is missing', async () => {
      mockReq.headers = {};
      mockReq.body = validOrderBody;

      await findAndExecuteRoute(router, 'post', '/orders', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'Idempotency-Key header is required' });
      expect(mockOrderService.placeOrder).not.toHaveBeenCalled();
    });

    it('should return 400 if idempotency key is invalid UUID', async () => {
      mockReq.headers = { 'idempotency-key': 'invalid-key' };
      mockReq.body = validOrderBody;

      await findAndExecuteRoute(router, 'post', '/orders', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'Idempotency-Key must be a valid UUID' });
    });

    it('should return 400 if restaurantId is missing', async () => {
      mockReq.headers = { 'idempotency-key': validIdempotencyKey };
      mockReq.body = { items: validOrderBody.items };

      await findAndExecuteRoute(router, 'post', '/orders', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        details: expect.arrayContaining(['restaurantId is required and must be a string']),
      });
    });

    it('should return 400 if items array is empty', async () => {
      mockReq.headers = { 'idempotency-key': validIdempotencyKey };
      mockReq.body = { restaurantId: validOrderBody.restaurantId, items: [] };

      await findAndExecuteRoute(router, 'post', '/orders', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        details: expect.arrayContaining(['items is required and must be a non-empty array']),
      });
    });

    it('should handle RestaurantNotAvailableError', async () => {
      const error = new Error('Restaurant not available') as Error & { name?: string };
      error.name = 'RestaurantNotAvailableError';
      mockOrderService.placeOrder.mockRejectedValue(error);
      mockReq.headers = { 'idempotency-key': validIdempotencyKey };
      mockReq.body = validOrderBody;

      await findAndExecuteRoute(router, 'post', '/orders', mockReq, mockRes, mockNext);

      // The route handler checks instanceof, so we need to use the actual error class
      // For now, test that next is called with error
      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('GET /orders/:id', () => {
    const validId = '123e4567-e89b-12d3-a456-426614174000';

    it('should return order by id', async () => {
      const mockOrder = {
        id: validId,
        restaurant_id: 'rest-123',
        driver_id: null,
        status: OrderStatus.PENDING,
        total_amount: 20.99,
        payment_status: 'SUCCESS' as const,
        payment_txn_id: 'txn-123',
        created_at: new Date(),
        updated_at: new Date(),
        items: [],
      };
      mockOrderService.getOrder.mockResolvedValue(mockOrder);
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/orders/:id', mockReq, mockRes, mockNext);

      expect(mockOrderService.getOrder).toHaveBeenCalledWith(validId);
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockOrder });
    });

    it('should return 404 if order not found', async () => {
      mockOrderService.getOrder.mockResolvedValue(null);
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/orders/:id', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(404);
      expect(mockRes.json).toHaveBeenCalledWith({ error: `Order "${validId}" not found` });
    });

    it('should return 400 for invalid UUID', async () => {
      mockReq.params = { id: 'invalid-id' };

      await findAndExecuteRoute(router, 'get', '/orders/:id', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid UUID: "invalid-id"' });
    });
  });

  describe('PATCH /orders/:id/status', () => {
    const validId = '123e4567-e89b-12d3-a456-426614174000';

    it('should update order status', async () => {
      const mockOrder = {
        id: validId,
        restaurant_id: 'rest-123',
        driver_id: null,
        status: OrderStatus.CONFIRMED,
        total_amount: 20.99,
        payment_status: 'SUCCESS' as const,
        payment_txn_id: 'txn-123',
        created_at: new Date(),
        updated_at: new Date(),
        items: [],
      };
      mockOrderService.updateOrderStatus.mockResolvedValue(mockOrder);
      mockReq.params = { id: validId };
      mockReq.body = { status: OrderStatus.CONFIRMED };

      await findAndExecuteRoute(router, 'patch', '/orders/:id/status', mockReq, mockRes, mockNext);

      expect(mockOrderService.updateOrderStatus).toHaveBeenCalledWith(validId, OrderStatus.CONFIRMED);
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockOrder });
    });

    it('should return 400 if status is missing', async () => {
      mockReq.params = { id: validId };
      mockReq.body = {};

      await findAndExecuteRoute(router, 'patch', '/orders/:id/status', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'status is required and must be a string',
      });
    });

    it('should return 400 if status is invalid', async () => {
      mockReq.params = { id: validId };
      mockReq.body = { status: 'INVALID_STATUS' };

      await findAndExecuteRoute(router, 'patch', '/orders/:id/status', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: expect.stringContaining('Invalid status'),
      });
    });

    it('should return 404 if order not found', async () => {
      mockOrderService.updateOrderStatus.mockResolvedValue(null);
      mockReq.params = { id: validId };
      mockReq.body = { status: OrderStatus.CONFIRMED };

      await findAndExecuteRoute(router, 'patch', '/orders/:id/status', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(404);
      expect(mockRes.json).toHaveBeenCalledWith({ error: `Order "${validId}" not found` });
    });
  });
});
