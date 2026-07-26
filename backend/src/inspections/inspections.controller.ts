import { Body, Controller, Get, Param, Patch, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { InspectionsService } from './inspections.service';
import { BookInspectionDto } from './dto/book-inspection.dto';
import { SubmitCheckpointsDto } from './dto/submit-checkpoints.dto';
import { UpdateInspectionStatusDto } from './dto/update-inspection-status.dto';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('inspections')
@ApiBearerAuth()
@Controller('inspections')
export class InspectionsController {
  constructor(
    private readonly inspectionsService: InspectionsService,
    private readonly auditLog: AuditLogService,
  ) {}

  @Post()
  book(@CurrentUser() user: JwtPayload, @Body() dto: BookInspectionDto) {
    return this.inspectionsService.book(user.sub, dto);
  }

  @Roles('partner')
  @Get('assigned/mine')
  findAllForPartner(@CurrentUser() user: JwtPayload) {
    return this.inspectionsService.findAllForPartner(user.sub);
  }

  @Get(':id')
  async findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.inspectionsService.assertRequester(user.sub, id);
    return this.inspectionsService.findOne(id);
  }

  @Get(':id/report')
  async getReport(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    await this.inspectionsService.assertRequester(user.sub, id);
    return this.inspectionsService.getReport(id);
  }

  @Roles('admin_inspection', 'admin_super')
  @Patch(':id/assign/:inspectorId')
  assignInspector(@Param('id') id: string, @Param('inspectorId') inspectorId: string) {
    return this.inspectionsService.assignInspector(id, inspectorId);
  }

  @Roles('partner', 'admin_inspection', 'admin_super')
  @Patch(':id/status')
  updateStatus(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateInspectionStatusDto) {
    return this.inspectionsService.updateStatus(id, dto.status, user.sub, user.role);
  }

  @Roles('partner', 'admin_inspection', 'admin_super')
  @Post(':id/checkpoints')
  submitCheckpoints(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: SubmitCheckpointsDto) {
    return this.inspectionsService.submitCheckpoints(id, dto, user.sub, user.role);
  }

  @Roles('admin_inspection', 'admin_super')
  @Patch(':id/approve-report')
  async approveReport(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Req() req: Request) {
    const after = await this.inspectionsService.approveReport(id);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'inspection_report.approve',
      entityType: 'Inspection',
      entityId: id,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }
}
