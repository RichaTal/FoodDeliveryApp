import { ConsumeMessage } from 'amqplib';
import { getChannel } from '../config/rabbitmq.js';
import { sendToCustomer } from '../websocket/customerSocket.js';
import { OrderEvent, WebSocketMessage } from '../types/index.js';

const QUEUE_NAME = 'orders.notification';

/**
 * Start consuming order events from RabbitMQ
 */
export async function startOrderConsumer(): Promise<void> {
  try {
    const channel = await getChannel();

    await channel.consume(
      QUEUE_NAME,
      async (msg: ConsumeMessage | null) => {
        if (!msg) {
          return;
        }

        try {
          // Parse message content as OrderEvent
          const content = msg.content.toString();
          const orderEvent: OrderEvent = JSON.parse(content);

          console.info(`[OrderConsumer] Received order event: ${orderEvent.orderId} - ${orderEvent.status}`);

          // Construct WebSocket message
          const wsMessage: WebSocketMessage = {
            type: 'ORDER_UPDATE',
            payload: orderEvent,
          };

          // Send to customer WebSocket
          const sent = sendToCustomer(orderEvent.orderId, wsMessage);

          if (!sent) {
            // Customer not on this instance or disconnected - log at DEBUG level
            console.debug(`[OrderConsumer] Customer not connected for orderId: ${orderEvent.orderId}`);
          }

          // Acknowledge message after successful processing
          channel.ack(msg);
        } catch (error) {
          const err = error as Error;
          console.log(`[OrderConsumer] Error processing message:`, err);

          // Parse error or unexpected payload - dead-letter, do not requeue
          channel.nack(msg, false, false);
        }
      },
      { noAck: false }
    );

    console.info(`[OrderConsumer] Started consuming from queue: ${QUEUE_NAME}`);
  } catch (error) {
    const err = error as Error;
    console.log(`[OrderConsumer] Failed to start consumer:`, err);
    throw err;
  }
}
