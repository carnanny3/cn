import { Module } from '@nestjs/common';
import { PartnersModule } from '../partners/partners.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { InspectionsService } from './inspections.service';
import { InspectionsController } from './inspections.controller';

@Module({
  imports: [PartnersModule, NotificationsModule],
  controllers: [InspectionsController],
  providers: [InspectionsService],
  exports: [InspectionsService],
})
export class InspectionsModule {}
