import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuditLogService {
  constructor(private readonly prisma: PrismaService) {}

  log(params: {
    adminUserId: string;
    action: string;
    entityType: string;
    entityId: string;
    beforeState?: unknown;
    afterState?: unknown;
    ipAddress?: string;
  }) {
    return this.prisma.adminAuditLog.create({
      data: {
        adminUserId: params.adminUserId,
        action: params.action,
        entityType: params.entityType,
        entityId: params.entityId,
        beforeState: params.beforeState === undefined ? undefined : (params.beforeState as never),
        afterState: params.afterState === undefined ? undefined : (params.afterState as never),
        ipAddress: params.ipAddress,
      },
    });
  }

  list(entityType?: string) {
    return this.prisma.adminAuditLog.findMany({
      where: entityType ? { entityType } : undefined,
      orderBy: { createdAt: 'desc' },
      take: 500,
    });
  }
}
