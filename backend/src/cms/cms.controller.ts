import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { CmsService } from './cms.service';
import { CreateCmsContentDto } from './dto/create-cms-content.dto';
import { UpdateCmsContentDto } from './dto/update-cms-content.dto';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Public } from '../common/decorators/public.decorator';

const CONTENT_ROLES = ['admin_content', 'admin_super'] as const;

@ApiTags('cms')
@Controller('cms')
export class CmsController {
  constructor(
    private readonly cmsService: CmsService,
    private readonly auditLog: AuditLogService,
  ) {}

  @Public()
  @Get()
  list(@Query('section') section?: string, @Query('locale') locale?: string) {
    return this.cmsService.list(section, locale);
  }

  @Public()
  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.cmsService.getOne(id);
  }

  @ApiBearerAuth()
  @Roles(...CONTENT_ROLES)
  @Post()
  async create(@CurrentUser() user: JwtPayload, @Body() dto: CreateCmsContentDto, @Req() req: Request) {
    const content = await this.cmsService.create(dto);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'cms.create',
      entityType: 'CmsContent',
      entityId: content.id,
      afterState: content,
      ipAddress: req.ip,
    });
    return content;
  }

  @ApiBearerAuth()
  @Roles(...CONTENT_ROLES)
  @Patch(':id')
  async update(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateCmsContentDto, @Req() req: Request) {
    const before = await this.cmsService.getOne(id);
    const after = await this.cmsService.update(id, dto);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'cms.update',
      entityType: 'CmsContent',
      entityId: id,
      beforeState: before,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }

  @ApiBearerAuth()
  @Roles(...CONTENT_ROLES)
  @Delete(':id')
  async remove(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Req() req: Request) {
    const before = await this.cmsService.getOne(id);
    const result = await this.cmsService.remove(id);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'cms.delete',
      entityType: 'CmsContent',
      entityId: id,
      beforeState: before,
      ipAddress: req.ip,
    });
    return result;
  }
}
