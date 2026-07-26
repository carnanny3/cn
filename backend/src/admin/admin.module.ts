import { Module } from '@nestjs/common';
import { SupportModule } from '../support/support.module';
import { WarrantyModule } from '../warranty/warranty.module';
import { InsuranceModule } from '../insurance/insurance.module';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';

@Module({
  imports: [SupportModule, WarrantyModule, InsuranceModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
