import {
  getFullMenu,
  invalidateMenuCache,
  getAllRestaurants,
  getRestaurantById,
  getRestaurantCount,
  createRestaurant,
  updateMenuItem,
} from '../menuService.js';
import { query } from '../../config/db.js';
import redisClient from '../../config/redis.js';

// Mock dependencies
jest.mock('../../config/db.js');
jest.mock('../../config/redis.js');

const mockQuery = query as jest.MockedFunction<typeof query>;
const mockRedisGet = redisClient.get as jest.MockedFunction<typeof redisClient.get>;
const mockRedisSet = redisClient.set as jest.MockedFunction<typeof redisClient.set>;
const mockRedisDel = redisClient.del as jest.MockedFunction<typeof redisClient.del>;

describe('menuService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getFullMenu', () => {
    const mockMenuData = {
      restaurant: {
        id: 'rest-123',
        name: 'Test Restaurant',
        address: '123 Main St',
        lat: 40.7128,
        lng: -74.0060,
        is_open: true,
        created_at: '2026-02-24T12:48:47.317Z',
        updated_at: '2026-02-24T12:48:47.317Z',
      },
      categories: [
        {
          id: 'cat-1',
          restaurant_id: 'rest-123',
          name: 'Main',
          display_order: 1,
          items: [
            {
              id: 'item-1',
              category_id: 'cat-1',
              restaurant_id: 'rest-123',
              name: 'Burger',
              description: 'Delicious burger',
              price: 10.99,
              is_available: true,
            },
          ],
        },
      ],
    };

    it('should return menu from cache when available', async () => {
      mockRedisGet.mockResolvedValue(JSON.stringify(mockMenuData));

      const result = await getFullMenu('rest-123');

      expect(result.menu).toEqual(mockMenuData);
      expect(result.cacheHit).toBe(true);
      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('should query database when cache miss', async () => {
      const cacheKey = 'menu:rest-123';
      mockRedisGet.mockResolvedValue(null);

      const mockDbRows = [
        {
          id: 'rest-123',
          name: 'Test Restaurant',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: '2026-02-24T12:48:47.317Z',
          updated_at: '2026-02-24T12:48:47.317Z',
          category_id: 'cat-1',
          category_name: 'Main',
          display_order: 1,
          item_id: 'item-1',
          item_name: 'Burger',
          description: 'Delicious burger',
          price: 10.99,
          is_available: true,
        },
      ];

      mockQuery.mockResolvedValueOnce({
        rows: mockDbRows,
        rowCount: 1,
      } as any);

      mockRedisSet.mockResolvedValue('OK');

      const result = await getFullMenu('rest-123');

      expect(result.menu).toBeDefined();
      expect(result.cacheHit).toBe(false);
      expect(result.menu?.restaurant.id).toBe('rest-123');
      expect(result.menu?.categories).toHaveLength(1);
      expect(mockRedisSet).toHaveBeenCalledWith(cacheKey, expect.any(String), 'EX', 60);
    });

    it('should return null when restaurant not found', async () => {
      mockRedisGet.mockResolvedValue(null);
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as any);

      const result = await getFullMenu('non-existent');

      expect(result.menu).toBeNull();
      expect(result.cacheHit).toBe(false);
    });

    it('should handle corrupted cache gracefully', async () => {
      mockRedisGet.mockResolvedValue('invalid json');
      mockRedisDel.mockResolvedValue(1);

      const mockDbRows = [
        {
          id: 'rest-123',
          name: 'Test Restaurant',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: '2026-02-24T12:48:47.317Z',
          updated_at: '2026-02-24T12:48:47.317Z',
          category_id: 'cat-1',
          category_name: 'Main',
          display_order: 1,
          item_id: 'item-1',
          item_name: 'Burger',
          description: 'Delicious burger',
          price: 10.99,
          is_available: true,
        },
      ];

      mockQuery.mockResolvedValueOnce({
        rows: mockDbRows,
        rowCount: 1,
      } as any);

      mockRedisSet.mockResolvedValue('OK');

      const result = await getFullMenu('rest-123');

      expect(result.menu).toBeDefined();
      expect(result.cacheHit).toBe(false);
      expect(mockRedisDel).toHaveBeenCalled();
    });

    it('should handle Redis errors gracefully', async () => {
      mockRedisGet.mockRejectedValue(new Error('Redis error'));

      const mockDbRows = [
        {
          id: 'rest-123',
          name: 'Test Restaurant',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: '2026-02-24T12:48:47.317Z',
          updated_at: '2026-02-24T12:48:47.317Z',
          category_id: 'cat-1',
          category_name: 'Main',
          display_order: 1,
          item_id: 'item-1',
          item_name: 'Burger',
          description: 'Delicious burger',
          price: 10.99,
          is_available: true,
        },
      ];

      mockQuery.mockResolvedValueOnce({
        rows: mockDbRows,
        rowCount: 1,
      } as any);

      const result = await getFullMenu('rest-123');

      expect(result.menu).toBeDefined();
      expect(result.cacheHit).toBe(false);
    });
  });

  describe('invalidateMenuCache', () => {
    it('should delete cache key', async () => {
      mockRedisDel.mockResolvedValue(1);

      await invalidateMenuCache('rest-123');

      expect(mockRedisDel).toHaveBeenCalledWith('menu:rest-123');
    });

    it('should handle Redis errors gracefully', async () => {
      mockRedisDel.mockRejectedValue(new Error('Redis error'));

      await expect(invalidateMenuCache('rest-123')).resolves.not.toThrow();
    });
  });

  describe('getAllRestaurants', () => {
    const mockRestaurants = [
      {
        id: 'rest-1',
        name: 'Restaurant 1',
        address: '123 Main St',
        lat: 40.7128,
        lng: -74.0060,
        is_open: true,
        created_at: '2026-02-24T12:48:47.317Z',
        updated_at: '2026-02-24T12:48:47.317Z',
      },
      {
        id: 'rest-2',
        name: 'Restaurant 2',
        address: '456 Oak Ave',
        lat: 40.7580,
        lng: -73.9855,
        is_open: false,
        created_at: '2026-02-24T12:48:47.317Z',
        updated_at: '2026-02-24T12:48:47.317Z',
      },
    ];

    it('should return restaurants from cache when available', async () => {
      mockRedisGet.mockResolvedValue(JSON.stringify(mockRestaurants));

      const result = await getAllRestaurants();

      expect(result).toEqual(mockRestaurants);
      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('should query database when cache miss', async () => {
      mockRedisGet.mockResolvedValue(null);
      mockQuery.mockResolvedValueOnce({
        rows: mockRestaurants,
        rowCount: 2,
      } as any);
      mockRedisSet.mockResolvedValue('OK');

      const result = await getAllRestaurants();

      expect(result).toEqual(mockRestaurants);
      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('SELECT'),
      );
      expect(mockRedisSet).toHaveBeenCalledWith(
        'restaurants:list',
        JSON.stringify(mockRestaurants),
        'EX',
        30,
      );
    });
  });

  describe('getRestaurantById', () => {
    const mockRestaurant = {
      id: 'rest-123',
      name: 'Test Restaurant',
      address: '123 Main St',
      lat: 40.7128,
      lng: -74.0060,
      is_open: true,
      created_at: '2026-02-24T12:48:47.317Z',
      updated_at: '2026-02-24T12:48:47.317Z',
    };

    it('should return restaurant when found', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [mockRestaurant],
        rowCount: 1,
      } as any);

      const result = await getRestaurantById('rest-123');

      expect(result).toEqual(mockRestaurant);
    });

    it('should return null when restaurant not found', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as any);

      const result = await getRestaurantById('non-existent');

      expect(result).toBeNull();
    });
  });

  describe('getRestaurantCount', () => {
    it('should return count of restaurants', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ count: '5' }],
        rowCount: 1,
      } as any);

      const result = await getRestaurantCount();

      expect(result).toBe(5);
    });

    it('should return 0 when no restaurants', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ count: '0' }],
        rowCount: 1,
      } as any);

      const result = await getRestaurantCount();

      expect(result).toBe(0);
    });
  });

  describe('createRestaurant', () => {
    const mockPayload = {
      name: 'New Restaurant',
      address: '789 Pine St',
      lat: 40.7614,
      lng: -73.9776,
      is_open: true,
    };

    const mockRestaurant = {
      id: 'rest-new',
      ...mockPayload,
      created_at: '2026-02-24T12:48:47.317Z',
      updated_at: '2026-02-24T12:48:47.317Z',
    };

    it('should create restaurant successfully', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [mockRestaurant],
        rowCount: 1,
      } as any);
      mockRedisDel.mockResolvedValue(1);

      const result = await createRestaurant(mockPayload);

      expect(result).toEqual(mockRestaurant);
      expect(mockRedisDel).toHaveBeenCalledWith('restaurants:list');
    });

    it('should use default is_open value when not provided', async () => {
      const payloadWithoutOpen = {
        name: 'New Restaurant',
        address: '789 Pine St',
        lat: 40.7614,
        lng: -73.9776,
      };

      mockQuery.mockResolvedValueOnce({
        rows: [{ ...mockRestaurant, is_open: true }],
        rowCount: 1,
      } as any);
      mockRedisDel.mockResolvedValue(1);

      await createRestaurant(payloadWithoutOpen);

      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('INSERT'),
        expect.arrayContaining([true]),
      );
    });
  });

  describe('updateMenuItem', () => {
    const mockMenuItem = {
      id: 'item-123',
      category_id: 'cat-1',
      restaurant_id: 'rest-123',
      name: 'Updated Burger',
      description: 'Updated description',
      price: 12.99,
      is_available: false,
    };

    it('should update menu item successfully', async () => {
      const updatePayload = {
        name: 'Updated Burger',
        price: 12.99,
        is_available: false,
      };

      mockQuery.mockResolvedValueOnce({
        rows: [mockMenuItem],
        rowCount: 1,
      } as any);
      mockRedisDel.mockResolvedValue(1);

      const result = await updateMenuItem('rest-123', 'item-123', updatePayload);

      expect(result).toEqual(mockMenuItem);
      expect(mockRedisDel).toHaveBeenCalledWith('menu:rest-123');
    });

    it('should return null when menu item not found', async () => {
      const updatePayload = { name: 'Updated Burger' };

      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as any);

      const result = await updateMenuItem('rest-123', 'non-existent', updatePayload);

      expect(result).toBeNull();
    });

    it('should return null when no fields to update', async () => {
      const result = await updateMenuItem('rest-123', 'item-123', {});

      expect(result).toBeNull();
      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('should update only provided fields', async () => {
      const updatePayload = { price: 15.99 };

      mockQuery.mockResolvedValueOnce({
        rows: [{ ...mockMenuItem, price: 15.99 }],
        rowCount: 1,
      } as any);
      mockRedisDel.mockResolvedValue(1);

      const result = await updateMenuItem('rest-123', 'item-123', updatePayload);

      expect(result?.price).toBe(15.99);
      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('price = $'),
        expect.any(Array),
      );
    });
  });
});
