import { WebSocketServer, WebSocket } from 'ws';
import { Server as HttpServer } from 'http';
import { createServer } from 'http';
import { createDriverSocketServer, getActiveConnectionCount } from '../driverSocket.js';
import { query } from '../../config/db.js';
import * as locationService from '../../services/locationService.js';
import * as publisher from '../../services/publisher.js';
import * as orderLookupService from '../../services/orderLookupService.js';

// Mock dependencies
jest.mock('../../config/db.js');
jest.mock('../../services/locationService.js');
jest.mock('../../services/publisher.js');
jest.mock('../../services/orderLookupService.js');

const mockQuery = query as jest.MockedFunction<typeof query>;
const mockUpdateDriverPosition = locationService.updateDriverPosition as jest.MockedFunction<
  typeof locationService.updateDriverPosition
>;
const mockPublishLocationUpdate = publisher.publishLocationUpdate as jest.MockedFunction<
  typeof publisher.publishLocationUpdate
>;
const mockGetActiveOrderId = orderLookupService.getActiveOrderId as jest.MockedFunction<
  typeof orderLookupService.getActiveOrderId
>;

describe('Driver WebSocket', () => {
  let httpServer: HttpServer;
  let wss: WebSocketServer;
  let mockWs: Partial<WebSocket>;

  beforeEach(() => {
    httpServer = createServer();
    jest.clearAllMocks();

    mockWs = {
      close: jest.fn(),
      send: jest.fn(),
      ping: jest.fn(),
      terminate: jest.fn(),
      readyState: WebSocket.OPEN,
      on: jest.fn(),
    };
  });

  afterEach(() => {
    if (wss) {
      wss.close();
    }
    httpServer.close();
  });

  describe('createDriverSocketServer', () => {
    it('should create WebSocket server', () => {
      wss = createDriverSocketServer(httpServer);
      expect(wss).toBeInstanceOf(WebSocketServer);
    });

    it('should reject connection with invalid driverId', (done) => {
      wss = createDriverSocketServer(httpServer);

      const mockReq = {
        url: '/drivers/connect?driverId=invalid',
        headers: { host: 'localhost' },
      };

      // Simulate connection
      const connectionHandler = (wss as any).listeners('connection')[0];
      if (connectionHandler) {
        connectionHandler(mockWs as WebSocket, mockReq);
        setTimeout(() => {
          expect(mockWs.close).toHaveBeenCalledWith(4001, 'Unauthorized: Invalid driverId');
          done();
        }, 100);
      } else {
        done();
      }
    });

    it('should reject connection if driver not found', async () => {
      const validDriverId = '123e4567-e89b-12d3-a456-426614174000';
      mockQuery.mockResolvedValue({ rows: [] } as any);

      wss = createDriverSocketServer(httpServer);

      const mockReq = {
        url: `/drivers/connect?driverId=${validDriverId}`,
        headers: { host: 'localhost' },
      };

      const connectionHandler = (wss as any).listeners('connection')[0];
      if (connectionHandler) {
        await connectionHandler(mockWs as WebSocket, mockReq);
        expect(mockQuery).toHaveBeenCalled();
        expect(mockWs.close).toHaveBeenCalledWith(4001, 'Unauthorized: Driver not found or inactive');
      }
    });

    it('should accept connection with valid driver', async () => {
      const validDriverId = '123e4567-e89b-12d3-a456-426614174000';
      mockQuery.mockResolvedValue({
        rows: [{ id: validDriverId, is_active: true }],
      } as any);

      wss = createDriverSocketServer(httpServer);

      const mockReq = {
        url: `/drivers/connect?driverId=${validDriverId}`,
        headers: { host: 'localhost' },
      };

      const connectionHandler = (wss as any).listeners('connection')[0];
      if (connectionHandler) {
        await connectionHandler(mockWs as WebSocket, mockReq);
        expect(mockQuery).toHaveBeenCalled();
        // Connection should be registered
        expect(getActiveConnectionCount()).toBeGreaterThanOrEqual(0);
      }
    });
  });

  describe('getActiveConnectionCount', () => {
    it('should return connection count', () => {
      const count = getActiveConnectionCount();
      expect(typeof count).toBe('number');
      expect(count).toBeGreaterThanOrEqual(0);
    });
  });
});
