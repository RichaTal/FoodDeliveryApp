import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: process.env['POSTGRES_HOST'] || 'localhost',
  port: parseInt(process.env['POSTGRES_PORT'] || '5432', 10),
  user: process.env['POSTGRES_USER'] || 'postgres',
  password: process.env['POSTGRES_PASSWORD'] || 'postgres123',
  database: process.env['POSTGRES_DB'] || 'restaurant_db',
  max: parseInt(process.env['DB_POOL_MAX'] || '50', 10), // Increased for high concurrency
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 2_000,
  statement_timeout: 5_000, // 5 second query timeout
});

pool.on('error', (err: Error) => {
  // Silently handle pool errors - no logging to avoid performance overhead
  void err; // Suppress unused variable warning
});

export async function query<T extends pg.QueryResultRow = pg.QueryResultRow>(
  text: string,
  params?: unknown[],
): Promise<pg.QueryResult<T>> {
  // Removed console.debug for performance - logging overhead was causing >200ms response times
  return await pool.query<T>(text, params);
}

export default pool;
