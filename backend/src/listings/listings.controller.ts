import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { ListingsService } from './listings.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { CreateAdminListingDto } from './dto/create-admin-listing.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Public } from '../common/decorators/public.decorator';
import { MAX_LISTING_PHOTOS } from '../storage/storage.service';

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

  /**
   * Photos are uploaded before the listing exists, so the client holds the
   * returned URLs and submits them with POST /listings. An abandoned form
   * therefore leaves orphaned objects — acceptable for now, swept later.
   */
  @ApiBearerAuth()
  @Post('photos')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('files', MAX_LISTING_PHOTOS, { limits: { fileSize: 12 * 1024 * 1024 } }))
  uploadPhotos(@CurrentUser() user: JwtPayload, @UploadedFiles() files?: Express.Multer.File[]) {
    if (!files || files.length === 0) {
      throw new BadRequestException({ code: 'FILES_REQUIRED', message: 'Attach at least one photo.' });
    }
    return this.listingsService.uploadPhotos(user.sub, files);
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
