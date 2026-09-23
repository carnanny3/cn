import { Module } from '@nestjs/common';
import { LogbookController, LogbookOverviewController } from './logbook.controller';
import { LogbookService } from './logbook.service';
import { StorageModule } from '../storage/storage.module';
import { VehiclesModule } from '../vehicles/vehicles.module';

@Module({
  imports: [StorageModule, VehiclesModule],
  controllers: [LogbookController, LogbookOverviewController],
  providers: [LogbookService],
})
export class LogbookModule {}
