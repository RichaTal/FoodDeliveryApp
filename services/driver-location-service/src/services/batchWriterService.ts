import { query } from '../config/db.js';
import type { GpsPing } from '../types/index.js';

// In-memory buffer for batch writes
interface BufferedLocation {
  driverId: string;
  orderId: string | null;
  lat: number;
  lng: number;
  timestamp: number;
}

const BATCH_SIZE = 100; // Write to PostgreSQL every 100 points
const BATCH_INTERVAL_MS = 30_000; // Or every 30 seconds, whichever comes first

let locationBuffer: BufferedLocation[] = [];
let lastFlushTime = Date.now();
let flushInterval: NodeJS.Timeout | null = null;

/**
 * Add location point to buffer for batch writing to PostgreSQL
 */
export function bufferLocationPoint(
  ping: GpsPing,
  orderId?: string | null,
): void {
  locationBuffer.push({
    driverId: ping.driverId,
    orderId: orderId || null,
    lat: ping.lat,
    lng: ping.lng,
    timestamp: ping.timestamp,
  });
  
  // Flush if buffer is full
  if (locationBuffer.length >= BATCH_SIZE) {
    flushBuffer().catch((err) => {
      console.error('[BatchWriter] Error flushing buffer:', err);
    });
  }
}

/**
 * Flush buffered locations to PostgreSQL
 */
async function flushBuffer(): Promise<void> {
  if (locationBuffer.length === 0) {
    return;
  }
  
  const toWrite = [...locationBuffer];
  locationBuffer = []; // Clear buffer immediately
  lastFlushTime = Date.now();
  
  try {
    // Use batch insert for efficiency
    const values = toWrite.map(
      (_, idx) =>
        `($${idx * 5 + 1}, $${idx * 5 + 2}, $${idx * 5 + 3}, $${idx * 5 + 4}, $${idx * 5 + 5})`,
    );
    
    const params: unknown[] = [];
    toWrite.forEach((loc) => {
      params.push(loc.driverId, loc.orderId, loc.lat, loc.lng, loc.timestamp);
    });
    
    const queryText = `
      INSERT INTO driver_location_history (driver_id, order_id, lat, lng, timestamp)
      VALUES ${values.join(', ')}
    `;
    
    await query(queryText, params);
    
    console.debug(
      `[BatchWriter] Wrote ${toWrite.length} location points to PostgreSQL`,
    );
  } catch (err) {
    const error = err as Error;
    console.error('[BatchWriter] Failed to write batch:', error.message);
    // Optionally: re-add to buffer or dead-letter queue
    // For now, we'll accept data loss for non-critical path history
  }
}

/**
 * Start periodic flush interval
 */
export function startBatchWriter(): void {
  if (flushInterval) {
    return; // Already started
  }
  
  flushInterval = setInterval(() => {
    // Flush if buffer has data, regardless of time since last flush
    // (the interval itself ensures periodic flushing)
    if (locationBuffer.length > 0) {
      flushBuffer().catch((err) => {
        console.error('[BatchWriter] Error in periodic flush:', err);
      });
    }
  }, BATCH_INTERVAL_MS);
  
  console.info('[BatchWriter] Started periodic flush interval');
}

/**
 * Stop batch writer and flush remaining buffer
 */
export async function stopBatchWriter(): Promise<void> {
  if (flushInterval) {
    clearInterval(flushInterval);
    flushInterval = null;
  }
  
  // Flush remaining buffer
  await flushBuffer();
  console.info('[BatchWriter] Stopped and flushed remaining buffer');
}

/**
 * Reset batch writer state (for testing purposes)
 */
export function resetBatchWriter(): void {
  if (flushInterval) {
    clearInterval(flushInterval);
    flushInterval = null;
  }
  locationBuffer = [];
  lastFlushTime = Date.now();
}

/**
 * Get path history from PostgreSQL for a given orderId or driverId
 */
export async function getPathHistoryFromDB(
  orderIdOrDriverId: string,
  startTime?: number,
  endTime?: number,
): Promise<Array<{ lat: number; lng: number; timestamp: number }>> {
  // Try to determine if it's an orderId (UUID format) or driverId
  // Order IDs typically have UUID format with dashes, driver IDs might be simpler
  // For now, check if it starts with "order-" or contains UUID pattern
  const isOrderId = orderIdOrDriverId.startsWith('order-') || 
                    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(orderIdOrDriverId);
  
  let queryText: string;
  let params: unknown[];
  
  if (isOrderId) {
    // Query by orderId
    queryText = `
      SELECT lat, lng, timestamp
      FROM driver_location_history
      WHERE order_id = $1
        AND ($2::BIGINT IS NULL OR timestamp >= $2)
        AND ($3::BIGINT IS NULL OR timestamp <= $3)
      ORDER BY timestamp ASC
    `;
    params = [orderIdOrDriverId, startTime || null, endTime || null];
  } else {
    // Query by driverId
    queryText = `
      SELECT lat, lng, timestamp
      FROM driver_location_history
      WHERE driver_id = $1
        AND ($2::BIGINT IS NULL OR timestamp >= $2)
        AND ($3::BIGINT IS NULL OR timestamp <= $3)
      ORDER BY timestamp ASC
    `;
    params = [orderIdOrDriverId, startTime || null, endTime || null];
  }
  
  const result = await query<{
    lat: string;
    lng: string;
    timestamp: string;
  }>(queryText, params);
  
  return result.rows.map((row) => ({
    lat: parseFloat(row.lat),
    lng: parseFloat(row.lng),
    timestamp: parseInt(row.timestamp, 10),
  }));
}
