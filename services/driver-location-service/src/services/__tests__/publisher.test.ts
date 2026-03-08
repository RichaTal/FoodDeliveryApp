import { publishLocationUpdate } from '../publisher.js';
import { getProducer } from '../../config/kafka.js';

// Mock dependencies
jest.mock('../../config/kafka.js');

const mockGetProducer = getProducer as jest.MockedFunction<typeof getProducer>;

describe('publisher', () => {
  let mockProducer: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockProducer = {
      send: jest.fn().mockResolvedValue(undefined),
    };
    mockGetProducer.mockResolvedValue(mockProducer);
  });

  describe('publishLocationUpdate', () => {
    const mockPing = {
      driverId: 'driver-123',
      lat: 40.7128,
      lng: -74.0060,
      timestamp: 1234567890,
    };

    it('should publish location update without orderId', async () => {
      await publishLocationUpdate(mockPing);

      expect(mockGetProducer).toHaveBeenCalled();
      expect(mockProducer.send).toHaveBeenCalledWith({
        topic: 'driver-location-events',
        messages: [{
          key: mockPing.driverId,
          value: expect.any(String),
        }],
      });

      const sentValue = JSON.parse(mockProducer.send.mock.calls[0][0].messages[0].value);

      expect(sentValue.driverId).toBe(mockPing.driverId);
      expect(sentValue.lat).toBe(mockPing.lat);
      expect(sentValue.lng).toBe(mockPing.lng);
      expect(sentValue.timestamp).toBe(mockPing.timestamp);
      expect(sentValue.orderId).toBeUndefined();
    });

    it('should publish location update with orderId', async () => {
      const orderId = 'order-123';

      await publishLocationUpdate(mockPing, orderId);

      const sentValue = JSON.parse(mockProducer.send.mock.calls[0][0].messages[0].value);

      expect(sentValue.orderId).toBe(orderId);
    });

    it('should use driverId as partition key', async () => {
      await publishLocationUpdate(mockPing);

      expect(mockProducer.send).toHaveBeenCalledWith(
        expect.objectContaining({
          messages: [
            expect.objectContaining({
              key: mockPing.driverId,
            }),
          ],
        }),
      );
    });

    it('should publish to driver-location-events topic', async () => {
      await publishLocationUpdate(mockPing);

      expect(mockProducer.send).toHaveBeenCalledWith(
        expect.objectContaining({
          topic: 'driver-location-events',
        }),
      );
    });
  });
});
