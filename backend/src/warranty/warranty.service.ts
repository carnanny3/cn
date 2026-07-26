import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateWarrantyPlanDto } from './dto/create-warranty-plan.dto';
import { PurchaseWarrantyPolicyDto } from './dto/purchase-warranty-policy.dto';
import { SubmitClaimDto } from './dto/submit-claim.dto';
import { UpdateClaimStatusDto } from './dto/update-claim-status.dto';

const POLICY_TERM_DAYS = 365;

function generatePolicyNumber(prefix: string): string {
  return `${prefix}-${randomBytes(4).toString('hex').toUpperCase()}`;
}

@Injectable()
export class WarrantyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  createPlan(dto: CreateWarrantyPlanDto) {
    return this.prisma.warrantyPlan.create({
      data: {
        providerPartnerId: dto.providerPartnerId,
        name: dto.name,
        coverageSummary: dto.coverageSummary,
        exclusions: dto.exclusions,
        price: dto.price,
        eligibilityRules: dto.eligibilityRules,
      },
    });
  }

  async listPlans(vehicleId?: string) {
    const plans = await this.prisma.warrantyPlan.findMany({
      where: { active: true },
      include: { providerPartner: { select: { businessName: true } } },
    });
    if (!vehicleId) return plans;

    const vehicle = await this.prisma.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle) return plans;

    return plans.map((plan) => ({ ...plan, eligible: this.isEligible(plan.eligibilityRules, vehicle) }));
  }

  private isEligible(rules: unknown, vehicle: { year: number; mileageKm: number | null }): boolean {
    const r = rules as { maxAgeYears?: number; maxMileageKm?: number } | null;
    if (!r) return true;
    const ageYears = new Date().getFullYear() - vehicle.year;
    if (r.maxAgeYears !== undefined && ageYears > r.maxAgeYears) return false;
    if (r.maxMileageKm !== undefined && (vehicle.mileageKm ?? 0) > r.maxMileageKm) return false;
    return true;
  }

  async purchasePolicy(customerId: string, dto: PurchaseWarrantyPolicyDto) {
    const owner = await this.prisma.vehicleOwner.findUnique({
      where: { vehicleId_userId: { vehicleId: dto.vehicleId, userId: customerId } },
    });
    if (!owner) {
      throw new ForbiddenException({
        code: 'NOT_VEHICLE_OWNER',
        message: 'You can only buy a warranty for a vehicle in your own garage.',
      });
    }

    const plan = await this.prisma.warrantyPlan.findUnique({ where: { id: dto.planId } });
    if (!plan || !plan.active) {
      throw new NotFoundException({ code: 'PLAN_NOT_FOUND', message: 'Warranty plan not found.' });
    }

    const vehicle = await this.prisma.vehicle.findUniqueOrThrow({ where: { id: dto.vehicleId } });
    if (!this.isEligible(plan.eligibilityRules, vehicle)) {
      throw new BadRequestException({
        code: 'VEHICLE_NOT_ELIGIBLE',
        message: 'This vehicle does not meet the eligibility criteria for this plan.',
      });
    }

    const startDate = new Date();
    const endDate = new Date(startDate.getTime() + POLICY_TERM_DAYS * 24 * 60 * 60 * 1000);

    const policy = await this.prisma.warrantyPolicy.create({
      data: {
        planId: plan.id,
        vehicleId: dto.vehicleId,
        customerId,
        policyNumber: generatePolicyNumber('WP'),
        startDate,
        endDate,
      },
    });

    await this.notificationsService.notify({
      userId: customerId,
      category: 'warranty_status',
      title: 'Warranty policy purchased',
      body: `Your "${plan.name}" warranty is now active until ${endDate.toLocaleDateString()}.`,
      relatedEntityType: 'warranty_policy',
      relatedEntityId: policy.id,
    });

    return policy;
  }

  getMyPolicies(customerId: string) {
    return this.prisma.warrantyPolicy.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
      include: { plan: true, claims: true },
    });
  }

  async submitClaim(customerId: string, dto: SubmitClaimDto) {
    const policy = await this.prisma.warrantyPolicy.findUnique({ where: { id: dto.policyId } });
    if (!policy || policy.customerId !== customerId) {
      throw new ForbiddenException({ code: 'NOT_YOUR_POLICY', message: 'You do not have access to this policy.' });
    }
    if (policy.status !== 'active') {
      throw new BadRequestException({ code: 'POLICY_NOT_ACTIVE', message: 'This policy is not active.' });
    }

    const claim = await this.prisma.warrantyClaim.create({
      data: {
        policyId: dto.policyId,
        description: dto.description,
        documents: dto.documentUrls
          ? { create: dto.documentUrls.map((url) => ({ fileUrl: url, type: 'claim_evidence' })) }
          : undefined,
      },
      include: { documents: true },
    });

    return claim;
  }

  getMyClaims(customerId: string) {
    return this.prisma.warrantyClaim.findMany({
      where: { policy: { customerId } },
      orderBy: { createdAt: 'desc' },
      include: { policy: { include: { plan: true } }, documents: true },
    });
  }

  async getClaim(customerId: string | null, claimId: string) {
    const claim = await this.prisma.warrantyClaim.findUnique({
      where: { id: claimId },
      include: { policy: true, documents: true },
    });
    if (!claim) throw new NotFoundException({ code: 'CLAIM_NOT_FOUND', message: 'Claim not found.' });
    if (customerId && claim.policy.customerId !== customerId) {
      throw new ForbiddenException({ code: 'NOT_YOUR_CLAIM', message: 'You do not have access to this claim.' });
    }
    return claim;
  }

  listAllClaims(status?: string) {
    return this.prisma.warrantyClaim.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { createdAt: 'desc' },
      include: { policy: { include: { customer: { select: { fullName: true } }, plan: true } } },
    });
  }

  async updateClaimStatus(claimId: string, dto: UpdateClaimStatusDto) {
    const claim = await this.prisma.warrantyClaim.findUnique({ where: { id: claimId }, include: { policy: true } });
    if (!claim) throw new NotFoundException({ code: 'CLAIM_NOT_FOUND', message: 'Claim not found.' });

    const updated = await this.prisma.warrantyClaim.update({
      where: { id: claimId },
      data: {
        status: dto.status as never,
        rejectionReason: dto.status === 'rejected' ? dto.rejectionReason : undefined,
        assignedGarageId: dto.assignedGarageId,
      },
    });

    // Authorizing a repair with a garage assigned hands the job to that
    // garage via the same Partner Portal job queue bookings already use.
    if (dto.status === 'repair_authorized' && dto.assignedGarageId) {
      await this.prisma.booking.create({
        data: {
          bookingType: 'service',
          vehicleId: claim.policy.vehicleId,
          customerId: claim.policy.customerId,
          partnerId: dto.assignedGarageId,
          serviceCategory: 'warranty_repair',
          status: 'pending',
          scheduledAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
          totalAmount: 0,
        },
      });
    }

    await this.notificationsService.notify({
      userId: claim.policy.customerId,
      category: 'warranty_status',
      title: 'Warranty claim update',
      body:
        dto.status === 'rejected' && dto.rejectionReason
          ? `Your claim was rejected: ${dto.rejectionReason}`
          : `Your warranty claim is now ${dto.status.replace(/_/g, ' ')}.`,
      relatedEntityType: 'warranty_policy',
      relatedEntityId: claim.policyId,
    });

    return updated;
  }
}
