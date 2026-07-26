import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PartnersService } from '../partners/partners.service';
import { BookInspectionDto } from './dto/book-inspection.dto';
import { SubmitCheckpointsDto } from './dto/submit-checkpoints.dto';
import { generateInspectionReport, AI_DISCLAIMER } from './report-generator.util';

const INSPECTION_PRICE_AED = 349;
const VAT_RATE = 0.05;

@Injectable()
export class InspectionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly partnersService: PartnersService,
  ) {}

  async book(requesterId: string, dto: BookInspectionDto) {
    if (!dto.vehicleId && !dto.plateNumber) {
      throw new BadRequestException({
        code: 'VEHICLE_REFERENCE_REQUIRED',
        message: 'Provide either vehicleId (for an owned vehicle) or plateNumber/makeModelYear (for a pre-purchase inspection).',
      });
    }

    const inspection = await this.prisma.inspection.create({
      data: {
        vehicleId: dto.vehicleId,
        requesterId,
        rawPlateNumber: dto.plateNumber,
        rawMakeModelYear: dto.makeModelYear,
        status: 'booked',
        scheduledAt: new Date(dto.scheduledAt),
        locationLat: dto.location.lat,
        locationLng: dto.location.lng,
        locationAddress: dto.location.address,
        priceAmount: INSPECTION_PRICE_AED,
      },
    });

    return {
      id: inspection.id,
      status: inspection.status,
      priceAmount: INSPECTION_PRICE_AED,
      currency: 'AED',
      vatAmount: Math.round(INSPECTION_PRICE_AED * VAT_RATE * 100) / 100,
    };
  }

  async findOne(id: string) {
    const inspection = await this.prisma.inspection.findUnique({
      where: { id },
      include: { vehicle: true, inspector: true },
    });
    if (!inspection) throw new NotFoundException({ code: 'INSPECTION_NOT_FOUND', message: 'Inspection not found.' });
    return inspection;
  }

  async assignInspector(inspectionId: string, inspectorId: string) {
    const partner = await this.prisma.partner.findUnique({ where: { id: inspectorId } });
    if (!partner || partner.partnerType !== 'inspector' || partner.status !== 'verified') {
      throw new BadRequestException({
        code: 'INVALID_INSPECTOR',
        message: 'The selected partner is not a verified inspector.',
      });
    }
    return this.prisma.inspection.update({
      where: { id: inspectionId },
      data: { inspectorId, status: 'assigned' },
    });
  }

  async updateStatus(inspectionId: string, status: string, callerId: string, callerRole: string) {
    await this.assertInspectorAccess(inspectionId, callerId, callerRole);
    return this.prisma.inspection.update({
      where: { id: inspectionId },
      data: { status: status as never },
    });
  }

  async findAllForPartner(userId: string) {
    const partnerId = await this.partnersService.resolvePartnerId(userId);
    return this.prisma.inspection.findMany({
      where: { inspectorId: partnerId },
      orderBy: { scheduledAt: 'desc' },
      include: { vehicle: true, requester: { select: { fullName: true, phoneNumber: true } } },
    });
  }

  /** Enforces that a `partner`-role caller may only act on jobs assigned to their own business; other roles (admin) are unrestricted here. */
  private async assertInspectorAccess(inspectionId: string, callerId: string, callerRole: string) {
    if (callerRole !== 'partner') return;
    const partnerId = await this.partnersService.resolvePartnerId(callerId);
    const inspection = await this.prisma.inspection.findUnique({ where: { id: inspectionId } });
    if (!inspection || inspection.inspectorId !== partnerId) {
      throw new ForbiddenException({
        code: 'NOT_YOUR_INSPECTION',
        message: 'This inspection is not assigned to your business.',
      });
    }
  }

  async submitCheckpoints(inspectionId: string, dto: SubmitCheckpointsDto, callerId: string, callerRole: string) {
    await this.assertInspectorAccess(inspectionId, callerId, callerRole);
    const inspection = await this.prisma.inspection.findUnique({
      where: { id: inspectionId },
      include: { vehicle: true },
    });
    if (!inspection) throw new NotFoundException({ code: 'INSPECTION_NOT_FOUND', message: 'Inspection not found.' });

    await this.prisma.$transaction(
      dto.checkpoints.map((cp) =>
        this.prisma.inspectionCheckpoint.create({
          data: {
            inspectionId,
            category: cp.category as never,
            checkpointName: cp.checkpointName,
            result: cp.result as never,
            notes: cp.notes,
          },
        }),
      ),
    );

    await this.prisma.inspection.update({
      where: { id: inspectionId },
      data: { status: 'qa_review' },
    });

    const vehicleLabel = inspection.vehicle
      ? `${inspection.vehicle.year} ${inspection.vehicle.make} ${inspection.vehicle.model}`
      : inspection.rawMakeModelYear || 'This vehicle';

    const generated = generateInspectionReport(dto.checkpoints, vehicleLabel);

    const report = await this.prisma.inspectionReport.upsert({
      where: { inspectionId },
      create: {
        inspectionId,
        overallScore: generated.overallScore,
        overallStatus: generated.overallStatus,
        categoryScores: generated.categoryScores,
        criticalDefectCount: generated.criticalDefectCount,
        minorDefectCount: generated.minorDefectCount,
        estimatedRepairCost: generated.estimatedRepairCost,
        aiSummary: generated.aiSummary,
        aiRecommendation: generated.aiRecommendation,
        roadTestNotes: dto.roadTestNotes,
      },
      update: {
        overallScore: generated.overallScore,
        overallStatus: generated.overallStatus,
        categoryScores: generated.categoryScores,
        criticalDefectCount: generated.criticalDefectCount,
        minorDefectCount: generated.minorDefectCount,
        estimatedRepairCost: generated.estimatedRepairCost,
        aiSummary: generated.aiSummary,
        aiRecommendation: generated.aiRecommendation,
        roadTestNotes: dto.roadTestNotes,
      },
    });

    return report;
  }

  async approveReport(inspectionId: string) {
    await this.prisma.inspection.update({
      where: { id: inspectionId },
      data: { status: 'completed' },
    });
    return this.getReport(inspectionId);
  }

  async getReport(inspectionId: string) {
    const report = await this.prisma.inspectionReport.findUnique({ where: { inspectionId } });
    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_READY',
        message: 'This inspection report has not been generated yet.',
      });
    }
    return { ...report, disclaimer: AI_DISCLAIMER };
  }

  /** Allows either the customer who requested the inspection or the assigned inspector's own partner account to view it. */
  async assertRequester(userId: string, inspectionId: string) {
    const inspection = await this.prisma.inspection.findUnique({ where: { id: inspectionId } });
    if (!inspection) {
      throw new NotFoundException({ code: 'INSPECTION_NOT_FOUND', message: 'Inspection not found.' });
    }
    if (inspection.requesterId === userId) return;
    if (inspection.inspectorId) {
      const partner = await this.prisma.partner.findUnique({ where: { userId } });
      if (partner && partner.id === inspection.inspectorId) return;
    }
    throw new ForbiddenException({
      code: 'NOT_INSPECTION_PARTICIPANT',
      message: 'You do not have access to this inspection.',
    });
  }
}
