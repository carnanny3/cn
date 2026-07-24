import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PartnersService } from './partners.service';
import { RegisterPartnerDto } from './dto/register-partner.dto';
import { AddPartnerServiceDto } from './dto/add-partner-service.dto';
import { SearchPartnersDto } from './dto/search-partners.dto';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('partners')
@Controller('partners')
export class PartnersController {
  constructor(private readonly partnersService: PartnersService) {}

  @Public()
  @Post('register')
  register(@Body() dto: RegisterPartnerDto) {
    return this.partnersService.register(dto);
  }

  @Public()
  @Get('search')
  search(@Query() query: SearchPartnersDto) {
    return this.partnersService.search(query);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.partnersService.findOne(id);
  }

  // Interim: gated to admin roles because there is no partner-authenticated
  // session mechanism yet (Partner is not linked to a User/JWT identity in
  // this MVP schema). Once partner login exists, this should be scoped to
  // "the authenticated partner managing their own catalog", not admin-only.
  @ApiBearerAuth()
  @Roles('admin_partner_manager', 'admin_super')
  @Post(':id/services')
  addService(@Param('id') id: string, @Body() dto: AddPartnerServiceDto) {
    return this.partnersService.addService(id, dto);
  }

  @ApiBearerAuth()
  @Roles('admin_partner_manager', 'admin_super')
  @Patch(':id/verify')
  verify(@Param('id') id: string, @Body() body: { approve: boolean; rejectionReason?: string }) {
    return this.partnersService.verify(id, body.approve, body.rejectionReason);
  }
}
