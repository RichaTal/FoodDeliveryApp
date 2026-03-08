import { startOrderConsumer } from '../orderConsumer.js';
import { getChannel } from '../../config/rabbitmq.js';
import { sendToCustomer } from '../../websocket/customerSocket.js';

// Mock dependencies
jest.mock('../../config/rabbitmq.js');
jest.mock('../../websocket/customerSocket.js');

const mockGetChannel = getChannel as jest.MockedFunction<typeof getChannel>;
const mockSendToCustomer = sendToCustomer as jest.MockedFunction<typeof sendToCustomer>;

describe('orderConsumer', () => {
  let mockChannel: any;
  let consumeCallback: ((msg: any) => Promise<void>) | null = null;

  beforeEach(() => {
    jest.clearAllMocks();
    mockChannel = {
      consume: jest.fn((queue, callback) => {
        consumeCallback = callback;
        return Promise.resolve({ consumerTag: 'test-consumer' });
      }),
      ack: jest.fn(),
      nack: jest.fn(),
    };
    mockGetChannel.mockResolvedValue(mockChannel);
  });

  describe('startOrderConsumer', () => {
    it('should start consuming from queue', async () => {
      await startOrderConsumer();

      expect(mockGetChannel).toHaveBeenCalled();
      expect(mockChannel.consume).toHaveBeenCalledWith(
        'orders.notification',
        expect.any(Function),
        { noAck: false },
      );
    });

    it('should process order event and send to customer', async () => {
      await startOrderConsumer();

      const orderEvent = {
        orderId: 'order-123',
        status: 'CONFIRMED',
        restaurantId: 'rest-123',
        items: [],
      };

      const mockMessage = {
        content: Buffer.from(JSON.stringify(orderEvent)),
      };

      mockSendToCustomer.mockReturnValue(true);

      if (consumeCallback) {
        await consumeCallback(mockMessage);
      }

      expect(mockSendToCustomer).toHaveBeenCalledWith(
        'order-123',
        expect.objectContaining({
          type: 'ORDER_UPDATE',
          payload: orderEvent,
        }),
      );
      expect(mockChannel.ack).toHaveBeenCalledWith(mockMessage);
    });

    it('should acknowledge message even if customer not connected', async () => {
      await startOrderConsumer();

      const orderEvent = {
        orderId: 'order-123',
        status: 'CONFIRMED',
      };

      const mockMessage = {
        content: Buffer.from(JSON.stringify(orderEvent)),
      };

      mockSendToCustomer.mockReturnValue(false);

      if (consumeCallback) {
        await consumeCallback(mockMessage);
      }

      expect(mockSendToCustomer).toHaveBeenCalled();
      expect(mockChannel.ack).toHaveBeenCalledWith(mockMessage);
    });

    it('should handle null message', async () => {
      await startOrderConsumer();

      if (consumeCallback) {
        await consumeCallback(null);
      }

      expect(mockSendToCustomer).not.toHaveBeenCalled();
      expect(mockChannel.ack).not.toHaveBeenCalled();
    });

    it('should handle invalid JSON', async () => {
      await startOrderConsumer();

      const mockMessage = {
        content: Buffer.from('invalid json'),
      };

      if (consumeCallback) {
        await consumeCallback(mockMessage);
      }

      expect(mockChannel.nack).toHaveBeenCalledWith(mockMessage, false, false);
      expect(mockChannel.ack).not.toHaveBeenCalled();
    });

    it('should handle processing errors', async () => {
      await startOrderConsumer();

      const orderEvent = {
        orderId: 'order-123',
        status: 'CONFIRMED',
      };

      const mockMessage = {
        content: Buffer.from(JSON.stringify(orderEvent)),
      };

      mockSendToCustomer.mockImplementation(() => {
        throw new Error('Send failed');
      });

      if (consumeCallback) {
        await consumeCallback(mockMessage);
      }

      expect(mockChannel.nack).toHaveBeenCalledWith(mockMessage, false, false);
    });

    it('should handle channel errors', async () => {
      mockGetChannel.mockRejectedValueOnce(new Error('Channel error'));

      await expect(startOrderConsumer()).rejects.toThrow('Channel error');
    });

    it('should process different order statuses', async () => {
      await startOrderConsumer();

      const statuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'PICKED_UP', 'DELIVERED', 'CANCELLED'];

      for (const status of statuses) {
        const orderEvent = {
          orderId: 'order-123',
          status,
        };

        const mockMessage = {
          content: Buffer.from(JSON.stringify(orderEvent)),
        };

        mockSendToCustomer.mockReturnValue(true);

        if (consumeCallback) {
          await consumeCallback(mockMessage);
        }

        expect(mockSendToCustomer).toHaveBeenCalledWith(
          'order-123',
          expect.objectContaining({
            type: 'ORDER_UPDATE',
            payload: expect.objectContaining({ status }),
          }),
        );
      }
    });
  });
});
