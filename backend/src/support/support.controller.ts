import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SupportService } from './support.service';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { AddTicketMessageDto } from './dto/add-ticket-message.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@ApiTags('support')
@ApiBearerAuth()
@Controller('support/tickets')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateTicketDto) {
    return this.supportService.createTicket(user.sub, dto.category, dto.subject, dto.message);
  }

  @Get()
  listMine(@CurrentUser() user: JwtPayload) {
    return this.supportService.listMyTickets(user.sub);
  }

  @Get(':id')
  getOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.supportService.getTicket(user.sub, id);
  }

  @Post(':id/messages')
  addMessage(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: AddTicketMessageDto) {
    return this.supportService.addMessage(user.sub, user.role, id, dto.content);
  }
}
