import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ConciergeService } from './concierge.service';
import { CreateConciergeOrderDto } from './dto/create-order.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('concierge')
@ApiBearerAuth()
@Controller('concierge')
export class ConciergeController {
  constructor(private readonly conciergeService: ConciergeService) {}

  @Post('orders')
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateConciergeOrderDto) {
    return this.conciergeService.createOrder(user.sub, dto);
  }

  @Get('orders')
  getMyOrders(@CurrentUser() user: JwtPayload) {
    return this.conciergeService.getMyOrders(user.sub);
  }

  @Roles('partner')
  @Get('orders/assigned/mine')
  findAllForPartner(@CurrentUser() user: JwtPayload) {
    return this.conciergeService.findAllForPartner(user.sub);
  }

  @Get('orders/:id')
  getOrder(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.conciergeService.getOrder(user.sub, id);
  }

  @Roles('partner')
  @Patch('orders/:id/status')
  updateStatusAsPartner(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() body: { status: string }) {
    return this.conciergeService.updateStatusAsPartner(id, body.status, user.sub);
  }
}
