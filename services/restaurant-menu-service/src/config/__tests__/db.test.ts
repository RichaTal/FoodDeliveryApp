// Mock pg before any requires
jest.mock('pg');

describe('Database Config', () => {
  const originalEnv = process.env;
  let mockPool: any;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv };

    mockPool = {
      query: jest.fn(),
      on: jest.fn(),
    };
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
      delete process.env['DB_POOL_MAX'];

      // Reset module cache so db.ts re-runs with current env vars
      jest.resetModules();
      // Acquire the fresh pg mock and configure Pool on it
      const pg = require('pg');
      pg.Pool = jest.fn().mockImplementation(() => mockPool);

      require('../db.js');

      expect(pg.Pool).toHaveBeenCalledWith(
        expect.objectContaining({
          host: 'localhost',
          port: 5432,
          user: 'foodapp',
          password: 'foodapp',
          database: 'foodapp',
          max: 50,
          idleTimeoutMillis: 30_000,
          connectionTimeoutMillis: 2_000,
          statement_timeout: 5_000,
        }),
      );
    });

    it('should create pool with custom values from env', () => {
      process.env['POSTGRES_HOST'] = 'db.example.com';
      process.env['POSTGRES_PORT'] = '5433';
      process.env['POSTGRES_USER'] = 'customuser';
      process.env['POSTGRES_PASSWORD'] = 'custompass';
      process.env['POSTGRES_DB'] = 'customdb';
      process.env['DB_POOL_MAX'] = '100';

      jest.resetModules();
      const pg = require('pg');
      pg.Pool = jest.fn().mockImplementation(() => mockPool);

      require('../db.js');

      expect(pg.Pool).toHaveBeenCalledWith(
        expect.objectContaining({
          host: 'db.example.com',
          port: 5433,
          user: 'customuser',
          password: 'custompass',
          database: 'customdb',
          max: 100,
        }),
      );
    });

    it('should register pool error handler', () => {
      jest.resetModules();
      const pg = require('pg');
      pg.Pool = jest.fn().mockImplementation(() => mockPool);

      require('../db.js');

      expect(mockPool.on).toHaveBeenCalledWith('error', expect.any(Function));
    });
  });

  describe('query function', () => {
    // query is obtained fresh after each resetModules so it references the correct pool
    let query: (text: string, params?: unknown[]) => Promise<any>;

    beforeEach(() => {
      jest.resetModules();
      const pg = require('pg');
      pg.Pool = jest.fn().mockImplementation(() => mockPool);
      const db = require('../db.js');
      query = db.query;
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
});
