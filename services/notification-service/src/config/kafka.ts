import { Kafka, Consumer, logLevel } from 'kafkajs';
import dotenv from 'dotenv';

dotenv.config();

const KAFKA_BROKERS = (process.env['KAFKA_BROKERS'] || 'localhost:9092').split(',');
const KAFKA_CLIENT_ID = process.env['KAFKA_CLIENT_ID'] || 'notification-service';

const kafka = new Kafka({
  clientId: KAFKA_CLIENT_ID,
  brokers: KAFKA_BROKERS,
  logLevel: logLevel.WARN,
  retry: {
    initialRetryTime: 1000,
    retries: 5,
  },
});

/**
 * Create a Kafka consumer for a given consumer group
 * Each consumer group independently tracks offsets
 */
export function createConsumer(groupId: string): Consumer {
  return kafka.consumer({
    groupId,
    sessionTimeout: 30000,
    heartbeatInterval: 10000,
  });
}
