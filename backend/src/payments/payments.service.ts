import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import Stripe from 'stripe';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';

const VAT_RATE = 0.05;

/**
 * Payment provider is pluggable: with STRIPE_SECRET_KEY configured, this
 * creates real Stripe PaymentIntents and relies on the webhook (see
 * handleStripeWebhook) to move a payment from pending -> captured/failed —
 * never assumed captured just because the intent was created. Without a key
 * (dev/sandbox), payments are simulated: card/wallet methods auto-capture,
 * pay_at_service stays pending until the partner confirms collection.
 */
@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private readonly stripe: Stripe | null;

  constructor(private readonly prisma: PrismaService) {
    const key = process.env.STRIPE_SECRET_KEY;
    this.stripe = key ? new Stripe(key) : null;
  }

  async createIntent(customerId: string, dto: CreatePaymentIntentDto) {
    const vatAmount = Math.round(dto.amount * VAT_RATE * 100) / 100;
    const isOnlineMethod = dto.paymentMethod !== 'pay_at_service';

    let providerReference: string | undefined;
    let clientSecret: string | undefined;
    let status: 'pending' | 'captured' = dto.paymentMethod === 'pay_at_service' ? 'pending' : 'captured';

    if (this.stripe && isOnlineMethod) {
      const intent = await this.stripe.paymentIntents.create({
        amount: Math.round(dto.amount * 100),
        currency: 'aed',
        payment_method_types: dto.paymentMethod === 'card' ? ['card'] : [dto.paymentMethod],
        metadata: {
          relatedEntityType: dto.relatedEntityType,
          relatedEntityId: dto.relatedEntityId,
          customerId,
        },
      });
      providerReference = intent.id;
      clientSecret = intent.client_secret ?? undefined;
      // Real charge status is only known once Stripe calls our webhook —
      // never optimistically mark a real intent as captured here.
      status = 'pending';
    }

    const payment = await this.prisma.payment.create({
      data: {
        relatedEntityType: dto.relatedEntityType,
        relatedEntityId: dto.relatedEntityId,
        customerId,
        amount: dto.amount,
        vatAmount,
        paymentMethod: dto.paymentMethod,
        provider: this.stripe ? 'stripe' : 'none',
        providerReference,
        status,
      },
    });

    return { ...payment, clientSecret };
  }

  async findOne(id: string) {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    if (!payment) throw new NotFoundException({ code: 'PAYMENT_NOT_FOUND', message: 'Payment not found.' });
    return payment;
  }

  /** Manual confirmation path — only meaningful for pay_at_service (partner confirms cash collected) or simulated (no Stripe key) payments. Real Stripe card payments are confirmed via the webhook instead. */
  async confirm(id: string) {
    return this.prisma.payment.update({ where: { id }, data: { status: 'captured' } });
  }

  async refund(id: string) {
    const payment = await this.findOne(id);
    if (this.stripe && payment.providerReference) {
      await this.stripe.refunds.create({ payment_intent: payment.providerReference });
    }
    return this.prisma.payment.update({ where: { id }, data: { status: 'refunded' } });
  }

  listAll(status?: string) {
    return this.prisma.payment.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  async revenueSummary() {
    const [captured, refunded, pending, failed] = await Promise.all([
      this.prisma.payment.aggregate({ where: { status: 'captured' }, _sum: { amount: true, vatAmount: true }, _count: true }),
      this.prisma.payment.aggregate({ where: { status: 'refunded' }, _sum: { amount: true }, _count: true }),
      this.prisma.payment.aggregate({ where: { status: 'pending' }, _sum: { amount: true }, _count: true }),
      this.prisma.payment.aggregate({ where: { status: 'failed' }, _sum: { amount: true }, _count: true }),
    ]);
    return {
      captured: { total: captured._sum.amount ?? 0, vat: captured._sum.vatAmount ?? 0, count: captured._count },
      refunded: { total: refunded._sum.amount ?? 0, count: refunded._count },
      pending: { total: pending._sum.amount ?? 0, count: pending._count },
      failed: { total: failed._sum.amount ?? 0, count: failed._count },
      netRevenue: (captured._sum.amount ?? 0) - (refunded._sum.amount ?? 0),
    };
  }

  /** Verifies and applies a Stripe webhook event. Returns quietly (no-op) if Stripe isn't configured — lets the caller always respond 200 either way. */
  async handleStripeWebhook(rawBody: Buffer, signature: string | undefined) {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!this.stripe || !webhookSecret || !signature) {
      this.logger.warn('Received a Stripe webhook call but Stripe is not fully configured — ignoring.');
      return;
    }

    const event = this.stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);

    if (event.type === 'payment_intent.succeeded') {
      const intent = event.data.object as Stripe.PaymentIntent;
      await this.prisma.payment.updateMany({
        where: { providerReference: intent.id },
        data: { status: 'captured' },
      });
    } else if (event.type === 'payment_intent.payment_failed') {
      const intent = event.data.object as Stripe.PaymentIntent;
      await this.prisma.payment.updateMany({
        where: { providerReference: intent.id },
        data: { status: 'failed' },
      });
    }
  }
}
