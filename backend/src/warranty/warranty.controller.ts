import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { WarrantyService } from './warranty.service';
import { CreateWarrantyPlanDto } from './dto/create-warranty-plan.dto';
import { PurchaseWarrantyPolicyDto } from './dto/purchase-warranty-policy.dto';
import { SubmitClaimDto } from './dto/submit-claim.dto';
import { UpdateClaimStatusDto } from './dto/update-claim-status.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('warranty')
@ApiBearerAuth()
@Controller('warranty')
export class WarrantyController {
  constructor(private readonly warrantyService: WarrantyService) {}

  @Public()
  @Get('plans')
  listPlans(@Query('vehicleId') vehicleId?: string) {
    return this.warrantyService.listPlans(vehicleId);
  }

  @Roles('admin_partner_manager', 'admin_super')
  @Post('plans')
  createPlan(@Body() dto: CreateWarrantyPlanDto) {
    return this.warrantyService.createPlan(dto);
  }

  @Post('policies')
  purchasePolicy(@CurrentUser() user: JwtPayload, @Body() dto: PurchaseWarrantyPolicyDto) {
    return this.warrantyService.purchasePolicy(user.sub, dto);
  }

  @Get('policies')
  getMyPolicies(@CurrentUser() user: JwtPayload) {
    return this.warrantyService.getMyPolicies(user.sub);
  }

  @Post('claims')
  submitClaim(@CurrentUser() user: JwtPayload, @Body() dto: SubmitClaimDto) {
    return this.warrantyService.submitClaim(user.sub, dto);
  }

  @Get('claims')
  getMyClaims(@CurrentUser() user: JwtPayload) {
    return this.warrantyService.getMyClaims(user.sub);
  }

  @Get('claims/:id')
  getClaim(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.warrantyService.getClaim(user.sub, id);
  }
}
