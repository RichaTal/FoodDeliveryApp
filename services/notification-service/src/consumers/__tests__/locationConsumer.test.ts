import { startLocationConsumer } from '../locationConsumer.js';
import { createConsumer } from '../../config/kafka.js';
import { sendToCustomer } from '../../websocket/customerSocket.js';

// Mock dependencies
jest.mock('../../config/kafka.js');
jest.mock('../../websocket/customerSocket.js');

const mockCreateConsumer = createConsumer as jest.MockedFunction<typeof createConsumer>;
const mockSendToCustomer = sendToCustomer as jest.MockedFunction<typeof sendToCustomer>;

describe('locationConsumer', () => {
  let mockConsumer: any;
  let eachMessageHandler: ((payload: any) => Promise<void>) | null = null;

  beforeEach(() => {
    jest.clearAllMocks();
    eachMessageHandler = null;

    mockConsumer = {
      connect: jest.fn().mockResolvedValue(undefined),
      subscribe: jest.fn().mockResolvedValue(undefined),
      run: jest.fn().mockImplementation(({ eachMessage }) => {
        eachMessageHandler = eachMessage;
        return Promise.resolve();
      }),
    };

    mockCreateConsumer.mockReturnValue(mockConsumer);
  });

  describe('startLocationConsumer', () => {
    it('should create consumer with correct group ID', async () => {
      await startLocationConsumer();

      expect(mockCreateConsumer).toHaveBeenCalledWith('notification-location-consumer');
    });

    it('should connect and subscribe to driver-location-events topic', async () => {
      await startLocationConsumer();

      expect(mockConsumer.connect).toHaveBeenCalled();
      expect(mockConsumer.subscribe).toHaveBeenCalledWith({
        topic: 'driver-location-events',
        fromBeginning: false,
      });
    });

    it('should start consuming messages', async () => {
      await startLocationConsumer();

      expect(mockConsumer.run).toHaveBeenCalledWith({
        eachMessage: expect.any(Function),
      });
    });

    it('should process location event and send to customer', async () => {
      await startLocationConsumer();

      const locationEvent = {
        driverId: 'driver-123',
        orderId: 'order-123',
        lat: 40.7128,
        lng: -74.0060,
        timestamp: 1234567890,
      };

      mockSendToCustomer.mockReturnValue(true);

      if (eachMessageHandler) {
        await eachMessageHandler({
          message: {
            value: Buffer.from(JSON.stringify(locationEvent)),
          },
        });
      }

      expect(mockSendToCustomer).toHaveBeenCalledWith(
        'order-123',
        expect.objectContaining({
          type: 'DRIVER_LOCATION',
          payload: locationEvent,
        }),
      );
    });

    it('should handle customer not connected', async () => {
      await startLocationConsumer();

      const locationEvent = {
        driverId: 'driver-123',
        orderId: 'order-123',
        lat: 40.7128,
        lng: -74.0060,
        timestamp: 1234567890,
      };

      mockSendToCustomer.mockReturnValue(false);

      if (eachMessageHandler) {
        await eachMessageHandler({
          message: {
            value: Buffer.from(JSON.stringify(locationEvent)),
          },
        });
      }

      expect(mockSendToCustomer).toHaveBeenCalled();
      // Should not throw - just logs debug message
    });

    it('should handle null message value', async () => {
      await startLocationConsumer();

      if (eachMessageHandler) {
        await eachMessageHandler({
          message: { value: null },
        });
      }

      expect(mockSendToCustomer).not.toHaveBeenCalled();
    });

    it('should handle invalid JSON gracefully', async () => {
      await startLocationConsumer();

      if (eachMessageHandler) {
        await eachMessageHandler({
          message: {
            value: Buffer.from('invalid json'),
          },
        });
      }

      // Should not throw - error is caught and logged
      expect(mockSendToCustomer).not.toHaveBeenCalled();
    });

    it('should handle processing errors gracefully', async () => {
      await startLocationConsumer();

      const locationEvent = {
        driverId: 'driver-123',
        orderId: 'order-123',
        lat: 40.7128,
        lng: -74.0060,
        timestamp: 1234567890,
      };

      mockSendToCustomer.mockImplementation(() => {
        throw new Error('Send failed');
      });

      if (eachMessageHandler) {
        await eachMessageHandler({
          message: {
            value: Buffer.from(JSON.stringify(locationEvent)),
          },
        });
      }

      // Should not throw - error is caught and logged
    });

    it('should handle consumer connection errors', async () => {
      mockConsumer.connect.mockRejectedValueOnce(new Error('Connection failed'));

      await expect(startLocationConsumer()).rejects.toThrow('Connection failed');
    });
  });
});
