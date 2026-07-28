import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { AddDocumentDto } from './dto/add-document.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@ApiTags('vehicles')
@ApiBearerAuth()
@Controller('vehicles')
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateVehicleDto) {
    return this.vehiclesService.create(user.sub, dto);
  }

  @Get()
  findAll(@CurrentUser() user: JwtPayload) {
    return this.vehiclesService.findAllForUser(user.sub);
  }

  @Get(':id')
  findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.vehiclesService.findOneForUser(user.sub, id);
  }

  @Patch(':id')
  update(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateVehicleDto) {
    return this.vehiclesService.update(user.sub, id, dto);
  }

  @Get(':id/health-score')
  getHealthScore(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.vehiclesService.getHealthScore(user.sub, id);
  }

  // Multer's own cap sits above StorageService's so ordinary overages get the
  // service's readable message, while anything absurd is cut off before it's
  // ever buffered in full.
  @Post(':id/documents')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 16 * 1024 * 1024 } }))
  addDocument(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: AddDocumentDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException({ code: 'FILE_REQUIRED', message: 'Attach a file to upload.' });
    }
    return this.vehiclesService.addDocument(user.sub, id, dto, file);
  }

  @Get(':id/documents')
  listDocuments(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.vehiclesService.listDocuments(user.sub, id);
  }

  @Post(':id/photo')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 12 * 1024 * 1024 } }))
  uploadPhoto(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException({ code: 'FILE_REQUIRED', message: 'Attach a file to upload.' });
    }
    return this.vehiclesService.setPrimaryPhoto(user.sub, id, file);
  }
}
