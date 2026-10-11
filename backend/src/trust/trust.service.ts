import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.module';
import {
  CreateBlockDto,
  CreateComplaintDto,
  CreateDisputeDto,
  CreateReportDto,
  CreateReviewDto,
} from './trust.dto';

@Injectable()
export class TrustService {
  constructor(private readonly prisma: PrismaService) {}

  // 1. Reviews
  async createReview(authorId: string, dto: CreateReviewDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
      include: { review: true, companion: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    if (booking.customerId !== authorId) {
      throw new ForbiddenException('Only the booking customer can submit a review');
    }
    if (booking.status !== 'COMPLETED') {
      throw new BadRequestException('Reviews can only be submitted for completed bookings');
    }
    if (booking.review) {
      throw new ConflictException('A review has already been submitted for this booking');
    }

    return this.prisma.$transaction(async (tx) => {
      // Create Review
      const review = await tx.review.create({
        data: {
          bookingId: dto.bookingId,
          authorId,
          companionId: booking.companionId,
          rating: dto.rating,
          comment: dto.comment,
        },
      });

      // Recalculate Companion ratingAvg & ratingCount
      const stats = await tx.review.aggregate({
        where: { companionId: booking.companionId, isHidden: false },
        _avg: { rating: true },
        _count: { rating: true },
      });

      await tx.companion.update({
        where: { id: booking.companionId },
        data: {
          ratingAvg: stats._avg.rating ?? dto.rating,
          ratingCount: stats._count.rating ?? 1,
        },
      });

      return review;
    });
  }

  // 2. Reports
  async createReport(reporterId: string, dto: CreateReportDto) {
    if (reporterId === dto.reportedUserId) {
      throw new BadRequestException('You cannot report yourself');
    }

    const reportedUser = await this.prisma.user.findUnique({
      where: { id: dto.reportedUserId },
    });
    if (!reportedUser) {
      throw new NotFoundException('Reported user not found');
    }

    return this.prisma.report.create({
      data: {
        reporterId,
        reportedUserId: dto.reportedUserId,
        bookingId: dto.bookingId,
        reason: dto.reason,
        details: dto.details,
      },
    });
  }

  // 3. Blocks
  async createBlock(blockerId: string, dto: CreateBlockDto) {
    if (blockerId === dto.blockedId) {
      throw new BadRequestException('You cannot block yourself');
    }

    const blockedUser = await this.prisma.user.findUnique({
      where: { id: dto.blockedId },
    });
    if (!blockedUser) {
      throw new NotFoundException('User to block not found');
    }

    return this.prisma.block.upsert({
      where: {
        blockerId_blockedId: {
          blockerId,
          blockedId: dto.blockedId,
        },
      },
      create: {
        blockerId,
        blockedId: dto.blockedId,
      },
      update: {},
    });
  }

  async getMyBlocks(blockerId: string) {
    return this.prisma.block.findMany({
      where: { blockerId },
      include: {
        blocked: {
          select: { id: true, fullName: true, photoUrl: true, city: true },
        },
      },
    });
  }

  async deleteBlock(blockerId: string, blockedId: string) {
    return this.prisma.block.deleteMany({
      where: { blockerId, blockedId },
    });
  }

  // 4. Complaints
  async createComplaint(userId: string, dto: CreateComplaintDto) {
    return this.prisma.complaint.create({
      data: {
        userId,
        subject: dto.subject,
        message: dto.message,
      },
    });
  }

  async getMyComplaints(userId: string) {
    return this.prisma.complaint.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 5. Disputes
  async createDispute(userId: string, dto: CreateDisputeDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
      include: { companion: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    const isCustomer = booking.customerId === userId;
    const isCompanion = booking.companion.userId === userId;
    if (!isCustomer && !isCompanion) {
      throw new ForbiddenException('Only booking participants can raise a dispute');
    }

    return this.prisma.$transaction(async (tx) => {
      const dispute = await tx.dispute.create({
        data: {
          bookingId: dto.bookingId,
          raisedBy: userId,
          reason: dto.reason,
        },
      });

      // Update booking status to DISPUTED
      await tx.booking.update({
        where: { id: dto.bookingId },
        data: { status: 'DISPUTED' },
      });

      await tx.bookingStatusHistory.create({
        data: {
          bookingId: dto.bookingId,
          from: booking.status,
          to: 'DISPUTED',
          actorId: userId,
          note: `Dispute filed by ${isCustomer ? 'Customer' : 'Companion'}: ${dto.reason}`,
        },
      });

      return dispute;
    });
  }

  async getMyDisputes(userId: string) {
    return this.prisma.dispute.findMany({
      where: {
        booking: {
          OR: [{ customerId: userId }, { companion: { userId } }],
        },
      },
      include: { booking: { select: { id: true, amount: true, status: true, startAt: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}
