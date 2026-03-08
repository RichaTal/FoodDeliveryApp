import { getProducer } from '../config/kafka.js';
import type { GpsPing } from '../types/index.js';

const TOPIC = 'driver-location-events';

/**
 * Publish location update to Kafka
 * Uses driverId as partition key — all pings from same driver go to same partition
 * preserving chronological order per driver
 */
export async function publishLocationUpdate(ping: GpsPing, orderId?: string): Promise<void> {
  const producer = await getProducer();

  const payload = {
    driverId: ping.driverId,
    lat: ping.lat,
    lng: ping.lng,
    timestamp: ping.timestamp,
    orderId: orderId || undefined,
  };

  await producer.send({
    topic: TOPIC,
    messages: [{
      key: ping.driverId,
      value: JSON.stringify(payload),
    }],
  });
}
