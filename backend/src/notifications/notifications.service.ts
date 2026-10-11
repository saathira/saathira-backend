import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.module';
import { FirebaseService } from '../firebase/firebase.service';
import { QueryNotificationsDto, UpdateFcmTokenDto } from './notifications.dto';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly firebase: FirebaseService,
  ) {}

  async updateFcmToken(userId: string, dto: UpdateFcmTokenDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: dto.fcmToken },
    });
  }

  async createAndSendNotification(params: {
    userId: string;
    type: string;
    title: string;
    body: string;
    data?: Record<string, any>;
  }) {
    // 1. Insert DB notification
    const notification = await this.prisma.notification.create({
      data: {
        userId: params.userId,
        type: params.type,
        title: params.title,
        body: params.body,
        data: params.data ?? {},
      },
    });

    // 2. Fetch user's FCM token and dispatch push notification
    const user = await this.prisma.user.findUnique({
      where: { id: params.userId },
      select: { fcmToken: true },
    });

    if (user?.fcmToken) {
      const stringifiedData: Record<string, string> = {};
      if (params.data) {
        for (const [key, value] of Object.entries(params.data)) {
          stringifiedData[key] = String(value);
        }
      }
      await this.firebase.sendPushNotification(user.fcmToken, {
        title: params.title,
        body: params.body,
        data: stringifiedData,
      });
    }

    return notification;
  }

  async findMyNotifications(userId: string, q: QueryNotificationsDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 30;

    const [items, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.notification.count({ where: { userId } }),
      this.prisma.notification.count({ where: { userId, readAt: null } }),
    ]);

    return { items, total, unreadCount, page, pageSize };
  }

  async markAsRead(userId: string, notificationId: string) {
    const notif = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });
    if (!notif || notif.userId !== userId) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { readAt: new Date() },
    });
  }

  async markAllAsRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { success: true };
  }
}
