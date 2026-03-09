import {
  updateDriverPosition,
  getDriverPosition,
  getNearbyDrivers,
  cleanupExpiredDrivers,
} from '../locationService.js';
import redisClient from '../../config/redis.js';
import { storePathPoint } from '../pathHistoryService.js';

// Mock dependencies
jest.mock('../../config/redis.js');
jest.mock('../pathHistoryService.js');

const mockGeoadd = redisClient.geoadd as jest.MockedFunction<typeof redisClient.geoadd>;
const mockZadd = redisClient.zadd as jest.MockedFunction<typeof redisClient.zadd>;
const mockGeopos = redisClient.geopos as jest.MockedFunction<typeof redisClient.geopos>;
const mockCall = redisClient.call as jest.MockedFunction<typeof redisClient.call>;
const mockZrangebyscore = redisClient.zrangebyscore as jest.MockedFunction<typeof redisClient.zrangebyscore>;
const mockZrem = redisClient.zrem as jest.MockedFunction<typeof redisClient.zrem>;
const mockPipeline = redisClient.pipeline as jest.MockedFunction<typeof redisClient.pipeline>;
const mockStorePathPoint = storePathPoint as jest.MockedFunction<typeof storePathPoint>;

describe('locationService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('updateDriverPosition', () => {
    const mockPing = {
      driverId: 'driver-123',
      lat: 40.7128,
      lng: -74.0060,
      timestamp: Date.now(),
    };

    it('should update driver position in Redis GEO', async () => {
      mockGeoadd.mockResolvedValue(1);
      mockZadd.mockResolvedValue('1');
      mockStorePathPoint.mockResolvedValue();

      await updateDriverPosition(mockPing);

      expect(mockGeoadd).toHaveBeenCalledWith(
        'drivers:active',
        mockPing.lng,
        mockPing.lat,
        mockPing.driverId,
      );
      expect(mockZadd).toHaveBeenCalled();
      expect(mockStorePathPoint).toHaveBeenCalled();
    });

    it('should include orderId when provided', async () => {
      const orderId = 'order-123';
      mockGeoadd.mockResolvedValue(1);
      mockZadd.mockResolvedValue('1');
      mockStorePathPoint.mockResolvedValue();

      await updateDriverPosition(mockPing, orderId);

      expect(mockStorePathPoint).toHaveBeenCalledWith(mockPing, orderId);
    });

    it('should set TTL tracking with expiry timestamp', async () => {
      mockGeoadd.mockResolvedValue(1);
      mockZadd.mockResolvedValue('1');
      mockStorePathPoint.mockResolvedValue();

      const beforeTime = Date.now();
      await updateDriverPosition(mockPing);
      const afterTime = Date.now();

      expect(mockZadd).toHaveBeenCalledWith(
        'drivers:ttl',
        expect.any(Number),
        mockPing.driverId,
      );

      const expiryScore = mockZadd.mock.calls[0][1] as unknown as number;
      expect(expiryScore).toBeGreaterThanOrEqual(beforeTime + 30000);
      expect(expiryScore).toBeLessThanOrEqual(afterTime + 30000);
    });
  });

  describe('getDriverPosition', () => {
    it('should return driver position when found', async () => {
      const driverId = 'driver-123';
      mockGeopos.mockResolvedValue([['-74.0060', '40.7128']]);

      const result = await getDriverPosition(driverId);

      expect(result).toEqual({
        driverId,
        lat: 40.7128,
        lng: -74.0060,
      });
      expect(mockGeopos).toHaveBeenCalledWith('drivers:active', driverId);
    });

    it('should return null when driver not found', async () => {
      const driverId = 'driver-123';
      mockGeopos.mockResolvedValue([]);

      const result = await getDriverPosition(driverId);

      expect(result).toBeNull();
    });

    it('should return null when position is null', async () => {
      const driverId = 'driver-123';
      mockGeopos.mockResolvedValue([[null, null]]);

      const result = await getDriverPosition(driverId);

      expect(result).toBeNull();
    });

    it('should handle string coordinates', async () => {
      const driverId = 'driver-123';
      mockGeopos.mockResolvedValue([['-74.0060', '40.7128']]);

      const result = await getDriverPosition(driverId);

      expect(result).toEqual({
        driverId,
        lat: 40.7128,
        lng: -74.0060,
      });
    });
  });

  describe('getNearbyDrivers', () => {
    const mockQuery = {
      lat: 40.7128,
      lng: -74.0060,
      radius: 5,
    };

    it('should return nearby drivers', async () => {
      const mockResults: Array<[string, [string, string]]> = [
        ['driver-1', ['-74.0050', '40.7130']],
        ['driver-2', ['-74.0070', '40.7120']],
      ];
      mockCall.mockResolvedValue(mockResults);

      const result = await getNearbyDrivers(mockQuery);

      expect(result).toHaveLength(2);
      expect(result[0].driverId).toBe('driver-1');
      expect(result[0].lat).toBe(40.7130);
      expect(result[0].lng).toBe(-74.0050);
      expect(mockCall).toHaveBeenCalledWith(
        'GEOSEARCH',
        'drivers:active',
        'FROMLONLAT',
        mockQuery.lng.toString(),
        mockQuery.lat.toString(),
        'BYRADIUS',
        mockQuery.radius.toString(),
        'km',
        'ASC',
        'WITHCOORD',
      );
    });

    it('should return empty array when no drivers found', async () => {
      mockCall.mockResolvedValue([]);

      const result = await getNearbyDrivers(mockQuery);

      expect(result).toEqual([]);
    });

    it('should cap results at 50 drivers', async () => {
      const mockResults: Array<[string, [string, string]]> = [];
      for (let i = 0; i < 60; i++) {
        mockResults.push([`driver-${i}`, ['-74.0060', '40.7128']]);
      }
      mockCall.mockResolvedValue(mockResults);

      const result = await getNearbyDrivers(mockQuery);

      expect(result).toHaveLength(50);
    });
  });

  describe('cleanupExpiredDrivers', () => {
    it('should remove expired drivers', async () => {
      const expiredDriverIds = ['driver-1', 'driver-2'];
      mockZrangebyscore.mockResolvedValue(expiredDriverIds);

      const mockPipelineInstance = {
        zrem: jest.fn().mockReturnThis(),
        exec: jest.fn().mockResolvedValue(undefined),
      };
      mockPipeline.mockReturnValue(mockPipelineInstance as any);

      const result = await cleanupExpiredDrivers();

      expect(result).toBe(2);
      expect(mockZrangebyscore).toHaveBeenCalledWith(
        'drivers:ttl',
        0,
        expect.any(Number),
      );
      expect(mockPipelineInstance.zrem).toHaveBeenCalledTimes(4); // 2 drivers * 2 keys each
      expect(mockPipelineInstance.exec).toHaveBeenCalled();
    });

    it('should return 0 when no expired drivers', async () => {
      mockZrangebyscore.mockResolvedValue([]);

      const result = await cleanupExpiredDrivers();

      expect(result).toBe(0);
      expect(mockPipeline).not.toHaveBeenCalled();
    });

    it('should use current timestamp for expiry check', async () => {
      const beforeTime = Date.now();
      mockZrangebyscore.mockResolvedValue([]);

      await cleanupExpiredDrivers();
      const afterTime = Date.now();

      const maxScore = mockZrangebyscore.mock.calls[0][2] as number;
      expect(maxScore).toBeGreaterThanOrEqual(beforeTime);
      expect(maxScore).toBeLessThanOrEqual(afterTime);
    });
  });
});
