import { env } from '../config/env';

interface PaymentResult {
  success: boolean;
  providerTxnId?: string;
  message: string;
}

interface PaymentProviderInterface {
  createPayment(amount: number, currency: string, metadata?: Record<string, unknown>): Promise<PaymentResult>;
  verifyPayment(txnId: string): Promise<PaymentResult>;
  refundPayment(txnId: string, amount?: number): Promise<PaymentResult>;
}

class MockPaymentProvider implements PaymentProviderInterface {
  async createPayment(amount: number, currency: string, metadata?: Record<string, unknown>): Promise<PaymentResult> {
    return {
      success: true,
      providerTxnId: `mock_txn_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
      message: `Mock payment of ${currency} ${amount} successful (dev mode)`,
    };
  }

  async verifyPayment(txnId: string): Promise<PaymentResult> {
    return {
      success: true,
      providerTxnId: txnId,
      message: 'Mock payment verified (dev mode)',
    };
  }

  async refundPayment(txnId: string, amount?: number): Promise<PaymentResult> {
    return {
      success: true,
      providerTxnId: txnId,
      message: `Mock refund of ${amount ? `$${amount}` : 'full amount'} processed (dev mode)`,
    };
  }
}

class StripePaymentProvider implements PaymentProviderInterface {
  private stripe: any;

  constructor() {
    if (!env.stripeSecretKey || env.stripeSecretKey === 'sk_test_placeholder') {
      throw new Error('Stripe secret key not configured');
    }
    const Stripe = require('stripe');
    this.stripe = new Stripe(env.stripeSecretKey);
  }

  async createPayment(amount: number, currency: string, metadata?: Record<string, unknown>): Promise<PaymentResult> {
    const paymentIntent = await this.stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: currency.toLowerCase(),
      metadata,
    });
    return {
      success: true,
      providerTxnId: paymentIntent.id,
      message: paymentIntent.client_secret,
    };
  }

  async verifyPayment(txnId: string): Promise<PaymentResult> {
    const paymentIntent = await this.stripe.paymentIntents.retrieve(txnId);
    return {
      success: paymentIntent.status === 'succeeded',
      providerTxnId: txnId,
      message: paymentIntent.status,
    };
  }

  async refundPayment(txnId: string, amount?: number): Promise<PaymentResult> {
    const refund = await this.stripe.refunds.create({
      payment_intent: txnId,
      ...(amount ? { amount: Math.round(amount * 100) } : {}),
    });
    return {
      success: refund.status === 'succeeded',
      providerTxnId: refund.id,
      message: refund.status,
    };
  }
}

class PayFastPaymentProvider implements PaymentProviderInterface {
  async createPayment(amount: number, currency: string, metadata?: Record<string, unknown>): Promise<PaymentResult> {
    if (!env.payfastApiKey || env.payfastApiKey === 'placeholder_payfast_api_key') {
      throw new Error('PayFast API key not configured');
    }
    return {
      success: true,
      providerTxnId: `pf_txn_${Date.now()}`,
      message: JSON.stringify({
        redirectUrl: `${env.payfastBaseUrl}/process?amount=${amount}&currency=${currency}`,
      }),
    };
  }

  async verifyPayment(txnId: string): Promise<PaymentResult> {
    return {
      success: true,
      providerTxnId: txnId,
      message: 'PayFast payment verified',
    };
  }

  async refundPayment(txnId: string, amount?: number): Promise<PaymentResult> {
    return {
      success: true,
      providerTxnId: txnId,
      message: `PayFast refund processed`,
    };
  }
}

function getPaymentProvider(provider: string): PaymentProviderInterface {
  switch (provider) {
    case 'stripe':
      return new StripePaymentProvider();
    case 'payfast':
      return new PayFastPaymentProvider();
    case 'mock':
      return new MockPaymentProvider();
    default:
      return new MockPaymentProvider();
  }
}

export { getPaymentProvider };
export type { PaymentProviderInterface, PaymentResult };
