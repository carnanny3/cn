import { Body, Controller, Get, Param, Patch, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { PromotionsService } from './promotions.service';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

const CONTENT_ROLES = ['admin_content', 'admin_super'] as const;

@ApiTags('promotions')
@ApiBearerAuth()
@Controller('promotions')
export class PromotionsController {
  constructor(
    private readonly promotionsService: PromotionsService,
    private readonly auditLog: AuditLogService,
  ) {}

  @Get('validate')
  validate(@Query('code') code: string) {
    return this.promotionsService.validate(code ?? '');
  }

  @Roles(...CONTENT_ROLES)
  @Get()
  listAll() {
    return this.promotionsService.listAll();
  }

  @Roles(...CONTENT_ROLES)
  @Post()
  async create(@CurrentUser() user: JwtPayload, @Body() dto: CreateCouponDto, @Req() req: Request) {
    const coupon = await this.promotionsService.create(dto);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'coupon.create',
      entityType: 'Coupon',
      entityId: coupon.id,
      afterState: coupon,
      ipAddress: req.ip,
    });
    return coupon;
  }

  @Roles(...CONTENT_ROLES)
  @Patch(':id')
  async update(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateCouponDto, @Req() req: Request) {
    const before = await this.promotionsService.getOne(id);
    const after = await this.promotionsService.update(id, dto);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'coupon.update',
      entityType: 'Coupon',
      entityId: id,
      beforeState: before,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }
}
