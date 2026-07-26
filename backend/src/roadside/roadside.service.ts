import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PartnersService } from '../partners/partners.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateRoadsideRequestDto } from './dto/create-roadside-request.dto';

// PRD (§13.17): "request-to-acceptance under 60 seconds [ASSUMPTION]".
// Average city driving speed used only to estimate ETA for display —
// not a committed SLA.
const ASSUMED_SPEED_KMH = 30;

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.asin(Math.sqrt(a));
}

@Injectable()
export class RoadsideService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly partnersService: PartnersService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async createRequest(customerId: string, dto: CreateRoadsideRequestDto) {
    const owner = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId: dto.vehicleId, userId: customerId } },
    });
    if (!owner) {
      throw new ForbiddenException({
        code: 'NOT_VEHICLE_OWNER',
        message: 'You can only request roadside assistance for a vehicle in your own garage.',
      });
    }

    const providers = await this.prisma.partner.findMany({
      where: { partnerType: 'roadside_provider', status: 'verified', latitude: { not: null }, longitude: { not: null } },
    });

    let nearest: (typeof providers)[number] | null = null;
    let nearestDistanceKm = Infinity;
    for (const p of providers) {
      const distanceKm = haversineKm(dto.location.lat, dto.location.lng, p.latitude!, p.longitude!);
      if (distanceKm < nearestDistanceKm) {
        nearestDistanceKm = distanceKm;
        nearest = p;
      }
    }

    const request = await this.prisma.roadsideRequest.create({
      data: {
        vehicleId: dto.vehicleId,
        customerId,
        serviceType: dto.serviceType,
        locationLat: dto.location.lat,
        locationLng: dto.location.lng,
        providerId: nearest?.id,
        status: nearest ? 'matched' : 'requested',
      },
    });

    await this.notificationsService.notify({
      userId: customerId,
      category: 'roadside_status',
      title: nearest ? 'Help is on the way' : 'Roadside request received',
      body: nearest
        ? `${nearest.businessName} has been matched to your request.`
        : "We're finding you a provider — you'll be notified as soon as one is matched.",
      relatedEntityType: 'roadside_request',
      relatedEntityId: request.id,
    });

    return this.track(customerId, request.id);
  }

  async track(customerId: string, id: string) {
    const request = await this.prisma.roadsideRequest.findUnique({ where: { id }, include: { provider: true } });
    if (!request) throw new NotFoundException({ code: 'REQUEST_NOT_FOUND', message: 'Roadside request not found.' });
    if (request.customerId !== customerId) {
      throw new ForbiddenException({ code: 'NOT_YOUR_REQUEST', message: 'You do not have access to this request.' });
    }

    let etaMinutes: number | null = null;
    if (request.provider?.latitude != null && request.provider?.longitude != null) {
      const distanceKm = haversineKm(request.locationLat, request.locationLng, request.provider.latitude, request.provider.longitude);
      etaMinutes = Math.max(1, Math.round((distanceKm / ASSUMED_SPEED_KMH) * 60));
    }

    return { ...request, etaMinutes };
  }

  listAllRequests(status?: string) {
    return this.prisma.roadsideRequest.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { requestedAt: 'desc' },
      include: { customer: { select: { fullName: true } }, provider: true, vehicle: true },
    });
  }

  getMyRequests(customerId: string) {
    return this.prisma.roadsideRequest.findMany({
      where: { customerId },
      orderBy: { requestedAt: 'desc' },
      include: { provider: true },
    });
  }

  async cancel(customerId: string, id: string) {
    const request = await this.prisma.roadsideRequest.findUnique({ where: { id } });
    if (!request || request.customerId !== customerId) {
      throw new ForbiddenException({ code: 'NOT_YOUR_REQUEST', message: 'You do not have access to this request.' });
    }
    return this.prisma.roadsideRequest.update({ where: { id }, data: { status: 'cancelled' } });
  }

  async findAllForPartner(userId: string) {
    const partnerId = await this.partnersService.resolvePartnerId(userId);
    return this.prisma.roadsideRequest.findMany({
      where: { providerId: partnerId },
      orderBy: { requestedAt: 'desc' },
      include: { customer: { select: { fullName: true, phoneNumber: true } }, vehicle: true },
    });
  }

  async updateStatus(id: string, status: string, callerId: string, callerRole: string) {
    if (callerRole === 'partner') {
      const partnerId = await this.partnersService.resolvePartnerId(callerId);
      const request = await this.prisma.roadsideRequest.findUnique({ where: { id } });
      if (!request || request.providerId !== partnerId) {
        throw new ForbiddenException({ code: 'NOT_YOUR_REQUEST', message: 'This request is not assigned to your business.' });
      }
    }

    const updated = await this.prisma.roadsideRequest.update({
      where: { id },
      data: {
        status: status as never,
        completedAt: status === 'completed' ? new Date() : undefined,
      },
    });

    await this.notificationsService.notify({
      userId: updated.customerId,
      category: 'roadside_status',
      title: 'Roadside update',
      body: `Your roadside request is now ${status.replace('_', ' ')}.`,
      relatedEntityType: 'roadside_request',
      relatedEntityId: id,
    });

    return updated;
  }
}
