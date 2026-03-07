import { getRestaurant, getRestaurantMenu, extractMenuItems } from '../restaurantClient';

// Mock fetch globally
global.fetch = jest.fn();

const mockFetch = global.fetch as jest.MockedFunction<typeof fetch>;

describe('restaurantClient', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env['RESTAURANT_SERVICE_URL'] = 'http://restaurant-menu-service:3001';
  });

  afterEach(() => {
    delete process.env['RESTAURANT_SERVICE_URL'];
  });

  describe('getRestaurant', () => {
    const mockRestaurant = {
      id: 'rest-123',
      name: 'Test Restaurant',
      address: '123 Main St',
      lat: 40.7128,
      lng: -74.0060,
      is_open: true,
      created_at: new Date(),
      updated_at: new Date(),
    };

    it('should return restaurant when found', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({ data: mockRestaurant }),
      } as Response);

      const result = await getRestaurant('rest-123');

      expect(result).toEqual(mockRestaurant);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://restaurant-menu-service:3001/restaurants/rest-123',
        expect.objectContaining({
          method: 'GET',
          headers: { 'Content-Type': 'application/json' },
        }),
      );
    });

    it('should return null when restaurant not found', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 404,
      } as Response);

      const result = await getRestaurant('non-existent');

      expect(result).toBeNull();
    });

    it('should throw error on service error', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        json: async () => ({ error: 'Internal server error' }),
      } as Response);

      await expect(getRestaurant('rest-123')).rejects.toThrow('Restaurant service error');
    });

    it('should handle network errors', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Failed to connect to restaurant service'));

      await expect(getRestaurant('rest-123')).rejects.toThrow('Failed to connect to restaurant service');
    });
  });

  describe('getRestaurantMenu', () => {
    const mockMenu = {
      restaurant: {
        id: 'rest-123',
        name: 'Test Restaurant',
        address: '123 Main St',
        lat: 40.7128,
        lng: -74.0060,
        is_open: true,
        created_at: new Date(),
        updated_at: new Date(),
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

    it('should return menu when found', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({ data: mockMenu }),
      } as Response);

      const result = await getRestaurantMenu('rest-123');

      expect(result).toEqual(mockMenu);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://restaurant-menu-service:3001/restaurants/rest-123/menu',
        expect.objectContaining({
          method: 'GET',
          headers: { 'Content-Type': 'application/json' },
        }),
      );
    });

    it('should return null when menu not found', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 404,
      } as Response);

      const result = await getRestaurantMenu('non-existent');

      expect(result).toBeNull();
    });

    it('should throw error on service error', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        json: async () => ({ error: 'Internal server error' }),
      } as Response);

      await expect(getRestaurantMenu('rest-123')).rejects.toThrow('Restaurant service error');
    });
  });

  describe('extractMenuItems', () => {
    it('should extract all menu items from categories', () => {
      const mockMenu = {
        restaurant: {
          id: 'rest-123',
          name: 'Test Restaurant',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: new Date(),
          updated_at: new Date(),
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
          {
            id: 'cat-2',
            restaurant_id: 'rest-123',
            name: 'Desserts',
            display_order: 2,
            items: [
              {
                id: 'item-2',
                category_id: 'cat-2',
                restaurant_id: 'rest-123',
                name: 'Ice Cream',
                description: 'Vanilla ice cream',
                price: 5.99,
                is_available: true,
              },
            ],
          },
        ],
      };

      const result = extractMenuItems(mockMenu);

      expect(result).toHaveLength(2);
      expect(result[0].id).toBe('item-1');
      expect(result[1].id).toBe('item-2');
    });

    it('should return empty array when no categories', () => {
      const mockMenu = {
        restaurant: {
          id: 'rest-123',
          name: 'Test Restaurant',
          address: '123 Main St',
          lat: 40.7128,
          lng: -74.0060,
          is_open: true,
          created_at: new Date(),
          updated_at: new Date(),
        },
        categories: [],
      };

      const result = extractMenuItems(mockMenu);

      expect(result).toEqual([]);
    });
  });
});
