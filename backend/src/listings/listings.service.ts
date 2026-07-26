import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { CreateAdminListingDto } from './dto/create-admin-listing.dto';

const MAX_COMPARE = 3;

@Injectable()
export class ListingsService {
  constructor(private readonly prisma: PrismaService) {}

  /** A customer listing their own owned vehicle for sale — tagged "private" per the trust-level requirement (PRD §13.5/§36: every listing must show Certified/Dealer/Private). */
  async createPrivateListing(sellerId: string, dto: CreateListingDto) {
    if (dto.vehicleId) {
      const owner = await this.prisma.vehicleOwner.findUnique({
        where: { vehicleId_userId: { vehicleId: dto.vehicleId, userId: sellerId } },
      });
      if (!owner) {
        throw new ForbiddenException({
          code: 'NOT_VEHICLE_OWNER',
          message: 'You can only list a vehicle that is in your own garage.',
        });
      }
    }

    return this.prisma.vehicleListing.create({
      data: {
        vehicleId: dto.vehicleId,
        sellerId,
        sellerType: 'private',
        make: dto.make,
        model: dto.model,
        year: dto.year,
        mileageKm: dto.mileageKm,
        askingPrice: dto.askingPrice,
        photos: dto.photoUrls ? { urls: dto.photoUrls } : undefined,
        status: 'active',
      },
    });
  }

  /** Car Nanny's own certified inventory — the only listing type live at Phase 2 launch per the PRD's phasing note. */
  createCertifiedListing(dto: CreateAdminListingDto) {
    return this.prisma.vehicleListing.create({
      data: {
        vehicleId: dto.vehicleId,
        sellerType: 'certified',
        make: dto.make,
        model: dto.model,
        year: dto.year,
        mileageKm: dto.mileageKm,
        askingPrice: dto.askingPrice,
        inspectionId: dto.inspectionId,
        photos: dto.photoUrls ? { urls: dto.photoUrls } : undefined,
        status: 'active',
      },
    });
  }

  listActive(make?: string) {
    return this.prisma.vehicleListing.findMany({
      where: { status: 'active', ...(make ? { make: { equals: make, mode: 'insensitive' } } : {}) },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getOne(id: string) {
    const listing = await this.prisma.vehicleListing.findUnique({
      where: { id },
      include: { inspection: { include: { report: true } } },
    });
    if (!listing) throw new NotFoundException({ code: 'LISTING_NOT_FOUND', message: 'Listing not found.' });
    return listing;
  }

  async compare(ids: string[]) {
    if (ids.length === 0 || ids.length > MAX_COMPARE) {
      throw new BadRequestException({
        code: 'INVALID_COMPARE_COUNT',
        message: `Provide between 1 and ${MAX_COMPARE} listing ids to compare.`,
      });
    }
    return this.prisma.vehicleListing.findMany({
      where: { id: { in: ids } },
      include: { inspection: { include: { report: true } } },
    });
  }

  getMyListings(sellerId: string) {
    return this.prisma.vehicleListing.findMany({ where: { sellerId }, orderBy: { createdAt: 'desc' } });
  }

  listAll(status?: string) {
    return this.prisma.vehicleListing.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  updateStatus(id: string, status: string) {
    return this.prisma.vehicleListing.update({ where: { id }, data: { status: status as never } });
  }
}
