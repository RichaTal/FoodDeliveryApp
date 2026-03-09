import { Request, Response, NextFunction } from 'express';
import * as menuService from '../../services/menuService.js';

// Mock the menuService
jest.mock('../../services/menuService.js');

const mockMenuService = menuService as jest.Mocked<typeof menuService>;

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
import router from '../restaurants.js';

describe('Restaurant Routes', () => {
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
      setHeader: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();
    jest.clearAllMocks();
  });

  describe('GET /restaurants/count', () => {
    it('should return restaurant count', async () => {
      mockMenuService.getRestaurantCount.mockResolvedValue(5);

      await findAndExecuteRoute(router, 'get', '/restaurants/count', mockReq, mockRes, mockNext);

      expect(mockMenuService.getRestaurantCount).toHaveBeenCalledTimes(1);
      expect(mockRes.json).toHaveBeenCalledWith({ count: 5 });
    });

    it('should handle errors', async () => {
      mockMenuService.getRestaurantCount.mockRejectedValue(new Error('DB error'));

      await findAndExecuteRoute(router, 'get', '/restaurants/count', mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalledWith(expect.any(Error));
    });
  });

  describe('GET /restaurants', () => {
    it('should return all restaurants', async () => {
      const mockRestaurants = [
        {
          id: 'rest-1',
          name: 'Restaurant 1',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: new Date('2024-01-01T00:00:00Z'),
          updated_at: new Date('2024-01-01T00:00:00Z'),
        },
      ];
      mockMenuService.getAllRestaurants.mockResolvedValue(mockRestaurants);

      await findAndExecuteRoute(router, 'get', '/restaurants', mockReq, mockRes, mockNext);

      expect(mockMenuService.getAllRestaurants).toHaveBeenCalledTimes(1);
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockRestaurants });
    });
  });

  describe('GET /restaurants/:id', () => {
    const validId = '123e4567-e89b-12d3-a456-426614174000';

    it('should return restaurant by id', async () => {
      const mockRestaurant = {
        id: validId,
        name: 'Restaurant 1',
        address: '123 Main St',
        lat: 40.7128,
        lng: -74.0060,
        is_open: true,
        created_at: new Date('2024-01-01T00:00:00Z'),
        updated_at: new Date('2024-01-01T00:00:00Z'),
      };
      mockMenuService.getRestaurantById.mockResolvedValue(mockRestaurant);
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/restaurants/:id', mockReq, mockRes, mockNext);

      expect(mockMenuService.getRestaurantById).toHaveBeenCalledWith(validId);
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockRestaurant });
    });

    it('should return 404 if restaurant not found', async () => {
      mockMenuService.getRestaurantById.mockResolvedValue(null);
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/restaurants/:id', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(404);
      expect(mockRes.json).toHaveBeenCalledWith({ error: `Restaurant "${validId}" not found` });
    });

    it('should return 400 for invalid UUID', async () => {
      mockReq.params = { id: 'invalid-id' };

      await findAndExecuteRoute(router, 'get', '/restaurants/:id', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid UUID: "invalid-id"' });
      expect(mockMenuService.getRestaurantById).not.toHaveBeenCalled();
    });
  });

  describe('GET /restaurants/:id/menu', () => {
    const validId = '123e4567-e89b-12d3-a456-426614174000';

    it('should return menu with cache hit', async () => {
      const mockMenu = {
        restaurant: {
          id: validId,
          name: 'Restaurant 1',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: new Date('2024-01-01T00:00:00Z'),
          updated_at: new Date('2024-01-01T00:00:00Z'),
        },
        categories: [],
      };
      mockMenuService.getFullMenu.mockResolvedValue({ menu: mockMenu, cacheHit: true });
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/restaurants/:id/menu', mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('X-Cache', 'HIT');
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockMenu });
    });

    it('should return menu with cache miss', async () => {
      const mockMenu = {
        restaurant: {
          id: validId,
          name: 'Restaurant 1',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: new Date('2024-01-01T00:00:00Z'),
          updated_at: new Date('2024-01-01T00:00:00Z'),
        },
        categories: [],
      };
      mockMenuService.getFullMenu.mockResolvedValue({ menu: mockMenu, cacheHit: false });
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/restaurants/:id/menu', mockReq, mockRes, mockNext);

      expect(mockRes.setHeader).toHaveBeenCalledWith('X-Cache', 'MISS');
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockMenu });
    });

    it('should return 404 if restaurant not found', async () => {
      mockMenuService.getFullMenu.mockResolvedValue({ menu: null, cacheHit: false });
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/restaurants/:id/menu', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(404);
      expect(mockRes.json).toHaveBeenCalledWith({ error: `Restaurant "${validId}" not found` });
    });
  });

  describe('POST /restaurants', () => {
    const validPayload = {
      name: 'New Restaurant',
      address: '456 Oak Ave',
      lat: 40.7589,
      lng: -73.9851,
    };

    it('should create restaurant with valid payload', async () => {
      const mockRestaurant = {
        id: 'rest-123',
        ...validPayload,
        is_open: true,
        created_at: new Date('2024-01-01T00:00:00Z'),
        updated_at: new Date('2024-01-01T00:00:00Z'),
      };
      mockMenuService.createRestaurant.mockResolvedValue(mockRestaurant);
      mockReq.body = validPayload;

      await findAndExecuteRoute(router, 'post', '/restaurants', mockReq, mockRes, mockNext);

      expect(mockMenuService.createRestaurant).toHaveBeenCalledWith(validPayload);
      expect(mockRes.status).toHaveBeenCalledWith(201);
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockRestaurant });
    });

    it('should return 400 if name is missing', async () => {
      mockReq.body = { address: '456 Oak Ave', lat: 40.7589, lng: -73.9851 };

      await findAndExecuteRoute(router, 'post', '/restaurants', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        details: expect.arrayContaining(['name is required']),
      });
    });

    it('should return 400 if address is missing', async () => {
      mockReq.body = { name: 'New Restaurant', lat: 40.7589, lng: -73.9851 };

      await findAndExecuteRoute(router, 'post', '/restaurants', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        details: expect.arrayContaining(['address is required']),
      });
    });

    it('should return 400 if lat is missing', async () => {
      mockReq.body = { name: 'New Restaurant', address: '456 Oak Ave', lng: -73.9851 };

      await findAndExecuteRoute(router, 'post', '/restaurants', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        details: expect.arrayContaining(['lat is required and must be a number']),
      });
    });

    it('should return 400 if lat is not a number', async () => {
      mockReq.body = { name: 'New Restaurant', address: '456 Oak Ave', lat: 'invalid', lng: -73.9851 };

      await findAndExecuteRoute(router, 'post', '/restaurants', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        details: expect.arrayContaining(['lat is required and must be a number']),
      });
    });
  });

  describe('PUT /restaurants/:id/menu-items/:itemId', () => {
    const validRestaurantId = '123e4567-e89b-12d3-a456-426614174000';
    const validItemId = '223e4567-e89b-12d3-a456-426614174000';

    it('should update menu item with valid payload', async () => {
      const updatePayload = { name: 'Updated Item', price: 15.99 };
      const mockItem = {
        id: validItemId,
        name: 'Updated Item',
        price: 15.99,
        description: 'Description',
        is_available: true,
        category_id: 'cat-1',
        restaurant_id: validRestaurantId,
      };
      mockMenuService.updateMenuItem.mockResolvedValue(mockItem);
      mockReq.params = { id: validRestaurantId, itemId: validItemId };
      mockReq.body = updatePayload;

      await findAndExecuteRoute(router, 'put', '/restaurants/:id/menu-items/:itemId', mockReq, mockRes, mockNext);

      expect(mockMenuService.updateMenuItem).toHaveBeenCalledWith(
        validRestaurantId,
        validItemId,
        updatePayload,
      );
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockItem });
    });

    it('should return 400 if no fields provided', async () => {
      mockReq.params = { id: validRestaurantId, itemId: validItemId };
      mockReq.body = {};

      await findAndExecuteRoute(router, 'put', '/restaurants/:id/menu-items/:itemId', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'At least one of name, price, description, is_available must be provided',
      });
    });

    it('should return 400 if price is not a number', async () => {
      mockReq.params = { id: validRestaurantId, itemId: validItemId };
      mockReq.body = { price: 'invalid' };

      await findAndExecuteRoute(router, 'put', '/restaurants/:id/menu-items/:itemId', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'price must be a number' });
    });

    it('should return 404 if menu item not found', async () => {
      mockMenuService.updateMenuItem.mockResolvedValue(null);
      mockReq.params = { id: validRestaurantId, itemId: validItemId };
      mockReq.body = { name: 'Updated' };

      await findAndExecuteRoute(router, 'put', '/restaurants/:id/menu-items/:itemId', mockReq, mockRes, mockNext);

      expect(mockRes.status).toHaveBeenCalledWith(404);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: `Menu item "${validItemId}" not found for restaurant "${validRestaurantId}"`,
      });
    });
  });
});
