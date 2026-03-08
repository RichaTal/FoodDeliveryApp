import * as amqp from 'amqplib';
import dotenv from 'dotenv';

dotenv.config();

const RABBITMQ_URL = process.env['RABBITMQ_URL'] || 'amqp://admin:admin123@localhost:5672';
const MAX_RETRIES = 5;

let connection: Awaited<ReturnType<typeof amqp.connect>> | null = null;
let channel: amqp.Channel | null = null;

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectWithRetry(retryCount = 0): Promise<void> {
  try {
    console.info(`[RabbitMQ] Connecting to ${RABBITMQ_URL}...`);
    connection = await amqp.connect(RABBITMQ_URL);
    if (!connection) {
      throw new Error('Failed to establish RabbitMQ connection');
    }

    connection.on('error', (err: Error) => {
      console.error('[RabbitMQ] Connection error:', err.message);
      channel = null;
    });

    connection.on('close', () => {
      console.warn('[RabbitMQ] Connection closed');
      channel = null;
    });

    channel = await connection.createChannel();
    if (!channel) {
      throw new Error('Failed to create RabbitMQ channel');
    }

    // Set prefetch to process at most 10 messages at once
    await channel.prefetch(10);

    // Assert exchange (idempotent - safe to call multiple times)
    // Only order.events remains on RabbitMQ; driver location events moved to Kafka
    await channel.assertExchange('order.events', 'fanout', {
      durable: true,
    });

    // Assert queue (idempotent - already exists from definitions.json)
    await channel.assertQueue('orders.notification', {
      durable: true,
    });

    // Bind queue to exchange
    await channel.bindQueue('orders.notification', 'order.events', '');

    console.info('[RabbitMQ] Connected, order exchange and queue asserted');
  } catch (err) {
    const error = err as Error;
    console.error(`[RabbitMQ] Connection failed: ${error.message}`);

    if (retryCount < MAX_RETRIES) {
      const delay = Math.min(Math.pow(2, retryCount) * 1000, 10_000); // exponential back-off, max 10s
      console.warn(`[RabbitMQ] Retrying in ${delay}ms... (attempt ${retryCount + 1}/${MAX_RETRIES})`);
      await sleep(delay);
      return connectWithRetry(retryCount + 1);
    } else {
      console.error('[RabbitMQ] Max retries reached. Exiting.');
      process.exit(1);
    }
  }
}

export async function getChannel(): Promise<amqp.Channel> {
  if (!channel || !connection) {
    await connectWithRetry();
  }
  if (!channel) {
    throw new Error('RabbitMQ channel not available');
  }
  return channel;
}

export async function initializeRabbitMQ(): Promise<void> {
  await connectWithRetry();
}

export async function closeConnection(): Promise<void> {
  if (channel) {
    await channel.close();
    channel = null;
  }
  if (connection) {
    await connection.close();
    connection = null;
  }
}
