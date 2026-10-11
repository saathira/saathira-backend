import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { AuthContext, CurrentAuth } from '../auth/auth.decorators';
import { QueryNotificationsDto, UpdateFcmTokenDto } from './notifications.dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  findMyNotifications(@CurrentAuth() auth: AuthContext, @Query() q: QueryNotificationsDto) {
    return this.notificationsService.findMyNotifications(auth.user!.id, q);
  }

  @Patch('fcm-token')
  updateFcmToken(@CurrentAuth() auth: AuthContext, @Body() dto: UpdateFcmTokenDto) {
    return this.notificationsService.updateFcmToken(auth.user!.id, dto);
  }

  @Patch(':id/read')
  markAsRead(@CurrentAuth() auth: AuthContext, @Param('id') id: string) {
    return this.notificationsService.markAsRead(auth.user!.id, id);
  }

  @Post('read-all')
  markAllAsRead(@CurrentAuth() auth: AuthContext) {
    return this.notificationsService.markAllAsRead(auth.user!.id);
  }
}
