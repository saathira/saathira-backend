import { Module } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, FirebaseService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
