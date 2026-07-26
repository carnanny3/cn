import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ListingsService } from './listings.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { CreateAdminListingDto } from './dto/create-admin-listing.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('listings')
@Controller('listings')
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  @Public()
  @Get()
  listActive(@Query('make') make?: string) {
    return this.listingsService.listActive(make);
  }

  @Public()
  @Get('compare')
  compare(@Query('ids') ids: string) {
    return this.listingsService.compare((ids ?? '').split(',').filter(Boolean));
  }

  @ApiBearerAuth()
  @Get('mine')
  getMyListings(@CurrentUser() user: JwtPayload) {
    return this.listingsService.getMyListings(user.sub);
  }

  @Public()
  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.listingsService.getOne(id);
  }

  @ApiBearerAuth()
  @Post()
  createPrivateListing(@CurrentUser() user: JwtPayload, @Body() dto: CreateListingDto) {
    return this.listingsService.createPrivateListing(user.sub, dto);
  }

  @ApiBearerAuth()
  @Roles('admin_content', 'admin_super')
  @Post('certified')
  createCertifiedListing(@Body() dto: CreateAdminListingDto) {
    return this.listingsService.createCertifiedListing(dto);
  }
}
