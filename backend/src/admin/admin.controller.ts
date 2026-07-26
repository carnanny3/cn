import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { SupportService } from '../support/support.service';
import { UpdateTicketStatusDto } from '../support/dto/update-ticket-status.dto';
import { AddTicketMessageDto } from '../support/dto/add-ticket-message.dto';
import { WarrantyService } from '../warranty/warranty.service';
import { UpdateClaimStatusDto } from '../warranty/dto/update-claim-status.dto';
import { InsuranceService } from '../insurance/insurance.service';
import { RespondQuoteDto } from '../insurance/dto/respond-quote.dto';
import { RoadsideService } from '../roadside/roadside.service';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
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
  constructor(
    private readonly adminService: AdminService,
    private readonly supportService: SupportService,
    private readonly warrantyService: WarrantyService,
    private readonly insuranceService: InsuranceService,
    private readonly roadsideService: RoadsideService,
  ) {}

  @Get('summary')
  summary() {
    return this.adminService.dashboardSummary();
  }

  @Get('support-tickets')
  listSupportTickets(@Query('status') status?: string) {
    return this.supportService.listAllTickets(status);
  }

  @Get('support-tickets/:id')
  getSupportTicket(@Param('id') id: string) {
    return this.supportService.getTicket(null, id);
  }

  @Post('support-tickets/:id/messages')
  replyToTicket(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: AddTicketMessageDto) {
    return this.supportService.addMessage(user.sub, user.role, id, dto.content);
  }

  @Patch('support-tickets/:id/status')
  updateTicketStatus(@Param('id') id: string, @Body() dto: UpdateTicketStatusDto) {
    return this.supportService.updateStatus(id, dto.status, dto.assignedAdminId);
  }

  @Get('warranty-claims')
  listWarrantyClaims(@Query('status') status?: string) {
    return this.warrantyService.listAllClaims(status);
  }

  @Get('warranty-claims/:id')
  getWarrantyClaim(@Param('id') id: string) {
    return this.warrantyService.getClaim(null, id);
  }

  @Patch('warranty-claims/:id/status')
  updateWarrantyClaimStatus(@Param('id') id: string, @Body() dto: UpdateClaimStatusDto) {
    return this.warrantyService.updateClaimStatus(id, dto);
  }

  @Get('insurance-quotes')
  listInsuranceQuotes(@Query('status') status?: string) {
    return this.insuranceService.listAllQuotes(status);
  }

  @Patch('insurance-quotes/:id/respond')
  respondToQuote(@Param('id') id: string, @Body() dto: RespondQuoteDto) {
    return this.insuranceService.respondToQuote(id, dto);
  }

  @Get('roadside-requests')
  listRoadsideRequests(@Query('status') status?: string) {
    return this.roadsideService.listAllRequests(status);
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
