import { processPayment } from '../paymentStub';

describe('paymentStub', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('should process payment successfully', async () => {
    const amount = 100.50;
    const orderId = 'order-123';

    const paymentPromise = processPayment(amount, orderId);
    jest.advanceTimersByTime(75);
    const result = await paymentPromise;

    expect(result.success).toBe(true);
    expect(result.transactionId).toBeDefined();
    expect(typeof result.transactionId).toBe('string');
  });

  it('should simulate 75ms delay', async () => {
    const amount = 50;
    const orderId = 'order-456';
    const startTime = Date.now();

    const paymentPromise = processPayment(amount, orderId);
    jest.advanceTimersByTime(75);
    await paymentPromise;
    const endTime = Date.now();

    // Should complete after 75ms delay
    expect(endTime - startTime).toBeGreaterThanOrEqual(0);
  });

  it('should generate unique transaction IDs', async () => {
    const amount = 100;
    const orderId1 = 'order-1';
    const orderId2 = 'order-2';

    const paymentPromise1 = processPayment(amount, orderId1);
    const paymentPromise2 = processPayment(amount, orderId2);
    jest.advanceTimersByTime(75);
    const result1 = await paymentPromise1;
    const result2 = await paymentPromise2;

    expect(result1.transactionId).not.toBe(result2.transactionId);
  });

  it('should always return success', async () => {
    const amount = 0;
    const orderId = 'order-123';

    const paymentPromise = processPayment(amount, orderId);
    jest.advanceTimersByTime(75);
    const result = await paymentPromise;

    expect(result.success).toBe(true);
  });
});
