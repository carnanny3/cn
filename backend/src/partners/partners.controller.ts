import { Body, Controller, Get, Param, Patch, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { PartnersService } from './partners.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { RegisterPartnerDto } from './dto/register-partner.dto';
import { RegisterPartnerAccountDto } from './dto/register-partner-account.dto';
import { UpdatePartnerProfileDto } from './dto/update-partner-profile.dto';
import { UpdatePartnerServiceDto } from './dto/update-partner-service.dto';
import { AddPartnerServiceDto } from './dto/add-partner-service.dto';
import { SearchPartnersDto } from './dto/search-partners.dto';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@ApiTags('partners')
@Controller('partners')
export class PartnersController {
  constructor(
    private readonly partnersService: PartnersService,
    private readonly auditLog: AuditLogService,
  ) {}

  // Admin-managed catalog entry (no login account) — used for partner types
  // that don't have a self-serve portal yet (insurer, warranty_provider, etc).
  @Public()
  @Post('register')
  register(@Body() dto: RegisterPartnerDto) {
    return this.partnersService.register(dto);
  }

  @Public()
  @Post('register-account')
  registerAccount(@Body() dto: RegisterPartnerAccountDto) {
    return this.partnersService.registerAccount(dto);
  }

  @Public()
  @Get('search')
  search(@Query() query: SearchPartnersDto) {
    return this.partnersService.search(query);
  }

  @ApiBearerAuth()
  @Roles('partner')
  @Get('me')
  getMyProfile(@CurrentUser() user: JwtPayload) {
    return this.partnersService.findMyProfile(user.sub);
  }

  @ApiBearerAuth()
  @Roles('partner')
  @Patch('me')
  updateMyProfile(@CurrentUser() user: JwtPayload, @Body() dto: UpdatePartnerProfileDto) {
    return this.partnersService.updateMyProfile(user.sub, dto);
  }

  @ApiBearerAuth()
  @Roles('partner')
  @Post('me/services')
  addMyService(@CurrentUser() user: JwtPayload, @Body() dto: AddPartnerServiceDto) {
    return this.partnersService.addMyService(user.sub, dto);
  }

  @ApiBearerAuth()
  @Roles('partner')
  @Patch('me/services/:serviceId')
  updateMyService(
    @CurrentUser() user: JwtPayload,
    @Param('serviceId') serviceId: string,
    @Body() dto: UpdatePartnerServiceDto,
  ) {
    return this.partnersService.updateMyService(user.sub, serviceId, dto);
  }

  @ApiBearerAuth()
  @Roles('partner')
  @Get('me/earnings')
  getMyEarnings(@CurrentUser() user: JwtPayload) {
    return this.partnersService.getMyEarnings(user.sub);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.partnersService.findOne(id);
  }

  // Admin-side manual catalog management (e.g. onboarding a partner type
  // that doesn't have a self-serve portal yet). Self-serve partners manage
  // their own catalog via POST/PATCH /partners/me/services above.
  @ApiBearerAuth()
  @Roles('admin_partner_manager', 'admin_super')
  @Post(':id/services')
  addService(@Param('id') id: string, @Body() dto: AddPartnerServiceDto) {
    return this.partnersService.addService(id, dto);
  }

  @ApiBearerAuth()
  @Roles('admin_partner_manager', 'admin_super')
  @Patch(':id/verify')
  async verify(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: { approve: boolean; rejectionReason?: string },
    @Req() req: Request,
  ) {
    const after = await this.partnersService.verify(id, body.approve, body.rejectionReason);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: body.approve ? 'partner.approve' : 'partner.reject',
      entityType: 'Partner',
      entityId: id,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }
}
