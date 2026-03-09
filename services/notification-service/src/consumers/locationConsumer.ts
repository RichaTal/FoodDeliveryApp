import { createConsumer } from '../config/kafka.js';
import { sendToCustomer } from '../websocket/customerSocket.js';
import { LocationEvent, WebSocketMessage } from '../types/index.js';

const TOPIC = 'driver-location-events';
const GROUP_ID = 'notification-location-consumer';

/**
 * Start consuming driver location events from Kafka
 * Performance note: This topic receives up to 2,000 messages/sec.
 * Handler must be fast — no blocking I/O beyond WebSocket send.
 */
export async function startLocationConsumer(): Promise<void> {
  try {
    const consumer = createConsumer(GROUP_ID);

    await consumer.connect();
    await consumer.subscribe({ topic: TOPIC, fromBeginning: false });

    await consumer.run({
      eachMessage: async ({ message }) => {
        try {
          if (!message.value) return;

          const locationEvent: LocationEvent = JSON.parse(message.value.toString());

          const wsMessage: WebSocketMessage = {
            type: 'DRIVER_LOCATION',
            payload: locationEvent,
          };

          const sent = sendToCustomer(locationEvent.orderId, wsMessage);
          if (!sent) {
            console.debug(
              `[LocationConsumer] Customer not connected for orderId: ${locationEvent.orderId}`,
            );
          }
        } catch (error) {
          const err = error as Error;
          console.error(`[LocationConsumer] Error processing message:`, err);
        }
      },
    });

    console.info(`[LocationConsumer] Started consuming from Kafka topic: ${TOPIC}`);
  } catch (error) {
    const err = error as Error;
    console.error(`[LocationConsumer] Failed to start consumer:`, err);
    throw err;
  }
}
