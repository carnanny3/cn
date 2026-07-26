import { Module } from '@nestjs/common';
import { SupportModule } from '../support/support.module';
import { WarrantyModule } from '../warranty/warranty.module';
import { InsuranceModule } from '../insurance/insurance.module';
import { RoadsideModule } from '../roadside/roadside.module';
import { ConciergeModule } from '../concierge/concierge.module';
import { ListingsModule } from '../listings/listings.module';
import { PaymentsModule } from '../payments/payments.module';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';

@Module({
  imports: [
    SupportModule,
    WarrantyModule,
    InsuranceModule,
    RoadsideModule,
    ConciergeModule,
    ListingsModule,
    PaymentsModule,
    AuditLogModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
