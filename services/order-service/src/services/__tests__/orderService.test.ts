import { placeOrder, getOrder, updateOrderStatus } from '../orderService';
import { getRestaurantMenu, extractMenuItems } from '../restaurantClient';
import { processPayment } from '../paymentStub';
import { publishOrderPlaced, publishOrderStatusUpdated } from '../publisher';
import { query, getClient } from '../../config/db';
import redisClient from '../../config/redis';
import pg from 'pg';
import {
  OrderStatus,
  PaymentStatus,
  RestaurantNotAvailableError,
  MenuItemNotAvailableError,
  PaymentFailedError,
  InvalidStatusTransitionError,
} from '../../types/index';

// Mock dependencies
jest.mock('../restaurantClient');
jest.mock('../paymentStub');
jest.mock('../publisher');
jest.mock('../../config/db');
jest.mock('../../config/redis');

const mockGetRestaurantMenu = jest.mocked(getRestaurantMenu);
const mockExtractMenuItems = jest.mocked(extractMenuItems);
const mockProcessPayment = jest.mocked(processPayment);
const mockPublishOrderPlaced = jest.mocked(publishOrderPlaced);
const mockPublishOrderStatusUpdated = jest.mocked(publishOrderStatusUpdated);
const mockQuery = jest.mocked(query);
const mockGetClient = jest.mocked(getClient);
const mockRedisGet = jest.mocked(redisClient.get);
const mockRedisSetex = jest.mocked(redisClient.setex);

