import { Router, Request, Response, NextFunction } from 'express';
import { validate as uuidValidate } from 'uuid';
import {
  placeOrder,
  getOrder,
  updateOrderStatus,
  getActiveOrderForDriver,
} from '../services/orderService.js';
import type {
  CreateOrderBody,
} from '../types/index.js';
import {
  OrderStatus,
  RestaurantNotAvailableError as RestaurantNotAvailableErrorClass,
  MenuItemNotAvailableError as MenuItemNotAvailableErrorClass,
  PaymentFailedError as PaymentFailedErrorClass,
  InvalidStatusTransitionError as InvalidStatusTransitionErrorClass,
} from '../types/index.js';

const router = Router();

// ── UUID guard ───────────────────────────────────────────────────────────────

function assertUUID(value: string, res: Response): boolean {
  if (!uuidValidate(value)) {
    res.status(400).json({ error: `Invalid UUID: "${value}"` });
    return false;
  }
  return true;
}

// ── POST /orders ─────────────────────────────────────────────────────────────

/**
 * @swagger
 * /orders:
 *   post:
 *     summary: Place a new order
 *     tags: [Orders]
 *     parameters:
 *       - in: header
 *         name: Idempotency-Key
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: >
 *           A unique UUID used to deduplicate requests. If the same key is sent
 *           twice, the second request returns the cached result from the first.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateOrderBody'
 *     responses:
 *       202:
 *         description: Order accepted and queued for processing
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: object
 *                   properties:
 *                     orderId:
 *                       type: string
 *                       format: uuid
 *                     status:
 *                       type: string
 *                       enum: [PENDING, CONFIRMED, PREPARING, PICKED_UP, DELIVERED, CANCELLED]
 *       400:
 *         description: Missing or invalid Idempotency-Key, or validation errors in the request body
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       402:
 *         description: Payment processing failed
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       422:
 *         description: Restaurant not available or menu item not available
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
router.post('/orders', async (req: Request, res: Response, next: NextFunction) => {
  // Extract Idempotency-Key header
  const idempotencyKey = req.headers['idempotency-key'] as string | undefined;

  if (!idempotencyKey) {
    res.status(400).json({ error: 'Idempotency-Key header is required' });
    return;
  }

  // Validate idempotency key is a valid UUID
  if (!uuidValidate(idempotencyKey)) {
    res.status(400).json({ error: 'Idempotency-Key must be a valid UUID' });
    return;
  }

  // Validate body
  const body = req.body as Partial<CreateOrderBody>;
  const errors: string[] = [];

  if (!body.restaurantId || typeof body.restaurantId !== 'string') {
    errors.push('restaurantId is required and must be a string');
  } else if (!uuidValidate(body.restaurantId)) {
    errors.push('restaurantId must be a valid UUID');
  }

  if (!Array.isArray(body.items) || body.items.length === 0) {
    errors.push('items is required and must be a non-empty array');
  } else {
    body.items.forEach((item, index) => {
      if (!item.menuItemId || typeof item.menuItemId !== 'string') {
        errors.push(`items[${index}].menuItemId is required and must be a string`);
      } else if (!uuidValidate(item.menuItemId)) {
        errors.push(`items[${index}].menuItemId must be a valid UUID`);
      }

      if (typeof item.quantity !== 'number' || item.quantity <= 0) {
        errors.push(`items[${index}].quantity is required and must be a positive number`);
      }
    });
  }

  if (errors.length > 0) {
    res.status(400).json({ error: 'Validation failed', details: errors });
    return;
  }

  try {
    const order = await placeOrder(body as CreateOrderBody, idempotencyKey);

    res.status(202).json({
      data: {
        orderId: order.id,
        status: order.status,
      },
    });
  } catch (err) {
    if (err instanceof RestaurantNotAvailableErrorClass) {
      res.status(422).json({ error: err.message });
      return;
    }
    if (err instanceof MenuItemNotAvailableErrorClass) {
      res.status(422).json({ error: err.message });
      return;
    }
    if (err instanceof PaymentFailedErrorClass) {
      res.status(402).json({ error: err.message });
      return;
    }
    next(err);
  }
});

// ── GET /orders/driver/:driverId/active ──────────────────────────────────────

/**
 * @swagger
 * /orders/driver/{driverId}/active:
 *   get:
 *     summary: Get the active PICKED_UP order assigned to a driver
 *     description: >
 *       Used internally by the driver-location-service to associate GPS pings
 *       with the correct order for customer tracking. Returns 404 when the
 *       driver has no order in PICKED_UP status.
 *     tags: [Orders]
 *     parameters:
 *       - in: path
 *         name: driverId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Driver UUID
 *     responses:
 *       200:
 *         description: Active order found
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: object
 *                   properties:
 *                     orderId:
 *                       type: string
 *                       format: uuid
 *       400:
 *         description: Invalid driver UUID format
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: No active order found for this driver
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
  '/orders/driver/:driverId/active',
  async (req: Request, res: Response, next: NextFunction) => {
    const { driverId } = req.params;

    if (!assertUUID(driverId, res)) return;

    try {
      const order = await getActiveOrderForDriver(driverId);

      if (!order) {
        res.status(404).json({ error: `No active order found for driver "${driverId}"` });
        return;
      }

      res.json({ data: { orderId: order.id } });
    } catch (err) {
      next(err);
    }
  },
);

// ── GET /orders/:id ──────────────────────────────────────────────────────────

/**
 * @swagger
 * /orders/{id}:
 *   get:
 *     summary: Get an order by ID
 *     tags: [Orders]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Order UUID
 *     responses:
 *       200:
 *         description: Order details including items
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/Order'
 *       400:
 *         description: Invalid UUID format
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Order not found
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
router.get('/orders/:id', async (req: Request, res: Response, next: NextFunction) => {
  const { id } = req.params;

  if (!assertUUID(id, res)) return;

  try {
    const order = await getOrder(id);

    if (!order) {
      res.status(404).json({ error: `Order "${id}" not found` });
      return;
    }

    res.json({ data: order });
  } catch (err) {
    next(err);
  }
});

// ── PATCH /orders/:id/status ─────────────────────────────────────────────────

/**
 * @swagger
 * /orders/{id}/status:
 *   patch:
 *     summary: Update the status of an order
 *     tags: [Orders]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Order UUID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdateOrderStatusBody'
 *     responses:
 *       200:
 *         description: Order status updated
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/Order'
 *       400:
 *         description: Invalid UUID, invalid status value, or invalid status transition
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       404:
 *         description: Order not found
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
router.patch(
  '/orders/:id/status',
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;

    if (!assertUUID(id, res)) return;

    const body = req.body as { status?: string };

    if (!body.status || typeof body.status !== 'string') {
      res.status(400).json({ error: 'status is required and must be a string' });
      return;
    }

    // Validate status is a valid OrderStatus
    const validStatuses = Object.values(OrderStatus);
    if (!validStatuses.includes(body.status as OrderStatus)) {
      res.status(400).json({
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
      return;
    }

    try {
      const order = await updateOrderStatus(id, body.status as OrderStatus);

      if (!order) {
        res.status(404).json({ error: `Order "${id}" not found` });
        return;
      }

      res.json({ data: order });
    } catch (err) {
      if (err instanceof InvalidStatusTransitionErrorClass) {
        res.status(400).json({ error: err.message });
        return;
      }
      next(err);
    }
  },
);

export default router;
