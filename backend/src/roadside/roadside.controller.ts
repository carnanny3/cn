import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoadsideService } from './roadside.service';
import { CreateRoadsideRequestDto } from './dto/create-roadside-request.dto';
import { UpdateRoadsideStatusDto } from './dto/update-roadside-status.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('roadside')
@ApiBearerAuth()
@Controller('roadside')
export class RoadsideController {
  constructor(private readonly roadsideService: RoadsideService) {}

  @Post('requests')
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateRoadsideRequestDto) {
    return this.roadsideService.createRequest(user.sub, dto);
  }

  @Get('requests')
  getMyRequests(@CurrentUser() user: JwtPayload) {
    return this.roadsideService.getMyRequests(user.sub);
  }

  @Roles('partner')
  @Get('requests/assigned/mine')
  findAllForPartner(@CurrentUser() user: JwtPayload) {
    return this.roadsideService.findAllForPartner(user.sub);
  }

  @Get('requests/:id/track')
  track(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.roadsideService.track(user.sub, id);
  }

  @Post('requests/:id/cancel')
  cancel(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.roadsideService.cancel(user.sub, id);
  }

  @Roles('partner', 'admin_ops', 'admin_super')
  @Patch('requests/:id/status')
  updateStatus(@CurrentUser() user: JwtPayload, @Param('id') id: string, @Body() dto: UpdateRoadsideStatusDto) {
    return this.roadsideService.updateStatus(id, dto.status, user.sub, user.role);
  }
}
