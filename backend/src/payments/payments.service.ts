import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';

const VAT_RATE = 0.05;

/**
 * Payment provider is pluggable: if STRIPE_SECRET_KEY is configured, wire a
 * real Stripe PaymentIntent call here. Without it (dev/sandbox), payments are
 * simulated: card/wallet methods auto-capture, pay_at_service stays pending
 * until the partner confirms collection.
 */
@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  async createIntent(customerId: string, dto: CreatePaymentIntentDto) {
    const vatAmount = Math.round(dto.amount * VAT_RATE * 100) / 100;
    const stripeConfigured = Boolean(process.env.STRIPE_SECRET_KEY);

    const payment = await this.prisma.payment.create({
      data: {
        relatedEntityType: dto.relatedEntityType,
        relatedEntityId: dto.relatedEntityId,
        customerId,
        amount: dto.amount,
        vatAmount,
        paymentMethod: dto.paymentMethod,
        provider: stripeConfigured ? 'stripe' : 'none',
        status: dto.paymentMethod === 'pay_at_service' ? 'pending' : 'captured',
      },
    });

    return payment;
  }

  async findOne(id: string) {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    if (!payment) throw new NotFoundException({ code: 'PAYMENT_NOT_FOUND', message: 'Payment not found.' });
    return payment;
  }

  async confirm(id: string) {
    return this.prisma.payment.update({ where: { id }, data: { status: 'captured' } });
  }

  async refund(id: string) {
    return this.prisma.payment.update({ where: { id }, data: { status: 'refunded' } });
  }
}
