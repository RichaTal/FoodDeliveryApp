import { getActiveOrderId, invalidateOrderCache } from '../orderLookupService.js';

// ── Mock Redis ────────────────────────────────────────────────────────────────
const mockRedisGet = jest.fn();
const mockRedisSetex = jest.fn();
const mockRedisDel = jest.fn();

jest.mock('../../config/redis.js', () => ({
  __esModule: true,
  default: {
    get: (...args: unknown[]) => mockRedisGet(...args),
    setex: (...args: unknown[]) => mockRedisSetex(...args),
    del: (...args: unknown[]) => mockRedisDel(...args),
  },
}));

// ── Mock global fetch ─────────────────────────────────────────────────────────
const mockFetch = jest.fn();
global.fetch = mockFetch as unknown as typeof fetch;

// ── Helpers ───────────────────────────────────────────────────────────────────

function makeOrderResponse(orderId: string) {
  return {
    ok: true,
    status: 200,
    json: async () => ({ data: { orderId } }),
  };
}

function make404Response() {
  return { ok: false, status: 404, json: async () => ({}) };
}

function make500Response() {
  return { ok: false, status: 500, json: async () => ({}) };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('orderLookupService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default: Redis cache miss
    mockRedisGet.mockResolvedValue(null);
    mockRedisSetex.mockResolvedValue('OK');
    mockRedisDel.mockResolvedValue(1);
  });

  describe('getActiveOrderId', () => {
    it('should return orderId from Redis cache when available', async () => {
      const driverId = 'driver-123';
      const orderId = 'order-abc';

      mockRedisGet.mockResolvedValue(orderId);

      const result = await getActiveOrderId(driverId);

      expect(result).toBe(orderId);
      expect(mockFetch).not.toHaveBeenCalled();
      expect(mockRedisGet).toHaveBeenCalledWith(`driver-order-lookup:${driverId}`);
    });

    it('should return null when Redis cache holds sentinel "null"', async () => {
      const driverId = 'driver-123';
      mockRedisGet.mockResolvedValue('null');

      const result = await getActiveOrderId(driverId);

      expect(result).toBeNull();
      expect(mockFetch).not.toHaveBeenCalled();
    });

    it('should call order-service API on cache miss and return orderId', async () => {
      const driverId = 'driver-123';
      const orderId = 'order-abc';

      mockFetch.mockResolvedValue(makeOrderResponse(orderId));

      const result = await getActiveOrderId(driverId);

      expect(result).toBe(orderId);
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining(`/orders/driver/${driverId}/active`),
        expect.any(Object),
      );
    });

    it('should cache the returned orderId in Redis after API call', async () => {
      const driverId = 'driver-123';
      const orderId = 'order-abc';

      mockFetch.mockResolvedValue(makeOrderResponse(orderId));

      await getActiveOrderId(driverId);

      expect(mockRedisSetex).toHaveBeenCalledWith(
        `driver-order-lookup:${driverId}`,
        30,
        orderId,
      );
    });

    it('should return null and cache "null" when order-service returns 404', async () => {
      const driverId = 'driver-123';
      mockFetch.mockResolvedValue(make404Response());

      const result = await getActiveOrderId(driverId);

      expect(result).toBeNull();
      expect(mockRedisSetex).toHaveBeenCalledWith(
        `driver-order-lookup:${driverId}`,
        30,
        'null',
      );
    });

    it('should return null without caching when order-service returns 5xx', async () => {
      const driverId = 'driver-123';
      mockFetch.mockResolvedValue(make500Response());

      const result = await getActiveOrderId(driverId);

      expect(result).toBeNull();
      expect(mockRedisSetex).not.toHaveBeenCalled();
    });

    it('should return null when fetch throws (network error)', async () => {
      const driverId = 'driver-123';
      mockFetch.mockRejectedValue(new Error('Network error'));

      const result = await getActiveOrderId(driverId);

      expect(result).toBeNull();
    });

    it('should return null (not throw) when Redis get fails, then hit API', async () => {
      const driverId = 'driver-123';
      const orderId = 'order-abc';

      mockRedisGet.mockRejectedValue(new Error('Redis down'));
      mockFetch.mockResolvedValue(makeOrderResponse(orderId));

      const result = await getActiveOrderId(driverId);

      expect(result).toBe(orderId);
      expect(mockFetch).toHaveBeenCalled();
    });

    it('should still return orderId even when Redis setex fails', async () => {
      const driverId = 'driver-123';
      const orderId = 'order-abc';

      mockFetch.mockResolvedValue(makeOrderResponse(orderId));
      mockRedisSetex.mockRejectedValue(new Error('Redis write error'));

      const result = await getActiveOrderId(driverId);

      expect(result).toBe(orderId);
    });
  });

  describe('invalidateOrderCache', () => {
    it('should delete the Redis cache key for the driver', async () => {
      const driverId = 'driver-123';

      await invalidateOrderCache(driverId);

      expect(mockRedisDel).toHaveBeenCalledWith(`driver-order-lookup:${driverId}`);
    });

    it('should not throw when Redis del fails', async () => {
      const driverId = 'driver-123';
      mockRedisDel.mockRejectedValue(new Error('Redis error'));

      await expect(invalidateOrderCache(driverId)).resolves.toBeUndefined();
    });
  });
});
