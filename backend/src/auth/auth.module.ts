import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { RewardsModule } from '../rewards/rewards.module';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';

@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_ACCESS_SECRET || 'dev-access-secret',
    }),
    RewardsModule,
  ],
  controllers: [AuthController],
  providers: [AuthService],
  exports: [JwtModule, AuthService],
})
export class AuthModule {}
