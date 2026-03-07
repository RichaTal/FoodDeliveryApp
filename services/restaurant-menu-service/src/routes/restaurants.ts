import { Router, Request, Response, NextFunction } from 'express';
import { validate as uuidValidate } from 'uuid';
import {
  getAllRestaurants,
  getFullMenu,
  createRestaurant,
  updateMenuItem,
  getRestaurantCount,
  getRestaurantById,
} from '../services/menuService.js';
import type { CreateRestaurantPayload, UpdateMenuItemPayload } from '../types/index.js';

const router = Router();

// ── UUID guard ───────────────────────────────────────────────────────────────

function assertUUID(value: string, res: Response): boolean {
  if (!uuidValidate(value)) {
    res.status(400).json({ error: `Invalid UUID: "${value}"` });
    return false;
  }
  return true;
}

// ── GET /restaurants/count ────────────────────────────────────────────────────
// Must be defined before /restaurants to avoid route matching conflicts

/**
 * @swagger
 * /restaurants/count:
 *   get:
 *     summary: Get the total number of restaurants
 *     tags: [Restaurants]
 *     responses:
 *       200:
 *         description: Total restaurant count
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 count:
 *                   type: integer
 *                   example: 42
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/restaurants/count', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const count = await getRestaurantCount();
    res.json({ count });
  } catch (err) {
    next(err);
  }
});

// ── GET /restaurants ─────────────────────────────────────────────────────────

/**
 * @swagger
 * /restaurants:
 *   get:
 *     summary: List all restaurants
 *     tags: [Restaurants]
 *     responses:
 *       200:
 *         description: Array of all restaurants
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Restaurant'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.get('/restaurants', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await getAllRestaurants();
    res.json({ data });
  } catch (err) {
    next(err);
  }
});

// ── GET /restaurants/:id ──────────────────────────────────────────────────────

/**
 * @swagger
 * /restaurants/{id}:
 *   get:
 *     summary: Get a restaurant by ID
 *     tags: [Restaurants]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Restaurant UUID
 *     responses:
 *       200:
 *         description: Restaurant details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/Restaurant'
 *       400:
 *         description: Invalid UUID format
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Restaurant not found
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
router.get('/restaurants/:id', async (req: Request, res: Response, next: NextFunction) => {
  const { id } = req.params;

  if (!assertUUID(id, res)) return;

  try {
    const restaurant = await getRestaurantById(id);

    if (!restaurant) {
      res.status(404).json({ error: `Restaurant "${id}" not found` });
      return;
    }

    res.json({ data: restaurant });
  } catch (err) {
    next(err);
  }
});

// ── GET /restaurants/:id/menu ────────────────────────────────────────────────

/**
 * @swagger
 * /restaurants/{id}/menu:
 *   get:
 *     summary: Get the full menu for a restaurant
 *     tags: [Restaurants]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Restaurant UUID
 *     responses:
 *       200:
 *         description: Full menu with categories and items
 *         headers:
 *           X-Cache:
 *             schema:
 *               type: string
 *               enum: [HIT, MISS]
 *             description: Indicates whether the response was served from Redis cache
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/FullMenu'
 *       400:
 *         description: Invalid UUID format
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Restaurant not found
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
router.get(
  '/restaurants/:id/menu',
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;

    if (!assertUUID(id, res)) return;

    try {
      const { menu, cacheHit } = await getFullMenu(id);

      if (!menu) {
        res.status(404).json({ error: `Restaurant "${id}" not found` });
        return;
      }

      res.setHeader('X-Cache', cacheHit ? 'HIT' : 'MISS');
      res.json({ data: menu });
    } catch (err) {
      next(err);
    }
  },
);

// ── POST /restaurants ────────────────────────────────────────────────────────

/**
 * @swagger
 * /restaurants:
 *   post:
 *     summary: Create a new restaurant
 *     tags: [Restaurants]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateRestaurantPayload'
 *     responses:
 *       201:
 *         description: Restaurant created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/Restaurant'
 *       400:
 *         description: Validation failed — missing or invalid fields
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       409:
 *         description: Restaurant already exists (unique constraint violation)
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
router.post('/restaurants', async (req: Request, res: Response, next: NextFunction) => {
  const body = req.body as Partial<CreateRestaurantPayload>;

  const errors: string[] = [];
  if (!body.name || typeof body.name !== 'string') errors.push('name is required');
  if (!body.address || typeof body.address !== 'string') errors.push('address is required');
  if (body.lat === undefined || typeof body.lat !== 'number') errors.push('lat is required and must be a number');
  if (body.lng === undefined || typeof body.lng !== 'number') errors.push('lng is required and must be a number');

  if (errors.length > 0) {
    res.status(400).json({ error: 'Validation failed', details: errors });
    return;
  }

  try {
    const data = await createRestaurant(body as CreateRestaurantPayload);
    res.status(201).json({ data });
  } catch (err) {
    next(err);
  }
});

// ── PUT /restaurants/:id/menu-items/:itemId ──────────────────────────────────

/**
 * @swagger
 * /restaurants/{id}/menu-items/{itemId}:
 *   put:
 *     summary: Update a menu item for a restaurant
 *     tags: [Restaurants]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Restaurant UUID
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Menu item UUID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdateMenuItemPayload'
 *     responses:
 *       200:
 *         description: Menu item updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/MenuItem'
 *       400:
 *         description: Validation failed — no valid fields provided or invalid price type
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Menu item not found for this restaurant
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
router.put(
  '/restaurants/:id/menu-items/:itemId',
  async (req: Request, res: Response, next: NextFunction) => {
    const { id, itemId } = req.params;

    if (!assertUUID(id, res) || !assertUUID(itemId, res)) return;

    const body = req.body as Partial<UpdateMenuItemPayload>;
    const allowed = ['name', 'description', 'price', 'is_available'];
    const provided = allowed.filter((k) => k in body);

    if (provided.length === 0) {
      res.status(400).json({
        error: 'At least one of name, price, description, is_available must be provided',
      });
      return;
    }

    // Type-check numeric price
    if (body.price !== undefined && typeof body.price !== 'number') {
      res.status(400).json({ error: 'price must be a number' });
      return;
    }

    try {
      const data = await updateMenuItem(id, itemId, body as UpdateMenuItemPayload);

      if (!data) {
        res.status(404).json({ error: `Menu item "${itemId}" not found for restaurant "${id}"` });
        return;
      }

      res.json({ data });
    } catch (err) {
      next(err);
    }
  },
);

export default router;
