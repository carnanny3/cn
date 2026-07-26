import { Body, Controller, Get, Headers, HttpCode, HttpStatus, Param, Post, RawBodyRequest, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiExcludeEndpoint, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { PaymentsService } from './payments.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { AuditLogService } from '../audit-log/audit-log.service';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('payments')
@ApiBearerAuth()
@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly auditLog: AuditLogService,
  ) {}

  @Post('intents')
  createIntent(@CurrentUser() user: JwtPayload, @Body() dto: CreatePaymentIntentDto) {
    return this.paymentsService.createIntent(user.sub, dto);
  }

  // Called by Stripe directly, not the app — no user JWT is present.
  @Public()
  @ApiExcludeEndpoint()
  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  async webhook(@Req() req: RawBodyRequest<Request>, @Headers('stripe-signature') signature: string) {
    await this.paymentsService.handleStripeWebhook(req.rawBody!, signature);
    return { received: true };
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.paymentsService.findOne(id);
  }

  @Post(':id/confirm')
  confirm(@Param('id') id: string) {
    return this.paymentsService.confirm(id);
  }

  @Roles('admin_finance', 'admin_super')
  @Post(':id/refund')
  async refund(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Req() req: Request) {
    const before = await this.paymentsService.findOne(id);
    const after = await this.paymentsService.refund(id);
    await this.auditLog.log({
      adminUserId: user.sub,
      action: 'payment.refund',
      entityType: 'Payment',
      entityId: id,
      beforeState: before,
      afterState: after,
      ipAddress: req.ip,
    });
    return after;
  }
}
