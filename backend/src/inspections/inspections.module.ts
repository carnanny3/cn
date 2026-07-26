import { Module } from '@nestjs/common';
import { PartnersModule } from '../partners/partners.module';
import { InspectionsService } from './inspections.service';
import { InspectionsController } from './inspections.controller';

@Module({
  imports: [PartnersModule],
  controllers: [InspectionsController],
  providers: [InspectionsService],
  exports: [InspectionsService],
})
export class InspectionsModule {}
