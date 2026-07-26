import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PartnersService } from '../partners/partners.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateConciergeOrderDto } from './dto/create-order.dto';
import { UpdateConciergeOrderDto } from './dto/update-order.dto';

// Per-order-type document checklists (PRD §13.18: "order created with
// required document checklist per service type"). Adding a new concierge
// service type is meant to be a configuration addition here, not a new
// code path — matching the PRD's explicit "generic engine" framing.
const DOCUMENT_CHECKLISTS: Record<string, string[]> = {
  registration_renewal: ['Current registration card', 'Valid insurance certificate', 'Passed vehicle test certificate'],
  ownership_transfer: ['Emirates ID (buyer & seller)', 'Current registration card', 'NOC from finance company (if financed)'],
  pickup_delivery: ['Vehicle key handover confirmation'],
  detailing: [],
  driver_service: ['Valid driving license on file'],
};

function buildChecklist(orderType: string) {
  const items = DOCUMENT_CHECKLISTS[orderType] ?? [];
  return { items: items.map((label) => ({ label, done: false })) };
}

@Injectable()
export class ConciergeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly partnersService: PartnersService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async createOrder(customerId: string, dto: CreateConciergeOrderDto) {
    const owner = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId: dto.vehicleId, userId: customerId } },
    });
    if (!owner) {
      throw new ForbiddenException({
        code: 'NOT_VEHICLE_OWNER',
        message: 'You can only request concierge services for a vehicle in your own garage.',
      });
    }

    const order = await this.prisma.conciergeOrder.create({
      data: {
        orderType: dto.orderType,
        vehicleId: dto.vehicleId,
        customerId,
        documentChecklist: buildChecklist(dto.orderType),
      },
    });

    await this.notificationsService.notify({
      userId: customerId,
      category: 'concierge_status',
      title: 'Concierge request received',
      body: "We've received your request and will assign it to our team shortly.",
      relatedEntityType: 'concierge_order',
      relatedEntityId: order.id,
    });

    return order;
  }

  getMyOrders(customerId: string) {
    return this.prisma.conciergeOrder.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
      include: { vehicle: true, assignedPartner: { select: { businessName: true } } },
    });
  }

  async getOrder(customerId: string | null, id: string) {
    const order = await this.prisma.conciergeOrder.findUnique({
      where: { id },
      include: { vehicle: true, assignedPartner: { select: { businessName: true } } },
    });
    if (!order) throw new NotFoundException({ code: 'ORDER_NOT_FOUND', message: 'Concierge order not found.' });
    if (customerId && order.customerId !== customerId) {
      throw new ForbiddenException({ code: 'NOT_YOUR_ORDER', message: 'You do not have access to this order.' });
    }
    return order;
  }

  listAllOrders(status?: string) {
    return this.prisma.conciergeOrder.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { createdAt: 'desc' },
      include: { customer: { select: { fullName: true } }, vehicle: true, assignedPartner: true },
    });
  }

  async updateOrder(id: string, dto: UpdateConciergeOrderDto) {
    const order = await this.prisma.conciergeOrder.findUnique({ where: { id } });
    if (!order) throw new NotFoundException({ code: 'ORDER_NOT_FOUND', message: 'Concierge order not found.' });

    const updated = await this.prisma.conciergeOrder.update({
      where: { id },
      data: {
        status: dto.status as never,
        assignedPartnerId: dto.assignedPartnerId,
        assignedAdminId: dto.assignedAdminId,
      },
    });

    if (dto.status) {
      await this.notificationsService.notify({
        userId: order.customerId,
        category: 'concierge_status',
        title: 'Concierge order update',
        body: `Your concierge request is now ${dto.status.replace('_', ' ')}.`,
        relatedEntityType: 'concierge_order',
        relatedEntityId: id,
      });
    }

    return updated;
  }

  async findAllForPartner(userId: string) {
    const partnerId = await this.partnersService.resolvePartnerId(userId);
    return this.prisma.conciergeOrder.findMany({
      where: { assignedPartnerId: partnerId },
      orderBy: { createdAt: 'desc' },
      include: { customer: { select: { fullName: true, phoneNumber: true } }, vehicle: true },
    });
  }

  async updateStatusAsPartner(id: string, status: string, callerId: string) {
    const partnerId = await this.partnersService.resolvePartnerId(callerId);
    const order = await this.prisma.conciergeOrder.findUnique({ where: { id } });
    if (!order || order.assignedPartnerId !== partnerId) {
      throw new ForbiddenException({ code: 'NOT_YOUR_ORDER', message: 'This order is not assigned to your business.' });
    }
    return this.updateOrder(id, { status: status as never });
  }
}
