import { Body, Controller, Get, Param, Patch, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { AdminService } from './admin.service';
import { SupportService } from '../support/support.service';
import { UpdateTicketStatusDto } from '../support/dto/update-ticket-status.dto';
import { AddTicketMessageDto } from '../support/dto/add-ticket-message.dto';
import { WarrantyService } from '../warranty/warranty.service';
import { UpdateClaimStatusDto } from '../warranty/dto/update-claim-status.dto';
import { InsuranceService } from '../insurance/insurance.service';
import { RespondQuoteDto } from '../insurance/dto/respond-quote.dto';
import { RoadsideService } from '../roadside/roadside.service';
import { ConciergeService } from '../concierge/concierge.service';
import { UpdateConciergeOrderDto } from '../concierge/dto/update-order.dto';
import { ListingsService } from '../listings/listings.service';
import { UpdateListingStatusDto } from '../listings/dto/update-listing-status.dto';
import { PaymentsService } from '../payments/payments.service';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

// RBAC groups mirror the PRD's Section 19.1 admin role table. Every role
// group implicitly includes admin_super (full access, per the PRD).
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
const OPS = ['admin_super', 'admin_ops'] as const;
const INSPECTION = ['admin_super', 'admin_inspection'] as const;
const SUPPORT = ['admin_super', 'admin_support'] as const;
const FINANCE = ['admin_super', 'admin_finance'] as const;
const FINANCE_OR_ANALYST = ['admin_super', 'admin_finance', 'admin_analyst'] as const;
const PARTNER_MANAGER = ['admin_super', 'admin_partner_manager'] as const;
const COMPLIANCE = ['admin_super', 'admin_compliance'] as const;

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
    private readonly conciergeService: ConciergeService,
    private readonly listingsService: ListingsService,
    private readonly paymentsService: PaymentsService,
    private readonly auditLog: AuditLogService,
  ) {}

  @Get('summary')
  summary() {
    return this.adminService.dashboardSummary();
  }

  @Roles(...SUPPORT)
  @Get('support-tickets')
  listSupportTickets(@Query('status') status?: string) {
    return this.supportService.listAllTickets(status);
  }

  @Roles(...SUPPORT)
  @Get('support-tickets/:id')
  getSupportTicket(@Param('id') id: string) {
    return this.supportService.getTicket(null, id);
  }

  @Roles(...SUPPORT)
  @Post('support-tickets/:id/messages')
  replyToTicket(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: AddTicketMessageDto) {
    return this.supportService.addMessage(user.sub, user.role, id, dto.content);
  }

  @Roles(...SUPPORT)
  @Patch('support-tickets/:id/status')
  async updateTicketStatus(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateTicketStatusDto, @Req() req: Request) {
    const after = await this.supportService.updateStatus(id, dto.status, dto.assignedAdminId);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'support_ticket.status_update',
      entityType: 'SupportTicket',
      entityId: id,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }

  @Roles(...OPS)
  @Get('warranty-claims')
  listWarrantyClaims(@Query('status') status?: string) {
    return this.warrantyService.listAllClaims(status);
  }

  @Roles(...OPS)
  @Get('warranty-claims/:id')
  getWarrantyClaim(@Param('id') id: string) {
    return this.warrantyService.getClaim(null, id);
  }

  @Roles(...OPS)
  @Patch('warranty-claims/:id/status')
  async updateWarrantyClaimStatus(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateClaimStatusDto, @Req() req: Request) {
    const after = await this.warrantyService.updateClaimStatus(id, dto);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'warranty_claim.status_update',
      entityType: 'WarrantyClaim',
      entityId: id,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }

  @Roles(...OPS)
  @Get('insurance-quotes')
  listInsuranceQuotes(@Query('status') status?: string) {
    return this.insuranceService.listAllQuotes(status);
  }

  @Roles(...OPS)
  @Patch('insurance-quotes/:id/respond')
  async respondToQuote(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: RespondQuoteDto, @Req() req: Request) {
    const after = await this.insuranceService.respondToQuote(id, dto);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'insurance_quote.respond',
      entityType: 'InsuranceQuote',
      entityId: id,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }

  @Roles(...OPS)
  @Get('roadside-requests')
  listRoadsideRequests(@Query('status') status?: string) {
    return this.roadsideService.listAllRequests(status);
  }

  @Roles(...OPS)
  @Get('concierge-orders')
  listConciergeOrders(@Query('status') status?: string) {
    return this.conciergeService.listAllOrders(status);
  }

  @Roles(...OPS)
  @Patch('concierge-orders/:id')
  async updateConciergeOrder(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateConciergeOrderDto, @Req() req: Request) {
    const after = await this.conciergeService.updateOrder(id, dto);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'concierge_order.update',
      entityType: 'ConciergeOrder',
      entityId: id,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }

  @Roles(...SUPPORT)
  @Get('users')
  listUsers() {
    return this.adminService.listUsers();
  }

  @Roles(...SUPPORT, 'admin_ops')
  @Get('vehicles')
  listVehicles() {
    return this.adminService.listVehicles();
  }

  @Roles(...PARTNER_MANAGER)
  @Get('partners')
  listPartners(@Query('status') status?: string) {
    return this.adminService.listPartners(status);
  }

  @Roles(...INSPECTION)
  @Get('inspections')
  listInspections(@Query('status') status?: string) {
    return this.adminService.listInspections(status);
  }

  @Roles(...OPS)
  @Get('bookings')
  listBookings(@Query('status') status?: string) {
    return this.adminService.listBookings(status);
  }

  @Roles(...OPS)
  @Get('listings')
  listListings(@Query('status') status?: string) {
    return this.listingsService.listAll(status);
  }

  @Roles(...OPS)
  @Patch('listings/:id/status')
  async updateListingStatus(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateListingStatusDto, @Req() req: Request) {
    const after = await this.listingsService.updateStatus(id, dto.status);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'listing.status_update',
      entityType: 'VehicleListing',
      entityId: id,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }

  @Roles(...FINANCE)
  @Get('payments')
  listPayments(@Query('status') status?: string) {
    return this.paymentsService.listAll(status);
  }

  @Roles(...FINANCE_OR_ANALYST)
  @Get('reports/revenue')
  revenueReport() {
    return this.paymentsService.revenueSummary();
  }

  @Roles(...COMPLIANCE)
  @Get('audit-log')
  listAuditLog(@Query('entityType') entityType?: string) {
    return this.auditLog.list(entityType);
  }
}
