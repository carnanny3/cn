import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateInsuranceProviderDto } from './dto/create-provider.dto';
import { RequestQuoteDto } from './dto/request-quote.dto';
import { RespondQuoteDto } from './dto/respond-quote.dto';
import { PurchaseInsurancePolicyDto } from './dto/purchase-insurance-policy.dto';

function generatePolicyNumber(): string {
  return `IP-${randomBytes(4).toString('hex').toUpperCase()}`;
}

// PRD (§13.13): "MVP: quote requests routed to a manual partner-relationship
// team who return quotes within an SLA (e.g., 2 business hours) [ASSUMPTION]"
const QUOTE_SLA_HOURS = 2;

@Injectable()
export class InsuranceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  createProvider(dto: CreateInsuranceProviderDto) {
    return this.prisma.insuranceProvider.create({ data: { name: dto.name } });
  }

  listProviders() {
    return this.prisma.insuranceProvider.findMany({ where: { active: true } });
  }

  async requestQuote(customerId: string, dto: RequestQuoteDto) {
    const owner = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId: dto.vehicleId, userId: customerId } },
    });
    if (!owner) {
      throw new ForbiddenException({
        code: 'NOT_VEHICLE_OWNER',
        message: 'You can only request insurance for a vehicle in your own garage.',
      });
    }

    const providers = await this.prisma.insuranceProvider.findMany({ where: { active: true } });
    if (providers.length === 0) {
      throw new BadRequestException({
        code: 'NO_PROVIDERS_AVAILABLE',
        message: 'No insurance providers are available right now.',
      });
    }

    const quotes = await this.prisma.$transaction(
      providers.map((provider) =>
        this.prisma.insuranceQuote.create({
          data: {
            vehicleId: dto.vehicleId,
            customerId,
            providerId: provider.id,
            coverageType: dto.coverageType,
          },
        }),
      ),
    );

    await this.notificationsService.notify({
      userId: customerId,
      category: 'insurance_status',
      title: 'Insurance quote requested',
      body: `We've requested quotes from ${providers.length} provider(s). Expect a response within ${QUOTE_SLA_HOURS} business hours.`,
      relatedEntityType: 'insurance_quote',
      relatedEntityId: quotes[0]?.id,
    });

    return quotes;
  }

  getMyQuotes(customerId: string) {
    return this.prisma.insuranceQuote.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
      include: { provider: true, policy: true },
    });
  }

  listAllQuotes(status?: string) {
    return this.prisma.insuranceQuote.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { createdAt: 'desc' },
      include: { provider: true, customer: { select: { fullName: true } } },
    });
  }

  async respondToQuote(quoteId: string, dto: RespondQuoteDto) {
    const quote = await this.prisma.insuranceQuote.findUnique({ where: { id: quoteId } });
    if (!quote) throw new NotFoundException({ code: 'QUOTE_NOT_FOUND', message: 'Quote not found.' });

    const updated = await this.prisma.insuranceQuote.update({
      where: { id: quoteId },
      data: {
        premiumAmount: dto.premiumAmount,
        coverageType: dto.coverageType,
        excessAmount: dto.excessAmount,
        validUntil: new Date(dto.validUntil),
        status: 'quoted',
      },
    });

    await this.notificationsService.notify({
      userId: quote.customerId,
      category: 'insurance_status',
      title: 'Insurance quote ready',
      body: `A quote of AED ${dto.premiumAmount} is ready for your review.`,
      relatedEntityType: 'insurance_quote',
      relatedEntityId: quoteId,
    });

    return updated;
  }

  async purchasePolicy(customerId: string, dto: PurchaseInsurancePolicyDto) {
    const quote = await this.prisma.insuranceQuote.findUnique({ where: { id: dto.quoteId } });
    if (!quote || quote.customerId !== customerId) {
      throw new ForbiddenException({ code: 'NOT_YOUR_QUOTE', message: 'You do not have access to this quote.' });
    }
    if (quote.status !== 'quoted') {
      throw new BadRequestException({ code: 'QUOTE_NOT_READY', message: 'This quote is not ready to purchase yet.' });
    }

    const startDate = new Date();
    const endDate = new Date(startDate.getTime() + 365 * 24 * 60 * 60 * 1000);

    const policy = await this.prisma.insurancePolicy.create({
      data: {
        quoteId: quote.id,
        policyNumber: generatePolicyNumber(),
        startDate,
        endDate,
      },
    });

    await this.notificationsService.notify({
      userId: customerId,
      category: 'insurance_status',
      title: 'Insurance policy purchased',
      body: `Your insurance policy is now active until ${endDate.toLocaleDateString()}.`,
      relatedEntityType: 'insurance_policy',
      relatedEntityId: policy.id,
    });

    return policy;
  }

  getMyPolicies(customerId: string) {
    return this.prisma.insurancePolicy.findMany({
      where: { quote: { customerId } },
      orderBy: { createdAt: 'desc' },
      include: { quote: { include: { provider: true } } },
    });
  }
}
