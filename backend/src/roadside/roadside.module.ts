import { Module } from '@nestjs/common';
import { PartnersModule } from '../partners/partners.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { RoadsideService } from './roadside.service';
import { RoadsideController } from './roadside.controller';

@Module({
  imports: [PartnersModule, NotificationsModule],
  controllers: [RoadsideController],
  providers: [RoadsideService],
  exports: [RoadsideService],
})
export class RoadsideModule {}
