import { Request, Response } from 'express';
import * as locationService from '../../services/locationService.js';
import * as pathHistoryService from '../../services/pathHistoryService.js';
import * as batchWriterService from '../../services/batchWriterService.js';
import { query } from '../../config/db.js';

// Mock dependencies
jest.mock('../../services/locationService.js');
jest.mock('../../services/pathHistoryService.js');
jest.mock('../../services/batchWriterService.js');
jest.mock('../../config/db.js');

const mockLocationService = locationService as jest.Mocked<typeof locationService>;
const mockPathHistoryService = pathHistoryService as jest.Mocked<typeof pathHistoryService>;
const mockBatchWriterService = batchWriterService as jest.Mocked<typeof batchWriterService>;
const mockQuery = query as jest.MockedFunction<typeof query>;

// Helper function to find and execute route handler
function findAndExecuteRoute(
  router: any,
  method: string,
  path: string,
  req: Partial<Request>,
  res: Partial<Response>,
): Promise<void> {
  return new Promise((resolve) => {
    const route = router.stack.find(
      (r: any) => r.route?.path === path && r.route?.methods[method.toLowerCase()],
    );
    if (route?.route?.stack?.[0]?.handle) {
      const handler = route.route.stack[0].handle;
      Promise.resolve(handler(req as Request, res as Response)).then(() => resolve());
    } else {
      resolve();
    }
  });
}

// Import router after mocks
import router from '../drivers.js';

describe('Driver Routes', () => {
  let mockReq: Partial<Request>;
  let mockRes: Partial<Response>;

  beforeEach(() => {
    mockReq = {
      params: {},
      query: {},
      body: {},
    };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    jest.clearAllMocks();
  });

  describe('GET /drivers/:id/location', () => {
    const validId = '123e4567-e89b-12d3-a456-426614174000';

    it('should return driver location', async () => {
      const mockLocation = {
        driverId: validId,
        lat: 40.7128,
        lng: -74.0060,
      };
      mockLocationService.getDriverPosition.mockResolvedValue(mockLocation);
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/drivers/:id/location', mockReq, mockRes);

      expect(mockLocationService.getDriverPosition).toHaveBeenCalledWith(validId);
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockLocation });
    });

    it('should return 404 if driver not found', async () => {
      mockLocationService.getDriverPosition.mockResolvedValue(null);
      mockReq.params = { id: validId };

      await findAndExecuteRoute(router, 'get', '/drivers/:id/location', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(404);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'Driver offline or not found' });
    });

    it('should return 400 for invalid UUID', async () => {
      mockReq.params = { id: 'invalid-id' };

      await findAndExecuteRoute(router, 'get', '/drivers/:id/location', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid driver ID format' });
    });
  });

  describe('GET /drivers/nearby', () => {
    it('should return nearby drivers', async () => {
      const mockDrivers = [
        { driverId: 'driver-1', lat: 40.7128, lng: -74.0060, distance: 1.5 },
      ];
      mockLocationService.getNearbyDrivers.mockResolvedValue(mockDrivers);
      mockReq.query = { lat: '40.7128', lng: '-74.0060', radius: '5' };

      await findAndExecuteRoute(router, 'get', '/drivers/nearby', mockReq, mockRes);

      expect(mockLocationService.getNearbyDrivers).toHaveBeenCalled();
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith({
        data: mockDrivers,
        count: mockDrivers.length,
      });
    });

    it('should return 400 if lat is missing', async () => {
      mockReq.query = { lng: '-74.0060' };

      await findAndExecuteRoute(router, 'get', '/drivers/nearby', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'lat and lng query parameters are required',
      });
    });

    it('should return 400 if lng is missing', async () => {
      mockReq.query = { lat: '40.7128' };

      await findAndExecuteRoute(router, 'get', '/drivers/nearby', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'lat and lng query parameters are required',
      });
    });

    it('should return 400 if lat is invalid', async () => {
      mockReq.query = { lat: 'invalid', lng: '-74.0060' };

      await findAndExecuteRoute(router, 'get', '/drivers/nearby', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'lat, lng, and radius must be valid numbers',
      });
    });

    it('should return 400 if lat is out of range', async () => {
      mockReq.query = { lat: '100', lng: '-74.0060' };

      await findAndExecuteRoute(router, 'get', '/drivers/nearby', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({
        error: 'lat must be -90 to 90, lng must be -180 to 180',
      });
    });

    it('should use default radius of 5km', async () => {
      const mockDrivers: any[] = [];
      mockLocationService.getNearbyDrivers.mockResolvedValue(mockDrivers);
      mockReq.query = { lat: '40.7128', lng: '-74.0060' };

      await findAndExecuteRoute(router, 'get', '/drivers/nearby', mockReq, mockRes);

      expect(mockLocationService.getNearbyDrivers).toHaveBeenCalledWith(
        expect.objectContaining({ radius: 5 }),
      );
    });

    it('should cap radius at 50km', async () => {
      const mockDrivers: any[] = [];
      mockLocationService.getNearbyDrivers.mockResolvedValue(mockDrivers);
      mockReq.query = { lat: '40.7128', lng: '-74.0060', radius: '100' };

      await findAndExecuteRoute(router, 'get', '/drivers/nearby', mockReq, mockRes);

      expect(mockLocationService.getNearbyDrivers).toHaveBeenCalledWith(
        expect.objectContaining({ radius: 50 }),
      );
    });
  });

  describe('GET /drivers', () => {
    it('should return all drivers', async () => {
      const mockDrivers = [
        {
          id: 'driver-1',
          name: 'Driver 1',
          phone: '123-456-7890',
          vehicle: 'Car',
          is_active: true,
          created_at: new Date(),
        },
      ];
      mockQuery.mockResolvedValue({ rows: mockDrivers } as any);

      await findAndExecuteRoute(router, 'get', '/drivers', mockReq, mockRes);

      expect(mockQuery).toHaveBeenCalled();
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith({ data: mockDrivers });
    });
  });

  describe('GET /drivers/:id/path', () => {
    const validId = '123e4567-e89b-12d3-a456-426614174000';

    it('should return path from both sources', async () => {
      const redisPath = [{ lat: 40.7128, lng: -74.0060, timestamp: 1000 }];
      const dbPath = [{ lat: 40.7130, lng: -74.0062, timestamp: 2000 }];
      mockPathHistoryService.getPathHistory.mockResolvedValue(redisPath);
      mockBatchWriterService.getPathHistoryFromDB.mockResolvedValue(dbPath);
      mockReq.params = { id: validId };
      mockReq.query = { source: 'both' };

      await findAndExecuteRoute(router, 'get', '/drivers/:id/path', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.any(Array),
          count: expect.any(Number),
          source: 'both',
        }),
      );
    });

    it('should return path from redis only', async () => {
      const redisPath = [{ lat: 40.7128, lng: -74.0060, timestamp: 1000 }];
      mockPathHistoryService.getPathHistory.mockResolvedValue(redisPath);
      mockReq.params = { id: validId };
      mockReq.query = { source: 'redis' };

      await findAndExecuteRoute(router, 'get', '/drivers/:id/path', mockReq, mockRes);

      expect(mockPathHistoryService.getPathHistory).toHaveBeenCalled();
      expect(mockBatchWriterService.getPathHistoryFromDB).not.toHaveBeenCalled();
    });

    it('should return 400 for invalid UUID', async () => {
      mockReq.params = { id: 'invalid-id' };

      await findAndExecuteRoute(router, 'get', '/drivers/:id/path', mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid ID format' });
    });
  });
});
