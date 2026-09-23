import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiQuery, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { LogbookService } from './logbook.service';
import { CreateRecordDto } from './dto/create-record.dto';
import { UpdateRecordDto } from './dto/update-record.dto';
import { CreateFuelEntryDto } from './dto/create-fuel-entry.dto';
import { UpdateFuelEntryDto } from './dto/update-fuel-entry.dto';
import { CreateReminderDto } from './dto/create-reminder.dto';
import { UpdateReminderDto } from './dto/update-reminder.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

/** The owner logbook, nested under the vehicle it belongs to. */
@ApiTags('logbook')
@ApiBearerAuth()
@Controller('vehicles/:vehicleId')
export class LogbookController {
  constructor(private readonly logbook: LogbookService) {}

  // ---------- Records ----------

  @Get('records')
  listRecords(@CurrentUser() user: JwtPayload, @Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.logbook.listRecords(user.sub, vehicleId);
  }

  @Post('records')
  createRecord(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Body() dto: CreateRecordDto,
  ) {
    return this.logbook.createRecord(user.sub, vehicleId, dto);
  }

  @Patch('records/:recordId')
  updateRecord(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('recordId', ParseUUIDPipe) recordId: string,
    @Body() dto: UpdateRecordDto,
  ) {
    return this.logbook.updateRecord(user.sub, vehicleId, recordId, dto);
  }

  @Delete('records/:recordId')
  deleteRecord(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('recordId', ParseUUIDPipe) recordId: string,
  ) {
    return this.logbook.deleteRecord(user.sub, vehicleId, recordId);
  }

  // Same two-level size cap as vehicle documents: multer's limit sits above
  // StorageService's so normal overages get the readable message.
  @Post('records/:recordId/photos')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 16 * 1024 * 1024 } }))
  addRecordPhoto(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('recordId', ParseUUIDPipe) recordId: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException({ code: 'FILE_REQUIRED', message: 'Attach a file to upload.' });
    }
    return this.logbook.addRecordPhoto(user.sub, vehicleId, recordId, file);
  }

  @Delete('records/:recordId/photos/:photoId')
  deleteRecordPhoto(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('recordId', ParseUUIDPipe) recordId: string,
    @Param('photoId', ParseUUIDPipe) photoId: string,
  ) {
    return this.logbook.deleteRecordPhoto(user.sub, vehicleId, recordId, photoId);
  }

  // ---------- Fuel ----------

  @Get('fuel')
  listFuel(@CurrentUser() user: JwtPayload, @Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.logbook.listFuel(user.sub, vehicleId);
  }

  @Post('fuel')
  createFuel(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Body() dto: CreateFuelEntryDto,
  ) {
    return this.logbook.createFuel(user.sub, vehicleId, dto);
  }

  @Patch('fuel/:entryId')
  updateFuel(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('entryId', ParseUUIDPipe) entryId: string,
    @Body() dto: UpdateFuelEntryDto,
  ) {
    return this.logbook.updateFuel(user.sub, vehicleId, entryId, dto);
  }

  @Delete('fuel/:entryId')
  deleteFuel(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('entryId', ParseUUIDPipe) entryId: string,
  ) {
    return this.logbook.deleteFuel(user.sub, vehicleId, entryId);
  }

  // ---------- Reminders ----------

  @Get('reminders')
  listReminders(@CurrentUser() user: JwtPayload, @Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.logbook.listReminders(user.sub, vehicleId);
  }

  @Post('reminders')
  createReminder(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Body() dto: CreateReminderDto,
  ) {
    return this.logbook.createReminder(user.sub, vehicleId, dto);
  }

  @Patch('reminders/:reminderId')
  updateReminder(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('reminderId', ParseUUIDPipe) reminderId: string,
    @Body() dto: UpdateReminderDto,
  ) {
    return this.logbook.updateReminder(user.sub, vehicleId, reminderId, dto);
  }

  @Post('reminders/:reminderId/complete')
  completeReminder(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('reminderId', ParseUUIDPipe) reminderId: string,
  ) {
    return this.logbook.completeReminder(user.sub, vehicleId, reminderId);
  }

  @Delete('reminders/:reminderId')
  deleteReminder(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Param('reminderId', ParseUUIDPipe) reminderId: string,
  ) {
    return this.logbook.deleteReminder(user.sub, vehicleId, reminderId);
  }

  // ---------- Summary & export ----------

  @Get('logbook-summary')
  summary(@CurrentUser() user: JwtPayload, @Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.logbook.summary(user.sub, vehicleId);
  }

  @Get('export.csv')
  @ApiQuery({ name: 'kind', enum: ['records', 'fuel'] })
  async exportCsv(
    @CurrentUser() user: JwtPayload,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Query('kind') kind: string,
    @Res() res: Response,
  ) {
    if (kind !== 'records' && kind !== 'fuel') {
      throw new BadRequestException({ code: 'INVALID_EXPORT_KIND', message: 'kind must be "records" or "fuel".' });
    }
    const { filename, csv } = await this.logbook.exportCsv(user.sub, vehicleId, kind);
    res.attachment(filename).type('text/csv; charset=utf-8').send(csv);
  }
}

/** Cross-vehicle views that don't belong to a single vehicle's route. */
@ApiTags('logbook')
@ApiBearerAuth()
@Controller('logbook')
export class LogbookOverviewController {
  constructor(private readonly logbook: LogbookService) {}

  @Get('attention')
  attention(@CurrentUser() user: JwtPayload) {
    return this.logbook.attention(user.sub);
  }
}
