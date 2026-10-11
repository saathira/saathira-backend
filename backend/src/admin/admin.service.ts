import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, UserStatus } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.module';
import {
  QueryAdminDto,
  ResolveDisputeDto,
  ResolveReportDto,
  ReviewVerificationDto,
  SendTestNotificationDto,
  UpdateUserStatusDto,
} from './admin.dto';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async logAudit(actorId: string, action: string, entityType: string, entityId: string, metadata?: any) {
    return this.prisma.auditLog.create({
      data: {
        actorId,
        action,
        entityType,
        entityId,
        metadata: metadata ?? Prisma.JsonNull,
      },
    });
  }

  // 1. Dashboard Metrics
  async getDashboardStats() {
    const [
      totalUsers,
      totalCompanions,
      activeCompanions,
      pendingVerifications,
      totalBookings,
      confirmedBookings,
      completedBookings,
      gmvAggregate,
      commissionAggregate,
      openReports,
      openComplaints,
      openDisputes,
      recentBookings,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.companion.count(),
      this.prisma.companion.count({ where: { isAvailable: true, verificationStatus: 'APPROVED' } }),
      this.prisma.companionVerification.count({ where: { status: 'PENDING' } }),
      this.prisma.booking.count(),
      this.prisma.booking.count({ where: { status: 'CONFIRMED' } }),
      this.prisma.booking.count({ where: { status: 'COMPLETED' } }),
      this.prisma.booking.aggregate({
        where: { status: { in: ['CONFIRMED', 'IN_PROGRESS', 'COMPLETED'] } },
        _sum: { amount: true },
      }),
      this.prisma.booking.aggregate({
        where: { status: { in: ['CONFIRMED', 'IN_PROGRESS', 'COMPLETED'] } },
        _sum: { commission: true },
      }),
      this.prisma.report.count({ where: { status: 'OPEN' } }),
      this.prisma.complaint.count({ where: { status: 'OPEN' } }),
      this.prisma.dispute.count({ where: { status: 'OPEN' } }),
      this.prisma.booking.findMany({
        take: 8,
        orderBy: { createdAt: 'desc' },
        include: {
          customer: { select: { fullName: true, phone: true } },
          companion: { include: { user: { select: { fullName: true } } } },
          activity: true,
        },
      }),
    ]);

    const gmvPaise = gmvAggregate._sum.amount ?? 0;
    const commissionPaise = commissionAggregate._sum.commission ?? 0;

    return {
      users: {
        total: totalUsers,
        companions: totalCompanions,
        activeCompanions,
        pendingVerifications,
      },
      bookings: {
        total: totalBookings,
        confirmed: confirmedBookings,
        completed: completedBookings,
        gmvRupees: Math.round(gmvPaise / 100),
        commissionRupees: Math.round(commissionPaise / 100),
      },
      trustAndSafety: {
        openReports,
        openComplaints,
        openDisputes,
      },
      recentBookings,
    };
  }

  // 2. Verifications Queue
  async getVerifications(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 20;

    const where: Prisma.CompanionVerificationWhereInput = {
      status: q.status ? (q.status as any) : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.companionVerification.findMany({
        where,
        include: {
          companion: {
            include: { user: true },
          },
        },
        orderBy: { createdAt: 'asc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.companionVerification.count({ where }),
    ]);

    return { items, total, page, pageSize };
  }

  async approveVerification(id: string, adminUid: string, dto: ReviewVerificationDto) {
    const record = await this.prisma.companionVerification.findUnique({
      where: { id },
      include: { companion: true },
    });
    if (!record) throw new NotFoundException('Verification not found');

    return this.prisma.$transaction(async (tx) => {
      const updatedVerification = await tx.companionVerification.update({
        where: { id },
        data: {
          status: 'APPROVED',
          reviewedBy: adminUid,
          reviewNote: dto.note ?? 'Approved by Admin',
          reviewedAt: new Date(),
        },
      });

      await tx.companion.update({
        where: { id: record.companionId },
        data: { verificationStatus: 'APPROVED' },
      });

      await this.logAudit(adminUid, 'VERIFICATION_APPROVED', 'CompanionVerification', id, {
        companionId: record.companionId,
        note: dto.note,
      });

      return updatedVerification;
    });
  }

  async rejectVerification(id: string, adminUid: string, dto: ReviewVerificationDto) {
    const record = await this.prisma.companionVerification.findUnique({
      where: { id },
      include: { companion: true },
    });
    if (!record) throw new NotFoundException('Verification not found');

    return this.prisma.$transaction(async (tx) => {
      const updatedVerification = await tx.companionVerification.update({
        where: { id },
        data: {
          status: 'REJECTED',
          reviewedBy: adminUid,
          reviewNote: dto.note ?? 'Rejected by Admin',
          reviewedAt: new Date(),
        },
      });

      await tx.companion.update({
        where: { id: record.companionId },
        data: { verificationStatus: 'REJECTED' },
      });

      await this.logAudit(adminUid, 'VERIFICATION_REJECTED', 'CompanionVerification', id, {
        companionId: record.companionId,
        note: dto.note,
      });

      return updatedVerification;
    });
  }

  // 3. User Management
  async getUsers(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 25;

    const where: Prisma.UserWhereInput = {
      role: q.status ? (q.status as any) : undefined,
      OR: q.query
        ? [
            { fullName: { contains: q.query, mode: 'insensitive' } },
            { phone: { contains: q.query, mode: 'insensitive' } },
            { email: { contains: q.query, mode: 'insensitive' } },
            { city: { contains: q.query, mode: 'insensitive' } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        include: {
          companion: { select: { verificationStatus: true, ratingAvg: true, ratingCount: true } },
          _count: { select: { customerBookings: true, reviewsGiven: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.user.count({ where }),
    ]);

    return { items, total, page, pageSize };
  }

  async updateUserStatus(id: string, status: UserStatus, adminUid: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');

    const updated = await this.prisma.user.update({
      where: { id },
      data: { status },
    });

    await this.logAudit(adminUid, `USER_STATUS_${status}`, 'User', id, { previousStatus: user.status });
    return updated;
  }

  // 4. Bookings Stream
  async getBookings(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 25;

    const where: Prisma.BookingWhereInput = {
      status: q.status ? (q.status as any) : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: {
          customer: { select: { id: true, fullName: true, phone: true } },
          companion: { include: { user: { select: { id: true, fullName: true, phone: true } } } },
          activity: true,
          payments: true,
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return { items, total, page, pageSize };
  }

  // 5. Payments & Payouts
  async getPayments(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 25;

    const [items, total] = await Promise.all([
      this.prisma.payment.findMany({
        include: {
          booking: {
            include: {
              customer: { select: { fullName: true } },
              companion: { include: { user: { select: { fullName: true } } } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.payment.count(),
    ]);

    return { items, total, page, pageSize };
  }

  async getPayouts(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 25;

    const [items, total] = await Promise.all([
      this.prisma.payout.findMany({
        include: {
          companion: { include: { user: { select: { fullName: true, phone: true } } } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.payout.count(),
    ]);

    return { items, total, page, pageSize };
  }

  async approvePayout(id: string, adminUid: string) {
    const payout = await this.prisma.payout.findUnique({ where: { id } });
    if (!payout) throw new NotFoundException('Payout not found');

    const updated = await this.prisma.payout.update({
      where: { id },
      data: {
        status: 'PAID',
        approvedBy: adminUid,
        paidAt: new Date(),
      },
    });

    await this.logAudit(adminUid, 'PAYOUT_APPROVED', 'Payout', id, { amount: payout.amount });
    return updated;
  }

  // 6. Reports & Disputes Resolution
  async getReports(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 25;

    const where: Prisma.ReportWhereInput = {
      status: q.status ? (q.status as any) : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.report.findMany({
        where,
        include: {
          reporter: { select: { fullName: true, role: true } },
          reportedUser: { select: { id: true, fullName: true, role: true, status: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.report.count({ where }),
    ]);

    return { items, total, page, pageSize };
  }

  async resolveReport(id: string, dto: ResolveReportDto, adminUid: string) {
    const report = await this.prisma.report.findUnique({ where: { id } });
    if (!report) throw new NotFoundException('Report not found');

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.report.update({
        where: { id },
        data: {
          status: 'RESOLVED',
          details: report.details ? `${report.details}\n[Admin note: ${dto.resolutionNote}]` : dto.resolutionNote,
        },
      });

      if (dto.suspendUser) {
        await tx.user.update({
          where: { id: report.reportedUserId },
          data: { status: 'SUSPENDED' },
        });
      }

      await this.logAudit(adminUid, 'REPORT_RESOLVED', 'Report', id, {
        reportedUserId: report.reportedUserId,
        suspended: dto.suspendUser,
      });

      return updated;
    });
  }

  async getDisputes(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 25;

    const [items, total] = await Promise.all([
      this.prisma.dispute.findMany({
        include: {
          booking: {
            include: {
              customer: { select: { fullName: true, phone: true } },
              companion: { include: { user: { select: { fullName: true, phone: true } } } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.dispute.count(),
    ]);

    return { items, total, page, pageSize };
  }

  async resolveDispute(id: string, dto: ResolveDisputeDto, adminUid: string) {
    const dispute = await this.prisma.dispute.findUnique({ where: { id } });
    if (!dispute) throw new NotFoundException('Dispute not found');

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.dispute.update({
        where: { id },
        data: {
          status: 'RESOLVED',
          resolution: dto.resolution,
          resolvedAt: new Date(),
        },
      });

      if (dto.refundCustomer) {
        await tx.booking.update({
          where: { id: dispute.bookingId },
          data: { status: 'REFUNDED' },
        });
      }

      await this.logAudit(adminUid, 'DISPUTE_RESOLVED', 'Dispute', id, {
        bookingId: dispute.bookingId,
        refundCustomer: dto.refundCustomer,
      });

      return updated;
    });
  }

  // 7. Audit Logs
  async getAuditLogs(q: QueryAdminDto) {
    const page = q.page ? Number(q.page) : 1;
    const pageSize = q.pageSize ? Number(q.pageSize) : 50;

    const [items, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.auditLog.count(),
    ]);

    return { items, total, page, pageSize };
  }

  // 8. Notifications / Push Test
  async sendTestNotification(dto: SendTestNotificationDto, adminUid: string) {
    if (dto.userId === 'ALL') {
      const users = await this.prisma.user.findMany({
        where: { status: 'ACTIVE' },
        select: { id: true, fcmToken: true, fullName: true },
      });
      let sentCount = 0;
      for (const u of users) {
        await this.notificationsService.createAndSendNotification({
          userId: u.id,
          type: dto.type ?? 'SYSTEM',
          title: dto.title,
          body: dto.body,
          data: { test: 'true', sentAt: new Date().toISOString() },
        });
        if (u.fcmToken) sentCount++;
      }
      await this.logAudit(adminUid, 'BROADCAST_TEST_NOTIFICATION', 'Notification', 'ALL', {
        title: dto.title,
        totalUsers: users.length,
        fcmTargetCount: sentCount,
      });
      return {
        success: true,
        message: `Notification broadcast to ${users.length} users (${sentCount} devices with active FCM push tokens).`,
        totalRecipients: users.length,
        fcmTargetCount: sentCount,
      };
    }

    const user = await this.prisma.user.findUnique({
      where: { id: dto.userId },
      select: { id: true, fullName: true, phone: true, fcmToken: true },
    });
    if (!user) throw new NotFoundException('User not found');

    const notification = await this.notificationsService.createAndSendNotification({
      userId: user.id,
      type: dto.type ?? 'SYSTEM',
      title: dto.title,
      body: dto.body,
      data: { test: 'true', sentAt: new Date().toISOString() },
    });

    await this.logAudit(adminUid, 'SEND_TEST_NOTIFICATION', 'Notification', notification.id, {
      targetUserId: user.id,
      hasFcmToken: Boolean(user.fcmToken),
      title: dto.title,
    });

    return {
      success: true,
      notification,
      hasFcmToken: Boolean(user.fcmToken),
      fcmTokenSnippet: user.fcmToken ? `${user.fcmToken.slice(0, 12)}...` : null,
      message: user.fcmToken
        ? `✅ Push notification dispatched to ${user.fullName || 'User'}'s registered device via Firebase FCM!`
        : `⚠️ In-app notification created in database inbox, but user has no FCM token yet. Have user log in to mobile app first.`,
    };
  }
}
