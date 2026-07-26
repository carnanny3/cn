import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('bookings')
@ApiBearerAuth()
@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateBookingDto) {
    return this.bookingsService.create(user.sub, dto);
  }

  @Get()
  findAll(@CurrentUser() user: JwtPayload) {
    return this.bookingsService.findAllForUser(user.sub);
  }

  @Roles('partner')
  @Get('partner/mine')
  findAllForPartner(@CurrentUser() user: JwtPayload) {
    return this.bookingsService.findAllForPartner(user.sub);
  }

  @Get(':id')
  findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.bookingsService.findOne(user.sub, id);
  }

  @Post(':id/cancel')
  cancel(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.bookingsService.cancel(user.sub, id);
  }

  @Roles('partner', 'admin_ops', 'admin_super')
  @Patch(':id/status')
  updateStatus(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateBookingStatusDto) {
    return this.bookingsService.updateStatus(id, dto.status, user.sub, user.role);
  }
}
