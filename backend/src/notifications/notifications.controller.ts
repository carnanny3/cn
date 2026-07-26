import { Body, Controller, Get, Patch, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { SetPreferenceDto } from './dto/set-preference.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@ApiTags('notifications')
@ApiBearerAuth()
@Controller()
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get('notifications')
  list(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.listForUser(user.sub);
  }

  @Post('notifications/device-tokens')
  registerDeviceToken(@CurrentUser() user: JwtPayload, @Body() dto: RegisterDeviceTokenDto) {
    return this.notificationsService.registerDeviceToken(user.sub, dto.token, dto.platform);
  }

  @Post('notifications/device-tokens/remove')
  unregisterDeviceToken(@Body() body: { token: string }) {
    return this.notificationsService.unregisterDeviceToken(body.token);
  }

  @Patch('notifications/:id/read')
  markRead(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.notificationsService.markRead(user.sub, id);
  }

  @Get('notification-preferences')
  getPreferences(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.getPreferences(user.sub);
  }

  @Patch('notification-preferences')
  setPreference(@CurrentUser() user: JwtPayload, @Body() dto: SetPreferenceDto) {
    return this.notificationsService.setPreference(user.sub, dto.category, dto.channel, dto.enabled);
  }
}
