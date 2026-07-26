import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';

@Injectable()
export class PromotionsService {
  constructor(private readonly prisma: PrismaService) {}

  listAll() {
    return this.prisma.coupon.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async validate(code: string) {
    const coupon = await this.prisma.coupon.findUnique({ where: { code: code.toUpperCase() } });
    if (!coupon || !coupon.active) {
      throw new NotFoundException({ code: 'COUPON_NOT_FOUND', message: 'This coupon code is not valid.' });
    }
    if (coupon.expiresAt && coupon.expiresAt < new Date()) {
      throw new BadRequestException({ code: 'COUPON_EXPIRED', message: 'This coupon has expired.' });
    }
    if (coupon.maxRedemptions != null && coupon.redeemedCount >= coupon.maxRedemptions) {
      throw new BadRequestException({ code: 'COUPON_EXHAUSTED', message: 'This coupon has reached its redemption limit.' });
    }
    return coupon;
  }

  create(dto: CreateCouponDto) {
    return this.prisma.coupon.create({
      data: {
        code: dto.code.toUpperCase(),
        description: dto.description,
        discountType: dto.discountType,
        discountValue: dto.discountValue,
        maxRedemptions: dto.maxRedemptions,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : undefined,
      },
    });
  }

  async getOne(id: string) {
    const coupon = await this.prisma.coupon.findUnique({ where: { id } });
    if (!coupon) throw new NotFoundException({ code: 'COUPON_NOT_FOUND', message: 'Coupon not found.' });
    return coupon;
  }

  async update(id: string, dto: UpdateCouponDto) {
    await this.getOne(id);
    return this.prisma.coupon.update({ where: { id }, data: dto });
  }
}
