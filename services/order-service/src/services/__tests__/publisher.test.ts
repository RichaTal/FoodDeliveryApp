import { publishOrderPlaced, publishOrderStatusUpdated } from '../publisher';
import { getChannel } from '../../config/rabbitmq';
import { OrderStatus, PaymentStatus } from '../../types/index';

// Mock dependencies
jest.mock('../../config/rabbitmq.ts');

const mockGetChannel = getChannel as jest.MockedFunction<typeof getChannel>;

describe('publisher', () => {
  let mockChannel: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockChannel = {
      publish: jest.fn(),
    };
    mockGetChannel.mockResolvedValue(mockChannel);
  });

  describe('publishOrderPlaced', () => {
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
      ],
    };

    it('should publish order.placed event', async () => {
      await publishOrderPlaced(mockOrder);

      expect(mockGetChannel).toHaveBeenCalled();
      expect(mockChannel.publish).toHaveBeenCalledWith(
        'order.events',
        '',
        expect.any(Buffer),
        { persistent: true },
      );

      const publishedBuffer = mockChannel.publish.mock.calls[0][2] as Buffer;
      const publishedPayload = JSON.parse(publishedBuffer.toString());

      expect(publishedPayload.orderId).toBe('order-123');
      expect(publishedPayload.restaurantId).toBe('rest-123');
      expect(publishedPayload.totalAmount).toBe(26.97);
      expect(publishedPayload.items).toHaveLength(1);
      expect(publishedPayload.timestamp).toBeDefined();
    });

    it('should handle orders without items', async () => {
      const orderWithoutItems = { ...mockOrder, items: undefined };

      await publishOrderPlaced(orderWithoutItems);

      const publishedBuffer = mockChannel.publish.mock.calls[0][2] as Buffer;
      const publishedPayload = JSON.parse(publishedBuffer.toString());

      expect(publishedPayload.items).toEqual([]);
    });

    it('should throw error if channel publish fails', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
      
      mockChannel.publish.mockImplementation(() => {
        throw new Error('Publish failed');
      });

      await expect(publishOrderPlaced(mockOrder)).rejects.toThrow('Publish failed');
      
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        expect.stringContaining('[Publisher] Failed to publish order.placed: Publish failed')
      );
      
      consoleErrorSpy.mockRestore();
    });
  });

  describe('publishOrderStatusUpdated', () => {
    it('should publish order.status.updated event', async () => {
      const orderId = 'order-123';
      const status = OrderStatus.CONFIRMED;

      await publishOrderStatusUpdated(orderId, status);

      expect(mockGetChannel).toHaveBeenCalled();
      expect(mockChannel.publish).toHaveBeenCalledWith(
        'order.events',
        '',
        expect.any(Buffer),
        { persistent: true },
      );

      const publishedBuffer = mockChannel.publish.mock.calls[0][2] as Buffer;
      const publishedPayload = JSON.parse(publishedBuffer.toString());

      expect(publishedPayload.orderId).toBe(orderId);
      expect(publishedPayload.status).toBe(status);
      expect(publishedPayload.timestamp).toBeDefined();
    });

    it('should handle all order statuses', async () => {
      const orderId = 'order-123';
      const statuses = [
        OrderStatus.CONFIRMED,
        OrderStatus.PREPARING,
        OrderStatus.PICKED_UP,
        OrderStatus.DELIVERED,
        OrderStatus.CANCELLED,
      ];

      for (const status of statuses) {
        await publishOrderStatusUpdated(orderId, status);
        const publishedBuffer = mockChannel.publish.mock.calls[mockChannel.publish.mock.calls.length - 1][2] as Buffer;
        const publishedPayload = JSON.parse(publishedBuffer.toString());
        expect(publishedPayload.status).toBe(status);
      }
    });

    it('should throw error if channel publish fails', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
      
      mockChannel.publish.mockImplementation(() => {
        throw new Error('Publish failed');
      });

      await expect(
        publishOrderStatusUpdated('order-123', OrderStatus.CONFIRMED),
      ).rejects.toThrow('Publish failed');
      
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        expect.stringContaining('[Publisher] Failed to publish order.status.updated: Publish failed')
      );
      
      consoleErrorSpy.mockRestore();
    });
  });
});
