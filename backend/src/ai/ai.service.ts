import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SendMessageDto } from './dto/send-message.dto';
import { applySafetyRules } from './ai-safety.util';

/**
 * Retrieval + response generation. This is a genuine rule-based
 * implementation of the RAG contract described in the product spec
 * (resolve permission-scoped vehicle context, retrieve structured facts,
 * generate a grounded response, apply the safety layer) — it does not call
 * an external LLM. To upgrade to a real LLM: keep `retrieveContext()`
 * exactly as-is and replace `draftResponse()` with a call to your model of
 * choice, passing the same retrieved context as grounding/RAG input so the
 * model reasons over real data instead of hallucinating it.
 */
@Injectable()
export class AiService {
  constructor(private readonly prisma: PrismaService) {}

  async startConversation(userId: string, vehicleId?: string) {
    if (vehicleId) {
      await this.assertVehicleAccess(userId, vehicleId);
    }
    return this.prisma.aiConversation.create({
      data: { userId, vehicleId },
    });
  }

  async getConversation(userId: string, conversationId: string) {
    const conversation = await this.prisma.aiConversation.findUnique({
      where: { id: conversationId },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!conversation || conversation.userId !== userId) {
      throw new ForbiddenException({ code: 'NOT_CONVERSATION_OWNER', message: 'You do not have access to this conversation.' });
    }
    return conversation;
  }

  async sendMessage(userId: string, conversationId: string, dto: SendMessageDto) {
    const conversation = await this.getConversation(userId, conversationId);

    await this.prisma.aiMessage.create({
      data: { conversationId, role: 'user', content: dto.content },
    });

    const vehicleId = dto.vehicleId ?? conversation.vehicleId ?? undefined;
    if (vehicleId) await this.assertVehicleAccess(userId, vehicleId);

    const context = await this.retrieveContext(userId, vehicleId);
    const { draft, referencedEntity } = this.draftResponse(dto.content, context);
    const finalResponse = applySafetyRules(dto.content, draft, context.hasCriticalDefect);

    const message = await this.prisma.aiMessage.create({
      data: {
        conversationId,
        role: 'assistant',
        content: finalResponse,
        referencedEntityType: referencedEntity?.type,
        referencedEntityId: referencedEntity?.id,
      },
    });

    return message;
  }

  private async assertVehicleAccess(userId: string, vehicleId: string) {
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

  private async retrieveContext(userId: string, vehicleId?: string) {
    if (!vehicleId) {
      return {
        vehicle: null,
        latestReport: null,
        insuranceDoc: null,
        registrationDoc: null,
        hasCriticalDefect: false,
      };
    }

    const vehicle = await this.prisma.vehicle.findUnique({ where: { id: vehicleId } });
    const latestReport = await this.prisma.inspectionReport.findFirst({
      where: { inspection: { vehicleId } },
      orderBy: { generatedAt: 'desc' },
    });
    const documents = await this.prisma.vehicleDocument.findMany({ where: { vehicleId } });
    const insuranceDoc = documents.find((d) => d.type === 'insurance') ?? null;
    const registrationDoc = documents.find((d) => d.type === 'registration') ?? null;

    return {
      vehicle,
      latestReport,
      insuranceDoc,
      registrationDoc,
      hasCriticalDefect: (latestReport?.criticalDefectCount ?? 0) > 0,
    };
  }

  private draftResponse(
    message: string,
    context: Awaited<ReturnType<AiService['retrieveContext']>>,
  ): { draft: string; referencedEntity?: { type: string; id: string } } {
    const lower = message.toLowerCase();
    const vehicleLabel = context.vehicle
      ? `your ${context.vehicle.year} ${context.vehicle.make} ${context.vehicle.model}`
      : 'your vehicle';

    if (lower.includes('insurance')) {
      if (!context.insuranceDoc) {
        return { draft: `I don't see an insurance document on file for ${vehicleLabel}. Add one from the vehicle's Documents tab so I can track its expiry for you.` };
      }
      const expiry = context.insuranceDoc.expiryDate;
      return {
        draft: expiry
          ? `${vehicleLabel}'s insurance ${expiry > new Date() ? 'is active and expires' : 'expired'} on ${expiry.toDateString()}.`
          : `${vehicleLabel} has an insurance document on file, but no expiry date was recorded.`,
        referencedEntity: { type: 'vehicle_document', id: context.insuranceDoc.id },
      };
    }

    if (lower.includes('registration')) {
      if (!context.registrationDoc) {
        return { draft: `I don't see a registration document on file for ${vehicleLabel}. Add one from the vehicle's Documents tab.` };
      }
      const expiry = context.registrationDoc.expiryDate;
      return {
        draft: expiry
          ? `${vehicleLabel}'s registration ${expiry > new Date() ? 'is active and expires' : 'expired'} on ${expiry.toDateString()}.`
          : `${vehicleLabel} has a registration document on file, but no expiry date was recorded.`,
        referencedEntity: { type: 'vehicle_document', id: context.registrationDoc.id },
      };
    }

    if (lower.includes('buy') || lower.includes('report') || lower.includes('inspection')) {
      if (!context.latestReport) {
        return { draft: `${vehicleLabel} doesn't have an inspection report yet. Book an inspection and I can walk you through the results once it's ready.` };
      }
      return {
        draft: context.latestReport.aiSummary ?? `${vehicleLabel} scored ${context.latestReport.overallScore}/10 in its latest inspection.`,
        referencedEntity: { type: 'inspection', id: context.latestReport.inspectionId },
      };
    }

    if (lower.includes('service') || lower.includes('maintenance')) {
      return {
        draft: context.vehicle
          ? `I can help you book a service for ${vehicleLabel}. Open the Services tab to see nearby verified garages, or tell me what's wrong and I'll suggest what to book.`
          : `Add a vehicle to your garage first, and I'll be able to track its service history and recommend what's due.`,
      };
    }

    return {
      draft: `I can help with questions about ${vehicleLabel}'s service schedule, warranty, insurance, or inspection report. What would you like to know?`,
    };
  }
}
