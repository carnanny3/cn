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
    const completedServiceBookings = await this.prisma.booking.count({
      where: {
        vehicleId,
        bookingType: 'service',
        status: 'completed',
        scheduledAt: { gte: twelveMonthsAgo },
      },
    });

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
      completedServiceBookingsLast12Months: completedServiceBookings,
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

  private async assertOwnership(userId: string, vehicleId: string) {
    const owner = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId, userId } },
    });
    if (!owner) {
      throw new ForbiddenException({
        code: 'NOT_VEHICLE_OWNER',
        message: 'You do not have access to this vehicle.',
      });
    }
  }
}
