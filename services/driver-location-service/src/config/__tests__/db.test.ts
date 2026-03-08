// Mock pg before importing
const mockPoolFactory = jest.fn();
const mockClientFactory = {
  query: jest.fn(),
  release: jest.fn(),
};

const mockPoolInstance = {
  query: jest.fn(),
  connect: jest.fn().mockResolvedValue(mockClientFactory),
  on: jest.fn(),
};

jest.mock('pg', () => {
  return {
    __esModule: true,
    default: {
      Pool: mockPoolFactory,
    },
    Pool: mockPoolFactory,
  };
});

describe('Database Config', () => {
  const originalEnv = process.env;
  let mockPool: any;
  let mockClient: any;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.resetModules();
    process.env = { ...originalEnv };

    mockClient = {
      query: jest.fn(),
      release: jest.fn(),
    };

    mockPool = {
      query: jest.fn(),
      connect: jest.fn().mockResolvedValue(mockClient),
      on: jest.fn(),
    };

    // Reset the mock factory to return our mock pool
    mockPoolFactory.mockImplementation(() => mockPool);
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('Pool initialization', () => {
    it('should create pool with default values', () => {
      delete process.env['POSTGRES_HOST'];
      delete process.env['POSTGRES_PORT'];
      delete process.env['POSTGRES_USER'];
      delete process.env['POSTGRES_PASSWORD'];
      delete process.env['POSTGRES_DB'];

      jest.resetModules();
      mockPoolFactory.mockImplementation(() => mockPool);
      require('../db.js');

      expect(mockPoolFactory).toHaveBeenCalledWith(
        expect.objectContaining({
          host: 'localhost',
          port: 5432,
          user: 'postgres',
          password: 'postgres123',
          database: 'driver_db',
          max: 20,
          idleTimeoutMillis: 30_000,
          connectionTimeoutMillis: 2_000,
        }),
      );
    });

    it('should create pool with custom values from env', () => {
      process.env['POSTGRES_HOST'] = 'db.example.com';
      process.env['POSTGRES_PORT'] = '5433';
      process.env['POSTGRES_USER'] = 'customuser';
      process.env['POSTGRES_PASSWORD'] = 'custompass';
      process.env['POSTGRES_DB'] = 'customdb';

      jest.resetModules();
      mockPoolFactory.mockImplementation(() => mockPool);
      require('../db.js');

      expect(mockPoolFactory).toHaveBeenCalledWith(
        expect.objectContaining({
          host: 'db.example.com',
          port: 5433,
          user: 'customuser',
          password: 'custompass',
          database: 'customdb',
        }),
      );
    });

    it('should register pool error handler', () => {
      jest.resetModules();
      mockPoolFactory.mockImplementation(() => mockPool);
      require('../db.js');

      expect(mockPool.on).toHaveBeenCalledWith('error', expect.any(Function));
    });
  });

  describe('query function', () => {
    let query: any;
    let getClient: any;

    beforeEach(() => {
      jest.resetModules();
      // Use the mock factory instead of manually overriding
      mockPoolFactory.mockImplementation(() => mockPool);
      const db = require('../db.js');
      query = db.query;
      getClient = db.getClient;
    });

    it('should execute query and return result', async () => {
      const mockResult = {
        rows: [{ id: 1, name: 'test' }],
        rowCount: 1,
      };
      mockPool.query.mockResolvedValue(mockResult);

      const result = await query('SELECT * FROM test');

      expect(mockPool.query).toHaveBeenCalledWith('SELECT * FROM test', undefined);
      expect(result).toBe(mockResult);
    });

    it('should execute query with parameters', async () => {
      const mockResult = {
        rows: [{ id: 1 }],
        rowCount: 1,
      };
      mockPool.query.mockResolvedValue(mockResult);

      const result = await query('SELECT * FROM test WHERE id = $1', [1]);

      expect(mockPool.query).toHaveBeenCalledWith('SELECT * FROM test WHERE id = $1', [1]);
      expect(result).toBe(mockResult);
    });

    it('should handle query errors', async () => {
      const error = new Error('Query failed');
      mockPool.query.mockRejectedValue(error);

      await expect(query('SELECT * FROM test')).rejects.toThrow('Query failed');
    });
  });

  describe('getClient function', () => {
    let getClient: any;

    beforeEach(() => {
      jest.resetModules();
      // Use the mock factory instead of manually overriding
      mockPoolFactory.mockImplementation(() => mockPool);
      const db = require('../db.js');
      getClient = db.getClient;
    });

    it('should return a client from pool', async () => {
      const client = await getClient();

      expect(mockPool.connect).toHaveBeenCalled();
      expect(client).toBe(mockClient);
    });
  });
});