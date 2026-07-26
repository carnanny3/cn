import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { InsuranceService } from './insurance.service';
import { RequestQuoteDto } from './dto/request-quote.dto';
import { PurchaseInsurancePolicyDto } from './dto/purchase-insurance-policy.dto';
import { CreateInsuranceProviderDto } from './dto/create-provider.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('insurance')
@ApiBearerAuth()
@Controller('insurance')
export class InsuranceController {
  constructor(private readonly insuranceService: InsuranceService) {}

  @Public()
  @Get('providers')
  listProviders() {
    return this.insuranceService.listProviders();
  }

  @Roles('admin_partner_manager', 'admin_super')
  @Post('providers')
  createProvider(@Body() dto: CreateInsuranceProviderDto) {
    return this.insuranceService.createProvider(dto);
  }

  @Post('quotes')
  requestQuote(@CurrentUser() user: JwtPayload, @Body() dto: RequestQuoteDto) {
    return this.insuranceService.requestQuote(user.sub, dto);
  }

  @Get('quotes')
  getMyQuotes(@CurrentUser() user: JwtPayload) {
    return this.insuranceService.getMyQuotes(user.sub);
  }

  @Post('policies')
  purchasePolicy(@CurrentUser() user: JwtPayload, @Body() dto: PurchaseInsurancePolicyDto) {
    return this.insuranceService.purchasePolicy(user.sub, dto);
  }

  @Get('policies')
  getMyPolicies(@CurrentUser() user: JwtPayload) {
    return this.insuranceService.getMyPolicies(user.sub);
  }
}
