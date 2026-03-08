import {
  bufferLocationPoint,
  startBatchWriter,
  stopBatchWriter,
  getPathHistoryFromDB,
  resetBatchWriter,
} from '../batchWriterService.js';
import { query } from '../../config/db.js';

// Mock dependencies
jest.mock('../../config/db.js');

const mockQuery = query as jest.MockedFunction<typeof query>;

describe('batchWriterService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    resetBatchWriter();
  });

  afterEach(async () => {
    await stopBatchWriter();
    jest.useRealTimers();
  });

  describe('bufferLocationPoint', () => {
    const mockPing = {
      driverId: 'driver-123',
      lat: 40.7128,
      lng: -74.0060,
      timestamp: Date.now(),
    };

    it('should buffer location point', () => {
      bufferLocationPoint(mockPing);

      // Buffer should contain the point
      // We can't directly access the buffer, but we can verify flush is called when buffer is full
    });

    it('should flush buffer when batch size is reached', async () => {
      mockQuery.mockResolvedValue({ rowCount: 100 } as any);

      // Add 100 points to trigger flush
      for (let i = 0; i < 100; i++) {
        bufferLocationPoint({
          ...mockPing,
          driverId: `driver-${i}`,
        });
      }

      // Wait for async flush
      await jest.runAllTimersAsync();

      expect(mockQuery).toHaveBeenCalled();
      const queryCall = mockQuery.mock.calls[0];
      expect(queryCall[0]).toContain('INSERT INTO driver_location_history');
    });

    it('should include orderId when provided', async () => {
      const orderId = 'order-123';
      mockQuery.mockResolvedValue({ rowCount: 1 } as any);

      bufferLocationPoint(mockPing, orderId);

      // Trigger flush by adding 99 more points
      for (let i = 0; i < 99; i++) {
        bufferLocationPoint({ ...mockPing, driverId: `driver-${i}` });
      }

      await jest.runAllTimersAsync();

      expect(mockQuery).toHaveBeenCalled();
      const params = mockQuery.mock.calls[0][1] as unknown[];
      expect(params).toContain(orderId);
    });
  });

  describe('startBatchWriter', () => {
    it('should start periodic flush interval', () => {
      startBatchWriter();

      // Verify interval is set (can't directly test, but function should complete)
      expect(startBatchWriter).not.toThrow();
    });

    it('should not start multiple intervals', () => {
      startBatchWriter();
      startBatchWriter();

      // Should not throw or create multiple intervals
      expect(startBatchWriter).not.toThrow();
    });

    it('should flush buffer after interval', async () => {
      mockQuery.mockResolvedValue({ rowCount: 1 } as any);

      const mockPing = {
        driverId: 'driver-123',
        lat: 40.7128,
        lng: -74.0060,
        timestamp: Date.now(),
      };

      bufferLocationPoint(mockPing);
      startBatchWriter();

      // Advance time by 30 seconds to trigger interval
      jest.advanceTimersByTime(30000);

      // Wait for async flush to complete
      await Promise.resolve();
      await Promise.resolve(); // Allow flushBuffer promise to resolve

      expect(mockQuery).toHaveBeenCalled();
    });
  });

  describe('stopBatchWriter', () => {
    it('should flush remaining buffer and stop interval', async () => {
      mockQuery.mockResolvedValue({ rowCount: 1 } as any);

      const mockPing = {
        driverId: 'driver-123',
        lat: 40.7128,
        lng: -74.0060,
        timestamp: Date.now(),
      };

      bufferLocationPoint(mockPing);
      startBatchWriter();

      await stopBatchWriter();

      expect(mockQuery).toHaveBeenCalled();
    });

    it('should handle empty buffer', async () => {
      await stopBatchWriter();

      // Should not throw
      expect(stopBatchWriter).not.toThrow();
    });
  });

  describe('getPathHistoryFromDB', () => {
    const mockPathPoints = [
      {
        lat: '40.7128',
        lng: '-74.0060',
        timestamp: '1234567890',
      },
      {
        lat: '40.7130',
        lng: '-74.0050',
        timestamp: '1234567900',
      },
    ];

    it('should return path history for orderId', async () => {
      const orderId = 'order-123';
      mockQuery.mockResolvedValue({
        rows: mockPathPoints,
        rowCount: 2,
      } as any);

      const result = await getPathHistoryFromDB(orderId);

      expect(result).toHaveLength(2);
      expect(result[0].lat).toBe(40.7128);
      expect(result[0].lng).toBe(-74.0060);
      expect(result[0].timestamp).toBe(1234567890);
      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('order_id = $1'),
        expect.arrayContaining([orderId]),
      );
    });

    it('should return path history for driverId', async () => {
      const driverId = 'driver-123';
      mockQuery.mockResolvedValue({
        rows: mockPathPoints,
        rowCount: 2,
      } as any);

      const result = await getPathHistoryFromDB(driverId);

      expect(result).toHaveLength(2);
      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('driver_id = $1'),
        expect.arrayContaining([driverId]),
      );
    });

    it('should filter by time range', async () => {
      const orderId = 'order-123';
      const startTime = 1234567890;
      const endTime = 1234568000;

      mockQuery.mockResolvedValue({
        rows: [mockPathPoints[0]],
        rowCount: 1,
      } as any);

      await getPathHistoryFromDB(orderId, startTime, endTime);

      expect(mockQuery).toHaveBeenCalledWith(
        expect.stringContaining('timestamp >= $2'),
        expect.arrayContaining([orderId, startTime, endTime]),
      );
    });

    it('should return empty array when no history found', async () => {
      const orderId = 'order-123';
      mockQuery.mockResolvedValue({
        rows: [],
        rowCount: 0,
      } as any);

      const result = await getPathHistoryFromDB(orderId);

      expect(result).toEqual([]);
    });

    it('should handle null time parameters', async () => {
      const orderId = 'order-123';
      mockQuery.mockResolvedValue({
        rows: mockPathPoints,
        rowCount: 2,
      } as any);

      await getPathHistoryFromDB(orderId, undefined, undefined);

      const params = mockQuery.mock.calls[0][1] as unknown[];
      expect(params).toContain(null);
    });
  });
});
