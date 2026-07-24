import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { Roles } from '../common/decorators/roles.decorator';

const ANY_ADMIN = [
  'admin_super',
  'admin_ops',
  'admin_inspection',
  'admin_support',
  'admin_finance',
  'admin_partner_manager',
  'admin_content',
  'admin_compliance',
  'admin_analyst',
] as const;

@ApiTags('admin')
@ApiBearerAuth()
@Roles(...ANY_ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('summary')
  summary() {
    return this.adminService.dashboardSummary();
  }

  @Get('users')
  listUsers() {
    return this.adminService.listUsers();
  }

  @Get('vehicles')
  listVehicles() {
    return this.adminService.listVehicles();
  }

  @Get('partners')
  listPartners(@Query('status') status?: string) {
    return this.adminService.listPartners(status);
  }

  @Get('inspections')
  listInspections(@Query('status') status?: string) {
    return this.adminService.listInspections(status);
  }

  @Get('bookings')
  listBookings(@Query('status') status?: string) {
    return this.adminService.listBookings(status);
  }
}
