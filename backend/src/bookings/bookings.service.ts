import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PartnersService } from '../partners/partners.service';
import { NotificationsService } from '../notifications/notifications.service';
import { RewardsService } from '../rewards/rewards.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@Injectable()
export class BookingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly partnersService: PartnersService,
    private readonly notificationsService: NotificationsService,
    private readonly rewardsService: RewardsService,
  ) {}

  async create(customerId: string, dto: CreateBookingDto) {
    const owner = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId: dto.vehicleId, userId: customerId } },
    });
    if (!owner) {
      throw new ForbiddenException({
        code: 'NOT_VEHICLE_OWNER',
        message: 'You can only book services for a vehicle in your own garage.',
      });
    }

    const booking = await this.prisma.booking.create({
      data: {
        bookingType: dto.bookingType,
        vehicleId: dto.vehicleId,
        customerId,
        partnerId: dto.partnerId,
        serviceCategory: dto.serviceCategory,
        status: 'pending',
        scheduledAt: new Date(dto.scheduledAt),
        pickupDeliveryRequested: dto.pickupDeliveryRequested ?? false,
        totalAmount: dto.totalAmount,
      },
    });

    await this.prisma.bookingStatusHistory.create({
      data: { bookingId: booking.id, status: 'pending', changedBy: customerId },
    });

    await this.notificationsService.notify({
      userId: customerId,
      category: 'booking_status',
      title: 'Booking received',
      body: `Your ${dto.bookingType} booking has been received and is awaiting confirmation.`,
      relatedEntityType: 'booking',
      relatedEntityId: booking.id,
    });

    return {
      ...booking,
      vatAmount: Math.round(dto.totalAmount * 0.05 * 100) / 100,
    };
  }

  async findAllForUser(customerId: string) {
    return this.prisma.booking.findMany({
      where: { customerId },
      orderBy: { scheduledAt: 'desc' },
      include: { partner: true, statusHistory: true },
    });
  }

  async findAllForPartner(userId: string) {
    const partnerId = await this.partnersService.resolvePartnerId(userId);
    return this.prisma.booking.findMany({
      where: { partnerId },
      orderBy: { scheduledAt: 'desc' },
      include: { customer: { select: { fullName: true, phoneNumber: true } }, vehicle: true, statusHistory: true },
    });
  }

  async findOne(customerId: string, id: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id },
      include: { partner: true, statusHistory: { orderBy: { changedAt: 'asc' } } },
    });
    if (!booking) throw new NotFoundException({ code: 'BOOKING_NOT_FOUND', message: 'Booking not found.' });
    if (booking.customerId !== customerId) {
      throw new ForbiddenException({ code: 'NOT_BOOKING_OWNER', message: 'You do not have access to this booking.' });
    }
    return booking;
  }

  async updateStatus(id: string, status: string, changedBy: string, callerRole: string) {
    if (callerRole === 'partner') {
      const partnerId = await this.partnersService.resolvePartnerId(changedBy);
      const booking = await this.prisma.booking.findUnique({ where: { id } });
      if (!booking || booking.partnerId !== partnerId) {
        throw new ForbiddenException({
          code: 'NOT_YOUR_BOOKING',
          message: 'This booking is not assigned to your business.',
        });
      }
    }

    const booking = await this.prisma.booking.update({
      where: { id },
      data: { status: status as never },
    });
    await this.prisma.bookingStatusHistory.create({
      data: { bookingId: id, status: status as never, changedBy },
    });

    await this.notificationsService.notify({
      userId: booking.customerId,
      category: 'booking_status',
      title: 'Booking update',
      body: `Your booking is now ${status.replace('_', ' ')}.`,
      relatedEntityType: 'booking',
      relatedEntityId: booking.id,
    });

    if (status === 'completed') {
      await this.rewardsService.onBookingCompleted(booking.customerId, booking.totalAmount);
    }

    return booking;
  }

  async cancel(customerId: string, id: string) {
    await this.findOne(customerId, id);
    return this.updateStatus(id, 'cancelled', customerId, 'customer');
  }
}
