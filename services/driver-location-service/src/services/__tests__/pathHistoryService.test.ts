import {
  storePathPoint,
  getPathHistory,
  deletePathHistory,
  getActivePathKeys,
} from '../pathHistoryService.js';
import redisClient from '../../config/redis.js';

// Mock dependencies
jest.mock('../../config/redis.js');

const mockZadd = redisClient.zadd as jest.MockedFunction<typeof redisClient.zadd>;
const mockExpire = redisClient.expire as jest.MockedFunction<typeof redisClient.expire>;
const mockZremrangebyscore = redisClient.zremrangebyscore as jest.MockedFunction<typeof redisClient.zremrangebyscore>;
const mockZrangebyscore = redisClient.zrangebyscore as jest.MockedFunction<typeof redisClient.zrangebyscore>;
const mockDel = redisClient.del as jest.MockedFunction<typeof redisClient.del>;
const mockKeys = redisClient.keys as jest.MockedFunction<typeof redisClient.keys>;

describe('pathHistoryService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('storePathPoint', () => {
    const mockPing = {
      driverId: 'driver-123',
      lat: 40.7128,
      lng: -74.0060,
      timestamp: 1234567890,
    };

    it('should store path point with driverId', async () => {
      mockZadd.mockResolvedValue(1);
      mockExpire.mockResolvedValue(1);
      mockZremrangebyscore.mockResolvedValue(0);

      await storePathPoint(mockPing);

      expect(mockZadd).toHaveBeenCalledWith(
        'drivers:path:driver-123',
        mockPing.timestamp,
        expect.any(String),
      );
      expect(mockExpire).toHaveBeenCalledWith('drivers:path:driver-123', 7200);
      expect(mockZremrangebyscore).toHaveBeenCalled();
    });

    it('should store path point with orderId when provided', async () => {
      const orderId = 'order-123';
      mockZadd.mockResolvedValue(1);
      mockExpire.mockResolvedValue(1);
      mockZremrangebyscore.mockResolvedValue(0);

      await storePathPoint(mockPing, orderId);

      expect(mockZadd).toHaveBeenCalledWith(
        'drivers:path:order-123',
        mockPing.timestamp,
        expect.any(String),
      );
    });

    it('should cleanup old points', async () => {
      const cutoffTime = Date.now() - 2 * 60 * 60 * 1000;
      mockZadd.mockResolvedValue(1);
      mockExpire.mockResolvedValue(1);
      mockZremrangebyscore.mockResolvedValue(5);

      await storePathPoint(mockPing);

      expect(mockZremrangebyscore).toHaveBeenCalledWith(
        'drivers:path:driver-123',
        0,
        expect.any(Number),
      );
    });
  });

  describe('getPathHistory', () => {
    const mockPathPoints = [
      JSON.stringify({ lat: 40.7128, lng: -74.0060, timestamp: 1234567890 }),
      '1234567890', // score for first point
      JSON.stringify({ lat: 40.7130, lng: -74.0050, timestamp: 1234567900 }),
      '1234567900', // score for second point
    ];

    it('should return path history for orderId', async () => {
      const orderId = 'order-123';
      mockZrangebyscore.mockResolvedValue(mockPathPoints);

      const result = await getPathHistory(orderId);

      expect(result).toHaveLength(2);
      expect(result[0].lat).toBe(40.7128);
      expect(result[0].lng).toBe(-74.0060);
      expect(result[0].timestamp).toBe(1234567890);
      expect(mockZrangebyscore).toHaveBeenCalledWith(
        'drivers:path:order-123',
        0,
        '+inf',
        'WITHSCORES',
      );
    });

    it('should return path history for driverId', async () => {
      const driverId = 'driver-123';
      mockZrangebyscore.mockResolvedValue(mockPathPoints);

      const result = await getPathHistory(driverId);

      expect(result).toHaveLength(2);
      expect(mockZrangebyscore).toHaveBeenCalledWith(
        'drivers:path:driver-123',
        0,
        '+inf',
        'WITHSCORES',
      );
    });

    it('should filter by time range', async () => {
      const orderId = 'order-123';
      const startTime = 1234567890;
      const endTime = 1234568000;

      mockZrangebyscore.mockResolvedValue([mockPathPoints[0]]);

      await getPathHistory(orderId, startTime, endTime);

      expect(mockZrangebyscore).toHaveBeenCalledWith(
        'drivers:path:order-123',
        startTime,
        endTime,
        'WITHSCORES',
      );
    });

    it('should return empty array when no history found', async () => {
      const orderId = 'order-123';
      mockZrangebyscore.mockResolvedValue([]);

      const result = await getPathHistory(orderId);

      expect(result).toEqual([]);
    });

    it('should handle invalid JSON gracefully', async () => {
      const orderId = 'order-123';
      mockZrangebyscore.mockResolvedValue(['invalid json', '1234567890']);

      const result = await getPathHistory(orderId);

      expect(result).toEqual([]);
    });

    it('should parse WITHSCORES format correctly', async () => {
      const orderId = 'order-123';
      // WITHSCORES returns: [point_json, score, point_json, score, ...]
      const withScores = [
        JSON.stringify({ lat: 40.7128, lng: -74.0060, timestamp: 1234567890 }),
        '1234567890',
        JSON.stringify({ lat: 40.7130, lng: -74.0050, timestamp: 1234567900 }),
        '1234567900',
      ];
      mockZrangebyscore.mockResolvedValue(withScores);

      const result = await getPathHistory(orderId);

      expect(result).toHaveLength(2);
    });
  });

  describe('deletePathHistory', () => {
    it('should delete path history for orderId', async () => {
      const orderId = 'order-123';
      mockDel.mockResolvedValue(1);

      await deletePathHistory(orderId);

      expect(mockDel).toHaveBeenCalledWith('drivers:path:order-123');
    });

    it('should delete path history for driverId', async () => {
      const driverId = 'driver-123';
      mockDel.mockResolvedValue(1);

      await deletePathHistory(driverId);

      expect(mockDel).toHaveBeenCalledWith('drivers:path:driver-123');
    });
  });

  describe('getActivePathKeys', () => {
    it('should return active path keys', async () => {
      const mockKeysList = [
        'drivers:path:order-123',
        'drivers:path:order-456',
        'drivers:path:driver-789',
      ];
      mockKeys.mockResolvedValue(mockKeysList);

      const result = await getActivePathKeys();

      expect(result).toEqual(['order-123', 'order-456', 'driver-789']);
      expect(mockKeys).toHaveBeenCalledWith('drivers:path:*');
    });

    it('should return empty array when no active paths', async () => {
      mockKeys.mockResolvedValue([]);

      const result = await getActivePathKeys();

      expect(result).toEqual([]);
    });
  });
});
