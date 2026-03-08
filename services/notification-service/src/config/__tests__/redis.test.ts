// Mock ioredis before importing
const mockOn = jest.fn();
const mockRedisConstructor = jest.fn().mockImplementation(() => ({
  on: mockOn,
}));

jest.mock('ioredis', () => ({
  Redis: mockRedisConstructor,
}));

describe('Redis Config', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.resetModules();
    process.env = { ...originalEnv };
    mockOn.mockClear();
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('Redis client initialization', () => {
    it('should create Redis client with default host and port', () => {
      delete process.env['REDIS_HOST'];
      delete process.env['REDIS_PORT'];
      jest.resetModules();
      require('../redis.js');

      expect(mockRedisConstructor).toHaveBeenCalledWith(
        expect.objectContaining({
          host: 'localhost',
          port: 6379,
          lazyConnect: true,
        }),
      );
    });

    it('should create Redis client with custom host and port from env', () => {
      process.env['REDIS_HOST'] = 'redis.example.com';
      process.env['REDIS_PORT'] = '6380';
      jest.resetModules();
      require('../redis.js');

      expect(mockRedisConstructor).toHaveBeenCalledWith(
        expect.objectContaining({
          host: 'redis.example.com',
          port: 6380,
        }),
      );
    });

    it('should configure retry strategy with max retries', () => {
      jest.resetModules();
      require('../redis.js');

      const callArgs = mockRedisConstructor.mock.calls[0][0] as any;
      expect(callArgs.retryStrategy).toBeDefined();

      const strategy = callArgs.retryStrategy;
      expect(strategy(1)).toBeGreaterThan(0);
      expect(strategy(2)).toBeGreaterThan(0);
      expect(strategy(3)).toBeGreaterThan(0);
      expect(strategy(4)).toBeNull();
    });

    it('should have exponential backoff with max delay of 2s', () => {
      jest.resetModules();
      require('../redis.js');

      const callArgs = mockRedisConstructor.mock.calls[0][0] as any;
      const strategy = callArgs.retryStrategy;

      const delay1 = strategy(1);
      const delay2 = strategy(2);
      const delay3 = strategy(3);

      expect(delay1).toBeLessThanOrEqual(2000);
      expect(delay2).toBeLessThanOrEqual(2000);
      expect(delay3).toBeLessThanOrEqual(2000);
    });
  });

  describe('Redis event handlers', () => {
    it('should register connect event handler', () => {
      jest.resetModules();
      require('../redis.js');

      expect(mockOn).toHaveBeenCalledWith('connect', expect.any(Function));
    });

    it('should register error event handler', () => {
      jest.resetModules();
      require('../redis.js');

      expect(mockOn).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('should register close event handler', () => {
      jest.resetModules();
      require('../redis.js');

      expect(mockOn).toHaveBeenCalledWith('close', expect.any(Function));
    });
  });
});
