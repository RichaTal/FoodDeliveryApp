import {
  registerSession,
  getSessionInstance,
  removeSession,
  refreshSession,
} from '../sessionService.js';
import redisClient from '../../config/redis.js';

// Mock dependencies
jest.mock('../../config/redis.js');

const mockSet = redisClient.set as jest.MockedFunction<typeof redisClient.set>;
const mockGet = redisClient.get as jest.MockedFunction<typeof redisClient.get>;
const mockDel = redisClient.del as jest.MockedFunction<typeof redisClient.del>;
const mockExpire = redisClient.expire as jest.MockedFunction<typeof redisClient.expire>;

describe('sessionService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('registerSession', () => {
    it('should register session with orderId and instanceId', async () => {
      const orderId = 'order-123';
      const instanceId = 'instance-456';
      mockSet.mockResolvedValue('OK');

      await registerSession(orderId, instanceId);

      expect(mockSet).toHaveBeenCalledWith(
        'ws:session:order-123',
        instanceId,
        'EX',
        3600,
      );
    });

    it('should set TTL to 1 hour', async () => {
      const orderId = 'order-123';
      const instanceId = 'instance-456';
      mockSet.mockResolvedValue('OK');

      await registerSession(orderId, instanceId);

      expect(mockSet).toHaveBeenCalledWith(
        expect.any(String),
        instanceId,
        'EX',
        3600,
      );
    });
  });

  describe('getSessionInstance', () => {
    it('should return instanceId when session exists', async () => {
      const orderId = 'order-123';
      const instanceId = 'instance-456';
      mockGet.mockResolvedValue(instanceId);

      const result = await getSessionInstance(orderId);

      expect(result).toBe(instanceId);
      expect(mockGet).toHaveBeenCalledWith('ws:session:order-123');
    });

    it('should return null when session does not exist', async () => {
      const orderId = 'order-123';
      mockGet.mockResolvedValue(null);

      const result = await getSessionInstance(orderId);

      expect(result).toBeNull();
    });
  });

  describe('removeSession', () => {
    it('should delete session', async () => {
      const orderId = 'order-123';
      mockDel.mockResolvedValue(1);

      await removeSession(orderId);

      expect(mockDel).toHaveBeenCalledWith('ws:session:order-123');
    });

    it('should handle deletion of non-existent session', async () => {
      const orderId = 'order-123';
      mockDel.mockResolvedValue(0);

      await expect(removeSession(orderId)).resolves.not.toThrow();
    });
  });

  describe('refreshSession', () => {
    it('should refresh session TTL', async () => {
      const orderId = 'order-123';
      mockExpire.mockResolvedValue(1);

      await refreshSession(orderId);

      expect(mockExpire).toHaveBeenCalledWith('ws:session:order-123', 3600);
    });

    it('should set TTL to 1 hour', async () => {
      const orderId = 'order-123';
      mockExpire.mockResolvedValue(1);

      await refreshSession(orderId);

      expect(mockExpire).toHaveBeenCalledWith(expect.any(String), 3600);
    });
  });
});
