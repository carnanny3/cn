import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterPartnerDto } from './dto/register-partner.dto';
import { AddPartnerServiceDto } from './dto/add-partner-service.dto';
import { SearchPartnersDto } from './dto/search-partners.dto';
import { rankPartners } from './ranking.util';

@Injectable()
export class PartnersService {
  constructor(private readonly prisma: PrismaService) {}

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
