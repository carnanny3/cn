import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { AddDocumentDto } from './dto/add-document.dto';
import { calculateHealthScore } from './health-score.util';
import { StorageService } from '../storage/storage.service';

const REQUIRED_DOC_TYPES = ['registration', 'insurance'] as const;

@Injectable()
export class VehiclesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  async create(userId: string, dto: CreateVehicleDto) {
    if (dto.vin) {
      const existing = await this.prisma.vehicle.findUnique({ where: { vin: dto.vin } });
      if (existing) {
        throw new ConflictException({
          code: 'VIN_ALREADY_REGISTERED',
          message: 'This VIN is already registered to a Car Nanny account. Contact support if you believe this is an error.',
        });
      }
    }

    const vehicle = await this.prisma.vehicle.create({
      data: {
        vin: dto.vin,
        plateNumber: dto.plateNumber,
        emirateRegistered: dto.emirateRegistered,
        make: dto.make,
        model: dto.model,
        year: dto.year,
        bodyType: dto.bodyType,
        fuelType: dto.fuelType,
        transmission: dto.transmission,
        gccSpec: dto.gccSpec ?? true,
        color: dto.color,
        mileageKm: dto.mileageKm,
        primaryPhotoUrl: dto.primaryPhotoUrl,
        owners: {
          create: { userId, isPrimary: true, ownershipType: 'personal' },
        },
      },
    });

