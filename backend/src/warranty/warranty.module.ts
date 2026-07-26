import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { WarrantyService } from './warranty.service';
import { WarrantyController } from './warranty.controller';

@Module({
  imports: [NotificationsModule],
  controllers: [WarrantyController],
  providers: [WarrantyService],
  exports: [WarrantyService],
})
export class WarrantyModule {}
