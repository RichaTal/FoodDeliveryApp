import { v4 as uuidv4 } from 'uuid';
import type { PaymentResult } from '../types/index.js';

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function processPayment(
  amount: number,
  orderId: string,
): Promise<PaymentResult> {
  // Simulate network latency
  await sleep(75);

  const transactionId = uuidv4();

  console.info(`[PaymentStub] Processing payment for order ${orderId}: amount=$${amount.toFixed(2)}, transactionId=${transactionId}`);

  // Always return success (this is a stub)
  return {
    success: true,
    transactionId,
  };
}
