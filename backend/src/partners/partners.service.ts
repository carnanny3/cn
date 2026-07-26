import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { hashPassword } from '../common/crypto.util';
import { RegisterPartnerDto } from './dto/register-partner.dto';
import { RegisterPartnerAccountDto } from './dto/register-partner-account.dto';
import { UpdatePartnerProfileDto } from './dto/update-partner-profile.dto';
import { UpdatePartnerServiceDto } from './dto/update-partner-service.dto';
import { AddPartnerServiceDto } from './dto/add-partner-service.dto';
import { SearchPartnersDto } from './dto/search-partners.dto';
import { rankPartners } from './ranking.util';

const COMMISSION_RATE = 0.12; // matches the PRD's worked example (§28.3)

@Injectable()
export class PartnersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authService: AuthService,
  ) {}

  register(dto: RegisterPartnerDto) {
    return this.prisma.partner.create({
      data: {
        businessName: dto.businessName,
        partnerType: dto.partnerType,
        contactPhone: dto.contactPhone,
        contactEmail: dto.contactEmail,
        tradeLicenseUrl: dto.tradeLicenseUrl,
        status: 'pending',
      },
    });
  }

  /** Self-serve signup: creates a login account (role=partner) and the linked business record together, then signs the partner in. */
  async registerAccount(dto: RegisterPartnerAccountDto) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException({
        code: 'EMAIL_ALREADY_REGISTERED',
        message: 'An account with this email already exists. Try logging in instead.',
      });
    }

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        fullName: dto.fullName,
        passwordHash: hashPassword(dto.password),
        status: 'active',
        role: 'partner',
        partnerProfile: {
          create: {
            businessName: dto.businessName,
            partnerType: dto.partnerType,
            contactPhone: dto.contactPhone,
            contactEmail: dto.contactEmail,
            tradeLicenseUrl: dto.tradeLicenseUrl,
            status: 'pending',
          },
        },
      },
    });

    return this.authService.issueTokensForUser(user.id, user.role, user.email);
  }

  /** Resolves the caller's own Partner row from their JWT user id, throwing if this account has no linked partner business. */
  async resolvePartnerId(userId: string): Promise<string> {
    const partner = await this.prisma.partner.findUnique({ where: { userId }, select: { id: true } });
    if (!partner) {
      throw new ForbiddenException({
        code: 'NOT_A_PARTNER_ACCOUNT',
        message: 'This account is not linked to a partner business.',
      });
    }
    return partner.id;
  }

  async findMyProfile(userId: string) {
    const partner = await this.prisma.partner.findUnique({
      where: { userId },
      include: { services: true },
    });
    if (!partner) {
      throw new NotFoundException({
        code: 'NOT_A_PARTNER_ACCOUNT',
        message: 'This account is not linked to a partner business.',
      });
    }
    return partner;
  }

  async updateMyProfile(userId: string, dto: UpdatePartnerProfileDto) {
    const partnerId = await this.resolvePartnerId(userId);
    return this.prisma.partner.update({ where: { id: partnerId }, data: dto });
  }

  async addMyService(userId: string, dto: AddPartnerServiceDto) {
    const partnerId = await this.resolvePartnerId(userId);
    return this.prisma.partnerService.create({
      data: {
        partnerId,
        serviceCategory: dto.serviceCategory,
        price: dto.price,
        durationEstimateMinutes: dto.durationEstimateMinutes,
      },
    });
  }

  async updateMyService(userId: string, serviceId: string, dto: UpdatePartnerServiceDto) {
    const partnerId = await this.resolvePartnerId(userId);
    const service = await this.prisma.partnerService.findUnique({ where: { id: serviceId } });
    if (!service || service.partnerId !== partnerId) {
      throw new ForbiddenException({
        code: 'NOT_YOUR_SERVICE',
        message: 'You do not have access to this service listing.',
      });
    }
    return this.prisma.partnerService.update({ where: { id: serviceId }, data: dto });
  }

  async getMyEarnings(userId: string) {
    const partnerId = await this.resolvePartnerId(userId);
    const completedBookings = await this.prisma.booking.findMany({
      where: { partnerId, status: 'completed' },
      select: { id: true, totalAmount: true, currency: true, scheduledAt: true },
    });

    const grossAmount = completedBookings.reduce((sum, b) => sum + b.totalAmount, 0);
    const commissionAmount = Math.round(grossAmount * COMMISSION_RATE * 100) / 100;
    const netPayout = Math.round((grossAmount - commissionAmount) * 100) / 100;

    return {
      completedJobCount: completedBookings.length,
      grossAmount,
      commissionRate: COMMISSION_RATE,
      commissionAmount,
      netPayout,
      currency: 'AED',
      recentJobs: completedBookings.slice(0, 20),
    };
  }

  async findOne(id: string) {
    const partner = await this.prisma.partner.findUnique({
      where: { id },
      include: { services: true },
    });
    if (!partner) throw new NotFoundException({ code: 'PARTNER_NOT_FOUND', message: 'Partner not found.' });
    return partner;
  }

  addService(partnerId: string, dto: AddPartnerServiceDto) {
    return this.prisma.partnerService.create({
      data: {
        partnerId,
        serviceCategory: dto.serviceCategory,
        price: dto.price,
        durationEstimateMinutes: dto.durationEstimateMinutes,
      },
    });
  }

  async verify(partnerId: string, approve: boolean, rejectionReason?: string) {
    return this.prisma.partner.update({
      where: { id: partnerId },
      data: {
        status: approve ? 'verified' : 'rejected',
        verifiedAt: approve ? new Date() : null,
      },
      // rejectionReason is surfaced via admin audit log, not stored on the
      // partner record itself in this MVP schema.
    }).then((partner) => ({ ...partner, rejectionReason: approve ? undefined : rejectionReason }));
  }

  async search(query: SearchPartnersDto) {
    const services = await this.prisma.partnerService.findMany({
      where: {
        active: true,
        serviceCategory: query.serviceCategory,
        partner: { status: 'verified' },
      },
      include: { partner: true },
    });

    if (services.length === 0) return [];

    const maxPrice = Math.max(...services.map((s) => s.price));
    const rankable = services.map((s) => ({
      id: s.partner.id,
      serviceId: s.id,
      businessName: s.partner.businessName,
      ratingAvg: s.partner.ratingAvg,
      cancellationRate: s.partner.cancellationRate,
      price: s.price,
      durationEstimateMinutes: s.durationEstimateMinutes,
      latitude: s.partner.latitude,
      longitude: s.partner.longitude,
    }));

    return rankPartners(rankable, query.lat ?? null, query.lng ?? null, maxPrice);
  }
}
