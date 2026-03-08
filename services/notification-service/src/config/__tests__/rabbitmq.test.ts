// Mock amqplib before importing
const mockConnect = jest.fn();
jest.mock('amqplib', () => ({
  connect: mockConnect,
}));

import { getChannel, initializeRabbitMQ, closeConnection } from '../rabbitmq.js';

describe('RabbitMQ Config', () => {
  const originalEnv = process.env;
  let mockConnection: any;
  let mockChannel: any;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.resetModules();
    process.env = { ...originalEnv };

    mockChannel = {
      prefetch: jest.fn().mockResolvedValue(undefined),
      assertExchange: jest.fn().mockResolvedValue(undefined),
      assertQueue: jest.fn().mockResolvedValue(undefined),
      bindQueue: jest.fn().mockResolvedValue(undefined),
      close: jest.fn().mockResolvedValue(undefined),
      on: jest.fn(),
    };

    mockConnection = {
      createChannel: jest.fn().mockResolvedValue(mockChannel),
      close: jest.fn().mockResolvedValue(undefined),
      on: jest.fn(),
    };

    mockConnect.mockResolvedValue(mockConnection);
  });

  afterEach(() => {
    process.env = originalEnv;
    jest.useRealTimers();
  });

  describe('connectWithRetry', () => {
    it('should connect to RabbitMQ with default URL', async () => {
      delete process.env['RABBITMQ_URL'];
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockConnect).toHaveBeenCalledWith(
        'amqp://admin:admin123@localhost:5672',
      );
    });

    it('should connect to RabbitMQ with custom URL from env', async () => {
      process.env['RABBITMQ_URL'] = 'amqp://user:pass@host:5672';
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockConnect).toHaveBeenCalledWith('amqp://user:pass@host:5672');
    });

    it('should create channel and set prefetch', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockConnection.createChannel).toHaveBeenCalled();
      expect(mockChannel.prefetch).toHaveBeenCalledWith(10);
    });

    it('should assert order.events exchange only', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockChannel.assertExchange).toHaveBeenCalledWith('order.events', 'fanout', {
        durable: true,
      });
      // driver.events should NOT be asserted (moved to Kafka)
      expect(mockChannel.assertExchange).not.toHaveBeenCalledWith('driver.events', 'direct', {
        durable: true,
      });
    });

    it('should assert orders.notification queue only', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockChannel.assertQueue).toHaveBeenCalledWith('orders.notification', {
        durable: true,
      });
      // driver.location.notification should NOT be asserted (moved to Kafka)
      expect(mockChannel.assertQueue).not.toHaveBeenCalledWith('driver.location.notification', {
        durable: true,
      });
    });

    it('should bind orders.notification queue only', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockChannel.bindQueue).toHaveBeenCalledWith(
        'orders.notification',
        'order.events',
        '',
      );
      // driver.location.notification binding should NOT exist (moved to Kafka)
      expect(mockChannel.bindQueue).not.toHaveBeenCalledWith(
        'driver.location.notification',
        'driver.events',
        'driver.location.updated',
      );
    });

    it('should register connection error handler', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockConnection.on).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('should register connection close handler', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockConnection.on).toHaveBeenCalledWith('close', expect.any(Function));
    });
  });

  describe('getChannel', () => {
    it('should return existing channel if available', async () => {
      await initializeRabbitMQ();
      const channel = await getChannel();

      expect(channel).toBe(mockChannel);
      expect(mockConnect).toHaveBeenCalledTimes(1);
    });

    it('should create new connection if channel not available', async () => {
      jest.resetModules();
      const { getChannel: getCh } = require('../rabbitmq.js');

      const channel = await getCh();

      expect(channel).toBeDefined();
      expect(mockConnect).toHaveBeenCalled();
    });
  });

  describe('closeConnection', () => {
    it('should close channel and connection', async () => {
      await initializeRabbitMQ();
      await closeConnection();

      expect(mockChannel.close).toHaveBeenCalled();
      expect(mockConnection.close).toHaveBeenCalled();
    });

    it('should handle missing channel gracefully', async () => {
      await initializeRabbitMQ();
      await closeConnection();
      await closeConnection(); // Second call should not throw

      expect(mockChannel.close).toHaveBeenCalledTimes(1);
    });
  });
});
