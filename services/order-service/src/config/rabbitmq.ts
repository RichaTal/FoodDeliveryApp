import * as amqp from 'amqplib';
import dotenv from 'dotenv';

dotenv.config();

const RABBITMQ_URL = process.env['RABBITMQ_URL'] || 'amqp://admin:admin123@localhost:5672';
const MAX_RETRIES = 5;

let connection: Awaited<ReturnType<typeof amqp.connect>> | null = null;
let channel: amqp.Channel | null = null;
let isConnecting = false;
let connectionPromise: Promise<void> | null = null;

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function resetConnectionState(): void {
  channel = null;
  connection = null;
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
      resetConnectionState();
    });

    connection.on('close', () => {
      console.warn('[RabbitMQ] Connection closed');
      resetConnectionState();
    });

    channel = await connection.createChannel();
    if (!channel) {
      throw new Error('Failed to create RabbitMQ channel');
    }

    channel.on('error', (err: Error) => {
      console.error('[RabbitMQ] Channel error:', err.message);
      channel = null;
    });

    channel.on('close', () => {
      console.warn('[RabbitMQ] Channel closed');
      channel = null;
    });

    // Assert exchange (idempotent - safe to call multiple times)
    await channel.assertExchange('order.events', 'fanout', {
      durable: true,
    });

    console.info('[RabbitMQ] Connected and exchange asserted');
  } catch (err) {
    const error = err as Error;
    console.error(`[RabbitMQ] Connection failed: ${error.message}`);
    resetConnectionState();

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

async function ensureConnection(): Promise<void> {
  if (!channel || !connection) {
    // Prevent multiple concurrent connection attempts
    if (isConnecting && connectionPromise) {
      await connectionPromise;
      return;
    }

    isConnecting = true;
    connectionPromise = connectWithRetry();
    try {
      await connectionPromise;
    } finally {
      isConnecting = false;
      connectionPromise = null;
    }
  }
}

export async function getChannel(): Promise<amqp.Channel> {
  await ensureConnection();
  if (!channel) {
    throw new Error('RabbitMQ channel not available');
  }
  return channel;
}

export async function initializeRabbitMQ(): Promise<void> {
  await ensureConnection();
}

export async function closeConnection(): Promise<void> {
  try {
    if (channel) {
      await channel.close();
      channel = null;
    }
  } catch (err) {
    const error = err as Error;
    console.error('[RabbitMQ] Error closing channel:', error.message);
  }

  try {
    if (connection) {
      await connection.close();
      connection = null;
    }
  } catch (err) {
    const error = err as Error;
    console.error('[RabbitMQ] Error closing connection:', error.message);
  }
}
