import { Kafka, Producer, logLevel } from 'kafkajs';
import dotenv from 'dotenv';

dotenv.config();

const KAFKA_BROKERS = (process.env['KAFKA_BROKERS'] || 'localhost:9092').split(',');
const KAFKA_CLIENT_ID = process.env['KAFKA_CLIENT_ID'] || 'driver-location-service';

const kafka = new Kafka({
  clientId: KAFKA_CLIENT_ID,
  brokers: KAFKA_BROKERS,
  logLevel: logLevel.WARN,
  retry: {
    initialRetryTime: 1000,
    retries: 5,
  },
});

let producer: Producer | null = null;

/**
 * Initialize Kafka producer connection
 */
export async function initializeKafka(): Promise<void> {
  producer = kafka.producer({
    allowAutoTopicCreation: false,
  });
  await producer.connect();
  console.info('[Kafka] Producer connected');
}

/**
 * Get the Kafka producer instance, initializing if needed
 */
export async function getProducer(): Promise<Producer> {
  if (!producer) {
    await initializeKafka();
  }
  return producer!;
}

/**
 * Disconnect Kafka producer gracefully
 */
export async function disconnectKafka(): Promise<void> {
  if (producer) {
    await producer.disconnect();
    producer = null;
    console.info('[Kafka] Producer disconnected');
  }
}
