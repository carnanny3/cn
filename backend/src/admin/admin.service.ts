import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const ADMIN_ROLES = [
  'admin_super',
  'admin_ops',
  'admin_inspection',
  'admin_support',
  'admin_finance',
  'admin_partner_manager',
  'admin_content',
  'admin_compliance',
  'admin_analyst',
];

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  listUsers() {
    return this.prisma.user.findMany({
      where: { role: { notIn: ADMIN_ROLES as never[] } },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        fullName: true,
        phoneNumber: true,
        email: true,
        status: true,
        accountType: true,
        emirate: true,
        createdAt: true,
      },
    });
  }

  listVehicles() {
    return this.prisma.vehicle.findMany({
      orderBy: { createdAt: 'desc' },
      include: { owners: { include: { user: { select: { fullName: true, phoneNumber: true } } } } },
    });
  }

  listPartners(status?: string) {
    return this.prisma.partner.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  listInspections(status?: string) {
    return this.prisma.inspection.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { scheduledAt: 'desc' },
      include: { vehicle: true, requester: { select: { fullName: true, phoneNumber: true } }, report: true },
    });
  }

  listBookings(status?: string) {
    return this.prisma.booking.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { scheduledAt: 'desc' },
      include: {
        vehicle: true,
        customer: { select: { fullName: true, phoneNumber: true } },
        partner: true,
      },
    });
  }

  async dashboardSummary() {
    const [userCount, vehicleCount, pendingPartners, qaQueueCount, activeBookings] = await Promise.all([
      this.prisma.user.count({ where: { role: 'customer' } }),
      this.prisma.vehicle.count(),
      this.prisma.partner.count({ where: { status: 'pending' } }),
      this.prisma.inspection.count({ where: { status: 'qa_review' } }),
      this.prisma.booking.count({ where: { status: { in: ['pending', 'confirmed', 'in_progress'] } } }),
    ]);
    return { userCount, vehicleCount, pendingPartners, qaQueueCount, activeBookings };
  }
}
