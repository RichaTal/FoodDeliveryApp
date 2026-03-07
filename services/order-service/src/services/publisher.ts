import { getChannel } from '../config/rabbitmq.js';
import type { Order, OrderStatus } from '../types/index.js';

export async function publishOrderPlaced(order: Order): Promise<void> {
  try {
    const channel = await getChannel();
    const payload = {
      orderId: order.id,
      restaurantId: order.restaurant_id,
      items: order.items?.map((item) => ({
        menuItemId: item.menu_item_id,
        name: item.name,
        priceAtTime: item.price_at_time,
        quantity: item.quantity,
      })) || [],
      totalAmount: order.total_amount,
      timestamp: new Date().toISOString(),
    };

    channel.publish('order.events', '', Buffer.from(JSON.stringify(payload)), {
      persistent: true,
    });

    console.log(`[Publisher] Published order.placed event for order ${order.id}`);
  } catch (err) {
    const error = err as Error;
    console.error(`[Publisher] Failed to publish order.placed: ${error.message}`);
    throw err;
  }
}

export async function publishOrderStatusUpdated(
  orderId: string,
  status: OrderStatus,
): Promise<void> {
  try {
    const channel = await getChannel();
    const payload = {
      orderId,
      status,
      timestamp: new Date().toISOString(),
    };

    channel.publish('order.events', '', Buffer.from(JSON.stringify(payload)), {
      persistent: true,
    });

    console.info(`[Publisher] Published order.status.updated event for order ${orderId}: ${status}`);
  } catch (err) {
    const error = err as Error;
    console.error(`[Publisher] Failed to publish order.status.updated: ${error.message}`);
    throw err;
  }
}
