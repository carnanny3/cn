import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { InspectionsService } from './inspections.service';
import { BookInspectionDto } from './dto/book-inspection.dto';
import { SubmitCheckpointsDto } from './dto/submit-checkpoints.dto';
import { UpdateInspectionStatusDto } from './dto/update-inspection-status.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('inspections')
@ApiBearerAuth()
@Controller('inspections')
export class InspectionsController {
  constructor(private readonly inspectionsService: InspectionsService) {}

  @Post()
  book(@CurrentUser() user: JwtPayload, @Body() dto: BookInspectionDto) {
    return this.inspectionsService.book(user.sub, dto);
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
  updateStatus(@Param('id') id: string, @Body() dto: UpdateInspectionStatusDto) {
    return this.inspectionsService.updateStatus(id, dto.status);
  }

  @Roles('partner', 'admin_inspection', 'admin_super')
  @Post(':id/checkpoints')
  submitCheckpoints(@Param('id') id: string, @Body() dto: SubmitCheckpointsDto) {
    return this.inspectionsService.submitCheckpoints(id, dto);
  }

  @Roles('admin_inspection', 'admin_super')
  @Patch(':id/approve-report')
  approveReport(@Param('id') id: string) {
    return this.inspectionsService.approveReport(id);
  }
}
