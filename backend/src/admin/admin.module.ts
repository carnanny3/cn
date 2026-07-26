import { Module } from '@nestjs/common';
import { SupportModule } from '../support/support.module';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';

@Module({
  imports: [SupportModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
