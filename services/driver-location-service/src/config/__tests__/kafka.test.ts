// Mock kafkajs before importing
const mockProducerConnect = jest.fn().mockResolvedValue(undefined);
const mockProducerDisconnect = jest.fn().mockResolvedValue(undefined);
const mockProducerSend = jest.fn().mockResolvedValue(undefined);

const mockProducer = {
  connect: mockProducerConnect,
  disconnect: mockProducerDisconnect,
  send: mockProducerSend,
};

const mockKafkaProducer = jest.fn().mockReturnValue(mockProducer);

jest.mock('kafkajs', () => ({
  Kafka: jest.fn().mockImplementation(() => ({
    producer: mockKafkaProducer,
  })),
  logLevel: { WARN: 4 },
}));

import { initializeKafka, getProducer, disconnectKafka } from '../kafka.js';

describe('Kafka Config', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('initializeKafka', () => {
    it('should create and connect a Kafka producer', async () => {
      // Reset module state
      await disconnectKafka();

      await initializeKafka();

      expect(mockKafkaProducer).toHaveBeenCalledWith({
        allowAutoTopicCreation: false,
      });
      expect(mockProducerConnect).toHaveBeenCalled();
    });
  });

  describe('getProducer', () => {
    it('should return existing producer if available', async () => {
      await initializeKafka();
      const producer = await getProducer();

      expect(producer).toBe(mockProducer);
    });

    it('should initialize producer if not available', async () => {
      await disconnectKafka();
      mockProducerConnect.mockClear();

      const producer = await getProducer();

      expect(producer).toBeDefined();
      expect(mockProducerConnect).toHaveBeenCalled();
    });
  });

  describe('disconnectKafka', () => {
    it('should disconnect producer', async () => {
      await initializeKafka();
      await disconnectKafka();

      expect(mockProducerDisconnect).toHaveBeenCalled();
    });

    it('should handle disconnect when no producer exists', async () => {
      await disconnectKafka();
      await disconnectKafka(); // Second call should not throw

      // Should not throw
      expect(true).toBe(true);
    });
  });
});
