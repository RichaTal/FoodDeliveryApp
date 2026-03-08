import { Router, type Request, type Response } from 'express';
import { validate as validateUUID } from 'uuid';
import { query } from '../config/db.js';
import { getDriverPosition, getNearbyDrivers } from '../services/locationService.js';
import { getPathHistory } from '../services/pathHistoryService.js';
import { getPathHistoryFromDB } from '../services/batchWriterService.js';
import type { Driver, NearbyDriversQuery } from '../types/index.js';

const router = Router();

/**
 * @swagger
 * /drivers/{id}/location:
 *   get:
 *     summary: Get the current location of a driver
 *     tags: [Drivers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Driver UUID
 *     responses:
 *       200:
 *         description: Current driver location from Redis GEO
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/DriverLocation'
 *       400:
 *         description: Invalid driver ID format
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Driver is offline or not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/drivers/:id/location', async (req: Request, res: Response) => {
  const { id } = req.params;

  // Validate UUID format
  if (!validateUUID(id)) {
    return res.status(400).json({ error: 'Invalid driver ID format' });
  }

  try {
    const location = await getDriverPosition(id);

    if (!location) {
      return res.status(404).json({ error: 'Driver offline or not found' });
    }

    return res.status(200).json({ data: location });
  } catch (err) {
    const error = err as Error;
    console.log('[Route] Error getting driver location:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /drivers/nearby:
 *   get:
 *     summary: Get drivers within a radius of a location
 *     tags: [Drivers]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *           minimum: -90
 *           maximum: 90
 *         description: Latitude of the search center
 *       - in: query
 *         name: lng
 *         required: true
 *         schema:
 *           type: number
 *           minimum: -180
 *           maximum: 180
 *         description: Longitude of the search center
 *       - in: query
 *         name: radius
 *         required: false
 *         schema:
 *           type: number
 *           minimum: 0
 *           maximum: 50
 *           default: 5
 *         description: Search radius in kilometres (max 50, default 5)
 *     responses:
 *       200:
 *         description: List of nearby drivers with distance
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/NearbyDriver'
 *                 count:
 *                   type: integer
 *       400:
 *         description: Missing or invalid query parameters
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/drivers/nearby', async (req: Request, res: Response) => {
  const latParam = req.query.lat;
  const lngParam = req.query.lng;
  const radiusParam = req.query.radius;

  // Validate required params
  if (!latParam || !lngParam) {
    return res.status(400).json({ error: 'lat and lng query parameters are required' });
  }

  const lat = parseFloat(latParam as string);
  const lng = parseFloat(lngParam as string);
  const radius = radiusParam ? parseFloat(radiusParam as string) : 5; // default 5 km

  // Validate numeric values
  if (isNaN(lat) || isNaN(lng) || isNaN(radius)) {
    return res.status(400).json({ error: 'lat, lng, and radius must be valid numbers' });
  }

  // Validate ranges
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return res.status(400).json({ error: 'lat must be -90 to 90, lng must be -180 to 180' });
  }

  // Validate radius (max 50 km)
  const validatedRadius = Math.min(Math.max(radius, 0), 50);

  try {
    const query: NearbyDriversQuery = {
      lat,
      lng,
      radius: validatedRadius,
    };

    const drivers = await getNearbyDrivers(query);

    return res.status(200).json({
      data: drivers,
      count: drivers.length,
    });
  } catch (err) {
    const error = err as Error;
    console.log('[Route] Error getting nearby drivers:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /drivers:
 *   get:
 *     summary: List all driver profiles (admin)
 *     tags: [Drivers]
 *     responses:
 *       200:
 *         description: Array of all driver profiles
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Driver'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/drivers', async (_req: Request, res: Response) => {
  try {
    const result = await query<Driver>(
      'SELECT id, name, phone, vehicle, is_active, created_at FROM drivers ORDER BY name',
    );

    return res.status(200).json({ data: result.rows });
  } catch (err) {
    const error = err as Error;
    console.log('[Route] Error getting drivers:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /drivers/{id}/path:
 *   get:
 *     summary: Get GPS path history for a driver
 *     tags: [Drivers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Driver UUID
 *       - in: query
 *         name: startTime
 *         required: false
 *         schema:
 *           type: integer
 *         description: Start of time range (Unix ms timestamp)
 *       - in: query
 *         name: endTime
 *         required: false
 *         schema:
 *           type: integer
 *         description: End of time range (Unix ms timestamp)
 *       - in: query
 *         name: source
 *         required: false
 *         schema:
 *           type: string
 *           enum: [redis, db, both]
 *           default: both
 *         description: >
 *           Data source — redis (recent ≤2h), db (PostgreSQL long-term),
 *           both (merged & deduplicated)
 *     responses:
 *       200:
 *         description: Ordered array of GPS path points
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/PathPoint'
 *                 count:
 *                   type: integer
 *                 source:
 *                   type: string
 *                   enum: [redis, db, both]
 *       400:
 *         description: Invalid UUID or invalid time parameters
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/drivers/:id/path', async (req: Request, res: Response) => {
  const { id } = req.params;
  const startTimeParam = req.query.startTime;
  const endTimeParam = req.query.endTime;
  const source = (req.query.source as string) || 'both'; // 'redis', 'db', or 'both'

  // Validate UUID format
  if (!validateUUID(id)) {
    return res.status(400).json({ error: 'Invalid ID format' });
  }

  const startTime = startTimeParam ? parseInt(startTimeParam as string, 10) : undefined;
  const endTime = endTimeParam ? parseInt(endTimeParam as string, 10) : undefined;

  if (startTime && isNaN(startTime)) {
    return res.status(400).json({ error: 'startTime must be a valid number' });
  }

  if (endTime && isNaN(endTime)) {
    return res.status(400).json({ error: 'endTime must be a valid number' });
  }

  try {
    let redisPath: Array<{ lat: number; lng: number; timestamp: number }> = [];
    let dbPath: Array<{ lat: number; lng: number; timestamp: number }> = [];

    // Get from Redis (recent path, last 2 hours)
    if (source === 'redis' || source === 'both') {
      try {
        redisPath = await getPathHistory(id, startTime, endTime);
      } catch (err) {
        console.warn('[Route] Error getting path from Redis:', err);
      }
    }

    // Get from PostgreSQL (long-term storage)
    if (source === 'db' || source === 'both') {
      try {
        dbPath = await getPathHistoryFromDB(id, startTime, endTime);
      } catch (err) {
        console.warn('[Route] Error getting path from DB:', err);
      }
    }

    // Merge paths if both sources requested
    let mergedPath: Array<{ lat: number; lng: number; timestamp: number }> = [];
    if (source === 'both') {
      // Combine and deduplicate by timestamp
      const pathMap = new Map<number, { lat: number; lng: number; timestamp: number }>();
      
      [...dbPath, ...redisPath].forEach((point) => {
        // Use Redis data if duplicate (more recent)
        if (!pathMap.has(point.timestamp) || pathMap.get(point.timestamp)!.timestamp < point.timestamp) {
          pathMap.set(point.timestamp, point);
        }
      });
      
      mergedPath = Array.from(pathMap.values()).sort((a, b) => a.timestamp - b.timestamp);
    } else if (source === 'redis') {
      mergedPath = redisPath;
    } else {
      mergedPath = dbPath;
    }

    return res.status(200).json({
      data: mergedPath,
      count: mergedPath.length,
      source,
    });
  } catch (err) {
    const error = err as Error;
    console.log('[Route] Error getting path history:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /orders/{orderId}/path:
 *   get:
 *     summary: Get GPS path history for an order's driver
 *     tags: [Orders]
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Order UUID
 *       - in: query
 *         name: startTime
 *         required: false
 *         schema:
 *           type: integer
 *         description: Start of time range (Unix ms timestamp)
 *       - in: query
 *         name: endTime
 *         required: false
 *         schema:
 *           type: integer
 *         description: End of time range (Unix ms timestamp)
 *       - in: query
 *         name: source
 *         required: false
 *         schema:
 *           type: string
 *           enum: [redis, db, both]
 *           default: both
 *         description: >
 *           Data source — redis (recent ≤2h), db (PostgreSQL long-term),
 *           both (merged & deduplicated)
 *     responses:
 *       200:
 *         description: Ordered array of GPS path points for the order's delivery route
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/PathPoint'
 *                 count:
 *                   type: integer
 *                 source:
 *                   type: string
 *                   enum: [redis, db, both]
 *       400:
 *         description: Invalid order ID or invalid time parameters
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/orders/:orderId/path', async (req: Request, res: Response) => {
  const { orderId } = req.params;
  const startTimeParam = req.query.startTime;
  const endTimeParam = req.query.endTime;
  const source = (req.query.source as string) || 'both';

  // Validate UUID format
  if (!validateUUID(orderId)) {
    return res.status(400).json({ error: 'Invalid order ID format' });
  }

  const startTime = startTimeParam ? parseInt(startTimeParam as string, 10) : undefined;
  const endTime = endTimeParam ? parseInt(endTimeParam as string, 10) : undefined;

  if (startTime && isNaN(startTime)) {
    return res.status(400).json({ error: 'startTime must be a valid number' });
  }

  if (endTime && isNaN(endTime)) {
    return res.status(400).json({ error: 'endTime must be a valid number' });
  }

  try {
    let redisPath: Array<{ lat: number; lng: number; timestamp: number }> = [];
    let dbPath: Array<{ lat: number; lng: number; timestamp: number }> = [];

    // Get from Redis (recent path, last 2 hours)
    if (source === 'redis' || source === 'both') {
      try {
        redisPath = await getPathHistory(orderId, startTime, endTime);
      } catch (err) {
        console.warn('[Route] Error getting path from Redis:', err);
      }
    }

    // Get from PostgreSQL (long-term storage)
    if (source === 'db' || source === 'both') {
      try {
        dbPath = await getPathHistoryFromDB(orderId, startTime, endTime);
      } catch (err) {
        console.warn('[Route] Error getting path from DB:', err);
      }
    }

    // Merge paths if both sources requested
    let mergedPath: Array<{ lat: number; lng: number; timestamp: number }> = [];
    if (source === 'both') {
      // Combine and deduplicate by timestamp
      const pathMap = new Map<number, { lat: number; lng: number; timestamp: number }>();
      
      [...dbPath, ...redisPath].forEach((point) => {
        // Use Redis data if duplicate (more recent)
        if (!pathMap.has(point.timestamp) || pathMap.get(point.timestamp)!.timestamp < point.timestamp) {
          pathMap.set(point.timestamp, point);
        }
      });
      
      mergedPath = Array.from(pathMap.values()).sort((a, b) => a.timestamp - b.timestamp);
    } else if (source === 'redis') {
      mergedPath = redisPath;
    } else {
      mergedPath = dbPath;
    }

    return res.status(200).json({
      data: mergedPath,
      count: mergedPath.length,
      source,
    });
  } catch (err) {
    const error = err as Error;
    console.log('[Route] Error getting path history:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @swagger
 * /drivers/{id}/status:
 *   patch:
 *     summary: Update driver active status
 *     tags: [Drivers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Driver UUID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - is_active
 *             properties:
 *               is_active:
 *                 type: boolean
 *                 description: Set driver as active (true) or inactive (false)
 *                 example: true
 *     responses:
 *       200:
 *         description: Driver status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       format: uuid
 *                     is_active:
 *                       type: boolean
 *       400:
 *         description: Invalid driver ID format or invalid request body
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Driver not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.patch('/drivers/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { is_active } = req.body;

  // Validate UUID format
  if (!validateUUID(id)) {
    return res.status(400).json({ error: 'Invalid driver ID format' });
  }

  // Validate request body
  if (typeof is_active !== 'boolean') {
    return res.status(400).json({ error: 'is_active must be a boolean value' });
  }

  try {
    // Check if driver exists
    const checkResult = await query<{ id: string }>(
      'SELECT id FROM drivers WHERE id = $1',
      [id],
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    // Update driver status
    const updateResult = await query<{ id: string; is_active: boolean }>(
      'UPDATE drivers SET is_active = $1 WHERE id = $2 RETURNING id, is_active',
      [is_active, id],
    );

    return res.status(200).json({
      data: updateResult.rows[0],
    });
  } catch (err) {
    const error = err as Error;
    console.log('[Route] Error updating driver status:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