describe('orderService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('placeOrder', () => {
    const mockOrderBody = {
      restaurantId: 'rest-123',
      items: [
        { menuItemId: 'item-1', quantity: 2 },
        { menuItemId: 'item-2', quantity: 1 },
      ],
    };

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
            {
              id: 'item-2',
              category_id: 'cat-1',
              restaurant_id: 'rest-123',
              name: 'Fries',
              description: 'Crispy fries',
              price: 4.99,
              is_available: true,
            },
          ],
        },
      ],
    };

    const mockOrder = {
      id: 'order-123',
      restaurant_id: 'rest-123',
      driver_id: null,
      status: OrderStatus.PENDING,
      total_amount: 26.97,
      payment_status: PaymentStatus.SUCCESS,
      payment_txn_id: 'txn-123',
      created_at: new Date(),
      updated_at: new Date(),
      items: [
        {
          id: 'order-item-1',
          order_id: 'order-123',
          menu_item_id: 'item-1',
          name: 'Burger',
          price_at_time: 10.99,
          quantity: 2,
        },
        {
          id: 'order-item-2',
          order_id: 'order-123',
          menu_item_id: 'item-2',
          name: 'Fries',
          price_at_time: 4.99,
          quantity: 1,
        },
      ],
    };

    it('should create a new order successfully', async () => {
      const idempotencyKey = 'idemp-key-123';
      mockRedisGet.mockResolvedValue(null);
      mockGetRestaurantMenu.mockResolvedValue(mockMenu);
      mockExtractMenuItems.mockReturnValue(mockMenu.categories[0].items);
      mockProcessPayment.mockResolvedValue({ success: true, transactionId: 'txn-123' });

      const mockClient = {
        query: jest.fn(),
        release: jest.fn(),
      };
      mockGetClient.mockResolvedValue(mockClient as any as pg.PoolClient);
      mockClient.query.mockResolvedValueOnce(undefined); // BEGIN
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 }); // INSERT order
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 }); // INSERT item 1
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 }); // INSERT item 2
      mockClient.query.mockResolvedValueOnce(undefined); // COMMIT

      mockQuery.mockResolvedValueOnce({
        rows: [mockOrder],
        rowCount: 1,
      } as unknown as pg.QueryResult); // getOrder after creation
      mockQuery.mockResolvedValueOnce({
        rows: mockOrder.items,
        rowCount: 2,
      } as unknown as pg.QueryResult); // getOrderItems

      mockRedisSetex.mockResolvedValue('OK');
      mockPublishOrderPlaced.mockResolvedValue();

      const result = await placeOrder(mockOrderBody, idempotencyKey);

      expect(result).toBeDefined();
      expect(result.id).toBe('order-123');
      expect(mockProcessPayment).toHaveBeenCalledWith(26.97, expect.any(String));
      expect(mockPublishOrderPlaced).toHaveBeenCalled();
      expect(mockRedisSetex).toHaveBeenCalledWith(
        `idempotency:${idempotencyKey}`,
        86400,
        expect.any(String),
      );
    });

    it('should return existing order if idempotency key exists', async () => {
      const idempotencyKey = 'idemp-key-123';
      const existingOrderId = 'order-123';
      mockRedisGet.mockResolvedValue(existingOrderId);
      mockQuery.mockResolvedValueOnce({
        rows: [mockOrder],
        rowCount: 1,
      } as unknown as pg.QueryResult);
      mockQuery.mockResolvedValueOnce({
        rows: mockOrder.items,
        rowCount: 2,
      } as unknown as pg.QueryResult);

      const result = await placeOrder(mockOrderBody, idempotencyKey);

      expect(result.id).toBe(existingOrderId);
      expect(mockGetRestaurantMenu).not.toHaveBeenCalled();
      expect(mockProcessPayment).not.toHaveBeenCalled();
    });

    it('should throw RestaurantNotAvailableError if restaurant not found', async () => {
      const idempotencyKey = 'idemp-key-123';
      mockRedisGet.mockResolvedValue(null);
      mockGetRestaurantMenu.mockResolvedValue(null);

      await expect(placeOrder(mockOrderBody, idempotencyKey)).rejects.toThrow(
        RestaurantNotAvailableError,
      );
    });

    it('should throw RestaurantNotAvailableError if restaurant is closed', async () => {
      const idempotencyKey = 'idemp-key-123';
      const closedMenu = {
        ...mockMenu,
        restaurant: { ...mockMenu.restaurant, is_open: false },
      };
      mockRedisGet.mockResolvedValue(null);
      mockGetRestaurantMenu.mockResolvedValue(closedMenu);

      await expect(placeOrder(mockOrderBody, idempotencyKey)).rejects.toThrow(
        RestaurantNotAvailableError,
      );
    });

    it('should throw MenuItemNotAvailableError if menu item not found', async () => {
      const idempotencyKey = 'idemp-key-123';
      mockRedisGet.mockResolvedValue(null);
      mockGetRestaurantMenu.mockResolvedValue(mockMenu);
      mockExtractMenuItems.mockReturnValue([mockMenu.categories[0].items[0]]); // Only item-1

      await expect(placeOrder(mockOrderBody, idempotencyKey)).rejects.toThrow(
        MenuItemNotAvailableError,
      );
    });

    it('should throw MenuItemNotAvailableError if menu item is unavailable', async () => {
      const idempotencyKey = 'idemp-key-123';
      const unavailableMenu = {
        ...mockMenu,
        categories: [
          {
            ...mockMenu.categories[0],
            items: [
              { ...mockMenu.categories[0].items[0], is_available: false },
              mockMenu.categories[0].items[1],
            ],
          },
        ],
      };
      mockRedisGet.mockResolvedValue(null);
      mockGetRestaurantMenu.mockResolvedValue(unavailableMenu);
      mockExtractMenuItems.mockReturnValue(unavailableMenu.categories[0].items);

      await expect(placeOrder(mockOrderBody, idempotencyKey)).rejects.toThrow(
        MenuItemNotAvailableError,
      );
    });

    it('should throw PaymentFailedError if payment fails', async () => {
      const idempotencyKey = 'idemp-key-123';
      mockRedisGet.mockResolvedValue(null);
      mockGetRestaurantMenu.mockResolvedValue(mockMenu);
      mockExtractMenuItems.mockReturnValue(mockMenu.categories[0].items);
      mockProcessPayment.mockResolvedValue({ success: false, transactionId: 'txn-123' });

      await expect(placeOrder(mockOrderBody, idempotencyKey)).rejects.toThrow(
        PaymentFailedError,
      );
    });

    it('should rollback transaction on error', async () => {
      const idempotencyKey = 'idemp-key-123';
      mockRedisGet.mockResolvedValue(null);
      mockGetRestaurantMenu.mockResolvedValue(mockMenu);
      mockExtractMenuItems.mockReturnValue(mockMenu.categories[0].items);
      mockProcessPayment.mockResolvedValue({ success: true, transactionId: 'txn-123' });

      const mockClient = {
        query: jest.fn(),
        release: jest.fn(),
      };
      mockGetClient.mockResolvedValue(mockClient as any as pg.PoolClient);
      mockClient.query.mockResolvedValueOnce(undefined); // BEGIN
      mockClient.query.mockRejectedValueOnce(new Error('DB Error')); // INSERT order fails

      await expect(placeOrder(mockOrderBody, idempotencyKey)).rejects.toThrow('DB Error');
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
      expect(mockClient.release).toHaveBeenCalled();
    });
  });

  describe('getOrder', () => {
    const mockOrder = {
      id: 'order-123',
      restaurant_id: 'rest-123',
      driver_id: null,
      status: OrderStatus.PENDING,
      total_amount: 26.97,
      payment_status: PaymentStatus.SUCCESS,
      payment_txn_id: 'txn-123',
      created_at: new Date(),
      updated_at: new Date(),
    };

    const mockOrderItems = [
      {
        id: 'order-item-1',
        order_id: 'order-123',
        menu_item_id: 'item-1',
        name: 'Burger',
        price_at_time: 10.99,
        quantity: 2,
      },
    ];

    it('should return order with items', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [mockOrder],
        rowCount: 1,
      } as unknown as pg.QueryResult);
      mockQuery.mockResolvedValueOnce({
        rows: mockOrderItems,
        rowCount: 1,
      } as unknown as pg.QueryResult);

      const result = await getOrder('order-123');

      expect(result).toBeDefined();
      expect(result?.id).toBe('order-123');
      expect(result?.items).toEqual(mockOrderItems);
    });

    it('should return null if order not found', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as unknown as pg.QueryResult);

      const result = await getOrder('non-existent');

      expect(result).toBeNull();
    });
  });

  describe('updateOrderStatus', () => {
    const mockOrder = {
      id: 'order-123',
      restaurant_id: 'rest-123',
      driver_id: null,
      status: OrderStatus.PENDING,
      total_amount: 26.97,
      payment_status: PaymentStatus.SUCCESS,
      payment_txn_id: 'txn-123',
      created_at: new Date(),
      updated_at: new Date(),
      items: [],
    };

    it('should update order status successfully', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [mockOrder],
        rowCount: 1,
      } as unknown as pg.QueryResult); // getOrder
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as unknown as pg.QueryResult); // getOrderItems
      mockQuery.mockResolvedValueOnce({
        rowCount: 1,
      } as unknown as pg.QueryResult); // UPDATE
      mockQuery.mockResolvedValueOnce({
        rows: [{ ...mockOrder, status: OrderStatus.CONFIRMED }],
        rowCount: 1,
      } as unknown as pg.QueryResult); // getOrder after update
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as unknown as pg.QueryResult); // getOrderItems after update
      mockPublishOrderStatusUpdated.mockResolvedValue();

      const result = await updateOrderStatus('order-123', OrderStatus.CONFIRMED);

      expect(result).toBeDefined();
      expect(result?.status).toBe(OrderStatus.CONFIRMED);
      expect(mockPublishOrderStatusUpdated).toHaveBeenCalledWith(
        'order-123',
        OrderStatus.CONFIRMED,
      );
    });

    it('should return null if order not found', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as unknown as pg.QueryResult);

      const result = await updateOrderStatus('non-existent', OrderStatus.CONFIRMED);

      expect(result).toBeNull();
    });

    it('should throw InvalidStatusTransitionError for invalid transition', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [{ ...mockOrder, status: OrderStatus.DELIVERED }],
        rowCount: 1,
      } as unknown as pg.QueryResult);
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as unknown as pg.QueryResult);

      await expect(
        updateOrderStatus('order-123', OrderStatus.PENDING),
      ).rejects.toThrow(InvalidStatusTransitionError);
    });

    it('should allow transition to CANCELLED from any status except DELIVERED', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [mockOrder],
        rowCount: 1,
      } as unknown as pg.QueryResult);
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as unknown as pg.QueryResult);
      mockQuery.mockResolvedValueOnce({
        rowCount: 1,
      } as unknown as pg.QueryResult);
      mockQuery.mockResolvedValueOnce({
        rows: [{ ...mockOrder, status: OrderStatus.CANCELLED }],
        rowCount: 1,
      } as unknown as pg.QueryResult);
      mockQuery.mockResolvedValueOnce({
        rows: [],
        rowCount: 0,
      } as unknown as pg.QueryResult);
      mockPublishOrderStatusUpdated.mockResolvedValue();

      const result = await updateOrderStatus('order-123', OrderStatus.CANCELLED);

      expect(result?.status).toBe(OrderStatus.CANCELLED);
    });
  });
});
