import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { PartnersModule } from './partners/partners.module';
import { InspectionsModule } from './inspections/inspections.module';
import { BookingsModule } from './bookings/bookings.module';
import { PaymentsModule } from './payments/payments.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AiModule } from './ai/ai.module';
import { AdminModule } from './admin/admin.module';
import { RewardsModule } from './rewards/rewards.module';
import { SupportModule } from './support/support.module';
import { WarrantyModule } from './warranty/warranty.module';
import { InsuranceModule } from './insurance/insurance.module';
import { RoadsideModule } from './roadside/roadside.module';
import { ConciergeModule } from './concierge/concierge.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsersModule,
    VehiclesModule,
    PartnersModule,
    InspectionsModule,
    BookingsModule,
    PaymentsModule,
    NotificationsModule,
    AiModule,
    AdminModule,
    RewardsModule,
    SupportModule,
    WarrantyModule,
    InsuranceModule,
    RoadsideModule,
    ConciergeModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}
