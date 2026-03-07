// Mock amqplib before importing
let mockConnect = jest.fn();
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
      assertExchange: jest.fn().mockResolvedValue(undefined),
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

  afterEach(async () => {
    process.env = originalEnv;
    jest.useRealTimers();
    await closeConnection();
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
      process.env['RABBITMQ_URL'] = 'amqp://admin:admin123@host:5672';
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockConnect).toHaveBeenCalledWith('amqp://admin:admin123@host:5672');
    });

    it('should create channel', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockConnection.createChannel).toHaveBeenCalled();
    });

    it('should assert exchange', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockChannel.assertExchange).toHaveBeenCalledWith('order.events', 'fanout', {
        durable: true,
      });
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

    it('should register channel error handler', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockChannel.on).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('should register channel close handler', async () => {
      jest.resetModules();
      const { initializeRabbitMQ: init } = require('../rabbitmq.js');

      await init();

      expect(mockChannel.on).toHaveBeenCalledWith('close', expect.any(Function));
    });
  });

  describe('getChannel', () => {
    it('should return existing channel if available', async () => {
      await initializeRabbitMQ();
      const channel = await getChannel();

      expect(channel).toBe(mockChannel);
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
    it('should handle channel close errors gracefully', async () => {
      mockChannel.close = jest.fn().mockRejectedValue(new Error('Close failed'));

      await initializeRabbitMQ();
      await expect(closeConnection()).resolves.not.toThrow();
    });

    it('should handle connection close errors gracefully', async () => {
      mockConnection.close = jest.fn().mockRejectedValue(new Error('Close failed'));

      await initializeRabbitMQ();
      await expect(closeConnection()).resolves.not.toThrow();
    });
  });
});
