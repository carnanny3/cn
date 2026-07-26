import { Module } from '@nestjs/common';
import { PartnersModule } from '../partners/partners.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';

@Module({
  imports: [PartnersModule, NotificationsModule],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