    return vehicle;
  }

  async findAllForUser(userId: string) {
    const owners = await this.prisma.vehicleOwner.findMany({
      where: { userId },
      include: { vehicle: true },
      orderBy: { addedAt: 'asc' },
    });
    return owners.map((o) => o.vehicle);
  }

  async findOneForUser(userId: string, vehicleId: string) {
    await this.assertOwnership(userId, vehicleId);
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle) throw new NotFoundException({ code: 'VEHICLE_NOT_FOUND', message: 'Vehicle not found.' });
    return vehicle;
  }

  async update(userId: string, vehicleId: string, dto: UpdateVehicleDto) {
    await this.assertOwnership(userId, vehicleId);
    return this.prisma.vehicle.update({ where: { id: vehicleId }, data: dto });
  }

  async addDocument(
    userId: string,
    vehicleId: string,
    dto: AddDocumentDto,
    file: { buffer: Buffer; mimetype: string; size: number; originalname?: string },
  ) {
    await this.assertOwnership(userId, vehicleId);
    const { key } = await this.storage.upload(file, 'vehicle-docs', vehicleId);
    const document = await this.prisma.vehicleDocument.create({
      data: {
        vehicleId,
        type: dto.type,
        // Documents are private, so this column holds the storage key rather
        // than a URL; readable links are minted per request in listDocuments.
        fileUrl: key,
        issuedDate: dto.issuedDate ? new Date(dto.issuedDate) : undefined,
        expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : undefined,
        uploadedBy: userId,
      },
    });
    return { ...document, viewUrl: await this.storage.viewUrlFor(document.fileUrl) };
  }

  async listDocuments(userId: string, vehicleId: string) {
    await this.assertOwnership(userId, vehicleId);
    const documents = await this.prisma.vehicleDocument.findMany({
      where: { vehicleId },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(
      documents.map(async (doc) => ({ ...doc, viewUrl: await this.storage.viewUrlFor(doc.fileUrl) })),
    );
  }

  async setPrimaryPhoto(
    userId: string,
    vehicleId: string,
    file: { buffer: Buffer; mimetype: string; size: number; originalname?: string },
  ) {
    await this.assertOwnership(userId, vehicleId);
    const { url } = await this.storage.upload(file, 'vehicle-photos', vehicleId);
    return this.prisma.vehicle.update({ where: { id: vehicleId }, data: { primaryPhotoUrl: url } });
  }

  async getHealthScore(userId: string, vehicleId: string) {
    const vehicle = await this.findOneForUser(userId, vehicleId);

    const latestReport = await this.prisma.inspectionReport.findFirst({
      where: { inspection: { vehicleId } },
      orderBy: { generatedAt: 'desc' },
    });

    const twelveMonthsAgo = new Date();
    twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);
    const [completedServiceBookings, loggedServices] = await Promise.all([
      this.prisma.booking.count({
        where: {
          vehicleId,
          bookingType: 'service',
          status: 'completed',
          scheduledAt: { gte: twelveMonthsAgo },
        },
      }),
      // Servicing done outside Car Nanny still counts, as long as the owner logged it.
      this.prisma.vehicleRecord.count({
        where: { vehicleId, type: { in: ['service', 'repair'] }, date: { gte: twelveMonthsAgo } },
      }),
    ]);

    const now = new Date();
    const docs = await this.prisma.vehicleDocument.findMany({ where: { vehicleId } });
    const validDocTypes = new Set(
      docs
        .filter((d) => !d.expiryDate || d.expiryDate > now)
        .map((d) => d.type),
    );
    const requiredDocsPresentAndValid = REQUIRED_DOC_TYPES.filter((t) => validDocTypes.has(t)).length;

    const breakdown = calculateHealthScore({
      latestInspectionScoreOutOf10: latestReport?.overallScore ?? null,
      servicesLast12Months: completedServiceBookings + loggedServices,
      vehicleYear: vehicle.year,
      requiredDocsPresentAndValid,
      requiredDocsTotal: REQUIRED_DOC_TYPES.length,
    });

    await this.prisma.vehicle.update({
      where: { id: vehicleId },
      data: { healthScore: breakdown.overall, healthScoreUpdatedAt: new Date() },
    });

    return breakdown;
  }

  // ---------- Co-owners ----------

  async listOwners(userId: string, vehicleId: string) {
    await this.assertOwnership(userId, vehicleId);
    const owners = await this.prisma.vehicleOwner.findMany({
      where: { vehicleId },
      include: { user: { select: { id: true, fullName: true, email: true } } },
      orderBy: [{ isPrimary: 'desc' }, { addedAt: 'asc' }],
    });
    return owners.map((o) => ({
      userId: o.user.id,
      fullName: o.user.fullName,
      email: o.user.email,
      isPrimary: o.isPrimary,
      addedAt: o.addedAt,
      isYou: o.user.id === userId,
    }));
  }

  /**
   * Gives another Car Nanny account full access to this vehicle's profile,
   * documents and logbook. Only the primary owner can do this.
   */
  async addCoOwner(userId: string, vehicleId: string, email: string) {
    await this.assertPrimaryOwner(userId, vehicleId);
    const invitee = await this.prisma.user.findFirst({
      where: { email: { equals: email.trim(), mode: 'insensitive' }, status: { not: 'suspended' } },
    });
    if (!invitee) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'No Car Nanny account uses that email. Ask them to sign up first.',
      });
    }
    const existing = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId, userId: invitee.id } },
    });
    if (existing) {
      throw new ConflictException({ code: 'ALREADY_OWNER', message: 'That person already has access to this vehicle.' });
    }
    await this.prisma.vehicleOwner.create({
      data: { vehicleId, userId: invitee.id, isPrimary: false, ownershipType: 'personal' },
    });
    return this.listOwners(userId, vehicleId);
  }

  /** The primary owner can remove anyone else; a co-owner can remove only themselves. */
  async removeOwner(userId: string, vehicleId: string, ownerUserId: string) {
    const me = await this.assertOwnership(userId, vehicleId);
    const target = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId, userId: ownerUserId } },
    });
    if (!target) throw new NotFoundException({ code: 'OWNER_NOT_FOUND', message: 'That person does not have access.' });
    if (target.isPrimary) {
      throw new ForbiddenException({ code: 'CANNOT_REMOVE_PRIMARY', message: 'The primary owner cannot be removed.' });
    }
    if (ownerUserId !== userId && !me.isPrimary) {
      throw new ForbiddenException({ code: 'NOT_PRIMARY_OWNER', message: 'Only the primary owner can remove someone.' });
    }
    await this.prisma.vehicleOwner.delete({ where: { id: target.id } });
    return { removed: true };
  }

  private async assertPrimaryOwner(userId: string, vehicleId: string) {
    const owner = await this.assertOwnership(userId, vehicleId);
    if (!owner.isPrimary) {
      throw new ForbiddenException({ code: 'NOT_PRIMARY_OWNER', message: 'Only the primary owner can share this vehicle.' });
    }
  }

  /** Throws unless the user is one of the vehicle's owners (primary or co-owner). */
  async assertOwnership(userId: string, vehicleId: string) {
    const owner = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId, userId } },
    });
    if (!owner) {
      throw new ForbiddenException({
        code: 'NOT_VEHICLE_OWNER',
        message: 'You do not have access to this vehicle.',
      });
    }
    return owner;
  }
}
