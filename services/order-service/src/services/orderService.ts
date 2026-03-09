import { v4 as uuidv4 } from 'uuid';
import { query, getClient } from '../config/db.js';
import redisClient from '../config/redis.js';
import { processPayment } from './paymentStub.js';
import { publishOrderPlaced, publishOrderStatusUpdated } from './publisher.js';
import { getRestaurantMenu, extractMenuItems } from './restaurantClient.js';
import type {
  CreateOrderBody,
  Order,
  OrderItem,
  MenuItem,
} from '../types/index.js';
import {
  OrderStatus,
  PaymentStatus,
  RestaurantNotAvailableError as RestaurantNotAvailableErrorClass,
  MenuItemNotAvailableError as MenuItemNotAvailableErrorClass,
  PaymentFailedError as PaymentFailedErrorClass,
  InvalidStatusTransitionError as InvalidStatusTransitionErrorClass,
} from '../types/index.js';
 
// Valid status transitions
const VALID_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.PREPARING]: [OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  [OrderStatus.PICKED_UP]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
  [OrderStatus.DELIVERED]: [], // No transitions from DELIVERED
  [OrderStatus.CANCELLED]: [], // No transitions from CANCELLED
};

function isValidTransition(currentStatus: OrderStatus, newStatus: OrderStatus): boolean {
  // Any status can transition to CANCELLED (except DELIVERED)
  if (newStatus === OrderStatus.CANCELLED && currentStatus !== OrderStatus.DELIVERED) {
    return true;
  }

  const allowed = VALID_TRANSITIONS[currentStatus];
  return allowed.includes(newStatus);
}

export async function placeOrder(
  body: CreateOrderBody,
  idempotencyKey: string,
): Promise<Order> {
  // 1. Idempotency check
  const idempotencyRedisKey = `idempotency:${idempotencyKey}`;
  const existingOrderId = await redisClient.get(idempotencyRedisKey);

  if (existingOrderId) {
    console.info(`[OrderService] Idempotency key found, returning existing order: ${existingOrderId}`);
    const existingOrder = await getOrder(existingOrderId);
    if (existingOrder) {
      return existingOrder;
    }
    // If order not found but key exists, continue processing (stale key)
  }

  // 2. Validate restaurant exists and is open (via restaurant-service API)
  const menu = await getRestaurantMenu(body.restaurantId);

  if (!menu) {
    throw new RestaurantNotAvailableErrorClass(`Restaurant ${body.restaurantId} not found`);
  }

  if (!menu.restaurant.is_open) {
    throw new RestaurantNotAvailableErrorClass(`Restaurant ${body.restaurantId} is closed`);
  }

  // 3. Validate menu items (extract from menu response)
  const allMenuItems = extractMenuItems(menu);
  const menuItemsMap = new Map<string, MenuItem>();
  for (const item of allMenuItems) {
    menuItemsMap.set(item.id, item);
  }

  // Validate each requested item
  for (const requestedItem of body.items) {
    const menuItem = menuItemsMap.get(requestedItem.menuItemId);

    if (!menuItem) {
      throw new MenuItemNotAvailableErrorClass(
        `Menu item ${requestedItem.menuItemId} not found`,
      );
    }

    // Verify menu item belongs to the restaurant (application-level referential integrity)
    if (menuItem.restaurant_id !== body.restaurantId) {
      throw new MenuItemNotAvailableErrorClass(
        `Menu item ${requestedItem.menuItemId} does not belong to restaurant ${body.restaurantId}`,
      );
    }

    if (!menuItem.is_available) {
      throw new MenuItemNotAvailableErrorClass(
        `Menu item ${requestedItem.menuItemId} is not available`,
      );
    }

    if (requestedItem.quantity <= 0) {
      throw new MenuItemNotAvailableErrorClass(
        `Invalid quantity for menu item ${requestedItem.menuItemId}`,
      );
    }
  }

  // 4. Calculate total
  let totalAmount = 0;
  for (const requestedItem of body.items) {
    const menuItem = menuItemsMap.get(requestedItem.menuItemId)!;
    totalAmount += menuItem.price * requestedItem.quantity;
  }

  // 5. Generate order ID
  const orderId = uuidv4();

  // 6. Mock payment
  const paymentResult = await processPayment(totalAmount, orderId);
  if (!paymentResult.success) {
    throw new PaymentFailedErrorClass(`Payment failed for order ${orderId}`);
  }

  // 7. ACID transaction - create order and order items
  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Insert order
    await client.query(
      `INSERT INTO orders (id, restaurant_id, status, total_amount, payment_status, payment_txn_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        orderId,
        body.restaurantId,
        OrderStatus.PENDING,
        totalAmount,
        PaymentStatus.SUCCESS,
        paymentResult.transactionId,
      ],
    );

    // Insert order items
    for (const requestedItem of body.items) {
      const menuItem = menuItemsMap.get(requestedItem.menuItemId)!;
      await client.query(
        `INSERT INTO order_items (order_id, menu_item_id, name, price_at_time, quantity)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          orderId,
          requestedItem.menuItemId,
          menuItem.name,
          menuItem.price,
          requestedItem.quantity,
        ],
      );
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  // 8. Store idempotency key
  await redisClient.setex(idempotencyRedisKey, 86400, orderId); // 24h TTL

  // 9. Fetch complete order with items
  const order = await getOrder(orderId);
  if (!order) {
    throw new Error(`Failed to retrieve created order ${orderId}`);
  }

  // 10. Publish event
  await publishOrderPlaced(order);

  return order;
}

/**
 * Get the active (PICKED_UP) order assigned to a driver
 * Returns { id } of the order, or null if no active order found
 */
export async function getActiveOrderForDriver(driverId: string): Promise<{ id: string } | null> {
  const result = await query<{ id: string }>(
    `SELECT id FROM orders
     WHERE driver_id = $1
       AND status = 'PICKED_UP'
     ORDER BY updated_at DESC
     LIMIT 1`,
    [driverId],
  );
  return result.rows.length > 0 ? result.rows[0] : null;
}

export async function getOrder(orderId: string): Promise<Order | null> {
  const orderResult = await query<Order>(
    `SELECT id, restaurant_id, driver_id, status, total_amount, 
            payment_status, payment_txn_id, created_at, updated_at
     FROM orders
     WHERE id = $1`,
    [orderId],
  );

  if (orderResult.rows.length === 0) {
    return null;
  }

  const order = orderResult.rows[0];

  // Fetch order items
  const itemsResult = await query<OrderItem>(
    `SELECT id, order_id, menu_item_id, name, price_at_time, quantity
     FROM order_items
     WHERE order_id = $1`,
    [orderId],
  );

  return {
    ...order,
    items: itemsResult.rows,
  };
}

export async function updateOrderStatus(
  orderId: string,
  newStatus: OrderStatus,
): Promise<Order | null> {
  // Get current order
  const currentOrder = await getOrder(orderId);
  if (!currentOrder) {
    return null;
  }

  // Validate status transition
  if (!isValidTransition(currentOrder.status as OrderStatus, newStatus)) {
    throw new InvalidStatusTransitionErrorClass(
      `Invalid status transition from ${currentOrder.status} to ${newStatus}`,
    );
  }

  // Update order status
  await query(
    `UPDATE orders 
     SET status = $1, updated_at = NOW() 
     WHERE id = $2`,
    [newStatus, orderId],
  );

  // Publish event
  await publishOrderStatusUpdated(orderId, newStatus);

  // Return updated order
  return await getOrder(orderId);
}
