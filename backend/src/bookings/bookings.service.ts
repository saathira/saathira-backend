import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AdminRole, BookingStatus, Prisma, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.module';
import { ACTIVE_BOOKING_STATUSES, canTransition } from './booking-state';
import { CancelBookingDto, CreateBookingDto, QueryBookingsDto, RejectBookingDto } from './bookings.dto';

@Injectable()
export class BookingsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Throws if the companion already has an active booking overlapping [startAt, endAt). */
  async assertNoOverlap(tx: Prisma.TransactionClient, companionId: string, startAt: Date, endAt: Date, excludeBookingId?: string) {
    if (endAt <= startAt) throw new BadRequestException('endAt must be strictly after startAt');
    const clash = await tx.booking.findFirst({
      where: {
        companionId,
        id: excludeBookingId ? { not: excludeBookingId } : undefined,
        status: { in: ACTIVE_BOOKING_STATUSES },
        startAt: { lt: endAt },
        endAt: { gt: startAt },
      },
      select: { id: true, startAt: true, endAt: true },
    });
    if (clash) {
      throw new ConflictException(
        `Companion is already booked during this time window (${clash.startAt.toISOString()} - ${clash.endAt.toISOString()})`,
      );
    }
  }

  async createBooking(customerId: string, dto: CreateBookingDto) {
    const startAt = new Date(dto.startAt);
    const endAt = new Date(dto.endAt);
    const now = new Date();

    if (startAt < now) {
      throw new BadRequestException('Booking start time must be in the future');
    }
    if (endAt <= startAt) {
      throw new BadRequestException('endAt must be strictly after startAt');
    }

    const durationMinutes = Math.round((endAt.getTime() - startAt.getTime()) / (1000 * 60));
    if (durationMinutes < 60) {
      throw new BadRequestException('Minimum booking duration is 1 hour (60 minutes)');
    }

    // Verify companion
    const companion = await this.prisma.companion.findUnique({
      where: { id: dto.companionId },
      include: {
        user: { select: { id: true, status: true } },
        activities: { where: { activityId: dto.activityId } },
      },
    });

    if (!companion || companion.user.status !== 'ACTIVE') {
      throw new NotFoundException('Companion not found or inactive');
    }
    if (companion.userId === customerId) {
      throw new BadRequestException('You cannot book yourself as a companion');
    }
    if (companion.verificationStatus !== 'APPROVED') {
      throw new BadRequestException('This companion is pending identity verification and cannot accept bookings yet');
    }
    if (!companion.isAvailable) {
      throw new BadRequestException('This companion is currently not accepting new booking requests');
    }

    // Determine hourly rate (custom activity rate or companion base rate)
    let ratePaise = companion.hourlyRate;
    if (companion.activities.length > 0 && companion.activities[0].customRate != null) {
      ratePaise = companion.activities[0].customRate!;
    }
    if (ratePaise <= 0) {
      throw new BadRequestException('Companion has not configured a valid hourly rate');
    }

    const amount = Math.round((ratePaise * durationMinutes) / 60);
    const commissionPercent = Number(process.env.PLATFORM_COMMISSION_PERCENT || 20);
    const commission = Math.round((amount * commissionPercent) / 100);

    return this.prisma.$transaction(async (tx) => {
      // 1. Double-booking overlap prevention
      await this.assertNoOverlap(tx, dto.companionId, startAt, endAt);

      // 2. Create booking record
      const booking = await tx.booking.create({
        data: {
          customerId,
          companionId: dto.companionId,
          activityId: dto.activityId,
          startAt,
          endAt,
          meetingPlace: dto.meetingPlace,
          latitude: dto.latitude,
          longitude: dto.longitude,
          notes: dto.notes,
          amount,
          commission,
          status: 'PENDING',
        },
        include: {
          companion: { include: { user: { select: { id: true, fullName: true, photoUrl: true, city: true } } } },
          customer: { select: { id: true, fullName: true, photoUrl: true } },
          activity: true,
        },
      });

      // 3. Record status history
      await tx.bookingStatusHistory.create({
        data: {
          bookingId: booking.id,
          to: 'PENDING',
          actorId: customerId,
          note: 'Booking requested by customer',
        },
      });

      return booking;
    });
  }

  async findMyBookings(userId: string, role: UserRole, q: QueryBookingsDto) {
    const page = q.page ?? 1;
    const pageSize = q.pageSize ?? 20;

    let where: Prisma.BookingWhereInput;
    if (role === UserRole.CUSTOMER) {
      where = {
        customerId: userId,
        status: q.status ? q.status : undefined,
      };
    } else {
      const companion = await this.prisma.companion.findUnique({
        where: { userId },
        select: { id: true },
      });
      if (!companion) return { items: [], total: 0, page, pageSize };
      where = {
        companionId: companion.id,
        status: q.status ? q.status : undefined,
      };
    }

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: {
          companion: { include: { user: { select: { id: true, fullName: true, photoUrl: true, city: true } } } },
          customer: { select: { id: true, fullName: true, photoUrl: true } },
          activity: true,
        },
        orderBy: { startAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return { items, total, page, pageSize };
  }

  async findById(bookingId: string, userId: string, adminRole?: AdminRole) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        companion: {
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                photoUrl: true,
                city: true,
                phone: true,
                gender: true,
              },
            },
          },
        },
        customer: {
          select: {
            id: true,
            fullName: true,
            photoUrl: true,
            city: true,
            phone: true,
            gender: true,
          },
        },
        activity: true,
        history: { orderBy: { createdAt: 'asc' } },
        payments: true,
        review: true,
        disputes: true,
      },
    });

    if (!booking) throw new NotFoundException('Booking not found');

    const isCustomer = booking.customerId === userId;
    const isCompanion = booking.companion.userId === userId;
    const isAdmin = Boolean(adminRole);

    if (!isCustomer && !isCompanion && !isAdmin) {
      throw new ForbiddenException('You do not have access to view this booking');
    }

    if (!isAdmin) {
      // Mask / remove other party's phone number to strictly enforce privacy
      if (isCustomer && booking.companion?.user) {
        (booking.companion.user as any).phone = null;
      }
      if (isCompanion && booking.customer) {
        (booking.customer as any).phone = null;
      }
    }

    return booking;
  }

  async acceptBooking(bookingId: string, companionUserId: string) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { companion: true },
      });
      if (!booking) throw new NotFoundException('Booking not found');
      if (booking.companion.userId !== companionUserId) {
        throw new ForbiddenException('Only the assigned companion can accept this booking');
      }
      if (booking.status !== 'PENDING') {
        throw new BadRequestException(`Cannot accept booking in status ${booking.status}`);
      }

      // Overlap check before accepting
      await this.assertNoOverlap(tx, booking.companionId, booking.startAt, booking.endAt, booking.id);

      // Transition PENDING -> PAYMENT_PENDING (awaiting customer payment)
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'PAYMENT_PENDING' },
      });

      await tx.bookingStatusHistory.create({
        data: {
          bookingId,
          from: 'PENDING',
          to: 'PAYMENT_PENDING',
          actorId: companionUserId,
          note: 'Companion accepted the booking request. Awaiting payment.',
        },
      });

      return updated;
    });
  }

  async rejectBooking(bookingId: string, companionUserId: string, dto: RejectBookingDto) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { companion: true },
      });
      if (!booking) throw new NotFoundException('Booking not found');
      if (booking.companion.userId !== companionUserId) {
        throw new ForbiddenException('Only the assigned companion can reject this booking');
      }
      if (booking.status !== 'PENDING') {
        throw new BadRequestException(`Cannot reject booking in status ${booking.status}`);
      }

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'REJECTED', cancelReason: dto.reason },
      });

      await tx.bookingStatusHistory.create({
        data: {
          bookingId,
          from: 'PENDING',
          to: 'REJECTED',
          actorId: companionUserId,
          note: dto.reason ?? 'Companion declined the booking request',
        },
      });

      return updated;
    });
  }

  async cancelBooking(bookingId: string, userId: string, dto: CancelBookingDto) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { companion: true },
      });
      if (!booking) throw new NotFoundException('Booking not found');

      const isCustomer = booking.customerId === userId;
      const isCompanion = booking.companion.userId === userId;
      if (!isCustomer && !isCompanion) {
        throw new ForbiddenException('Only the customer or companion can cancel this booking');
      }

      if (!canTransition(booking.status, 'CANCELLED')) {
        throw new BadRequestException(`Cannot cancel booking in status ${booking.status}`);
      }

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: {
          status: 'CANCELLED',
          cancelledBy: isCustomer ? 'CUSTOMER' : 'COMPANION',
          cancelReason: dto.reason,
        },
      });

      await tx.bookingStatusHistory.create({
        data: {
          bookingId,
          from: booking.status,
          to: 'CANCELLED',
          actorId: userId,
          note: `Cancelled by ${isCustomer ? 'Customer' : 'Companion'}: ${dto.reason}`,
        },
      });

      return updated;
    });
  }

  async startBooking(bookingId: string, companionUserId: string) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { companion: true },
      });
      if (!booking) throw new NotFoundException('Booking not found');
      if (booking.companion.userId !== companionUserId) {
        throw new ForbiddenException('Only the assigned companion can start the meeting');
      }
      if (booking.status !== 'CONFIRMED') {
        throw new BadRequestException(`Cannot start booking in status ${booking.status}`);
      }

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'IN_PROGRESS' },
      });

      await tx.bookingStatusHistory.create({
        data: {
          bookingId,
          from: 'CONFIRMED',
          to: 'IN_PROGRESS',
          actorId: companionUserId,
          note: 'Meeting started',
        },
      });

      return updated;
    });
  }

  async completeBooking(bookingId: string, userId: string) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { companion: true },
      });
      if (!booking) throw new NotFoundException('Booking not found');

      const isCustomer = booking.customerId === userId;
      const isCompanion = booking.companion.userId === userId;
      if (!isCustomer && !isCompanion) {
        throw new ForbiddenException('Only participants can mark a booking complete');
      }
      if (booking.status !== 'IN_PROGRESS') {
        throw new BadRequestException(`Cannot complete booking in status ${booking.status}`);
      }

      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: 'COMPLETED' },
      });

      await tx.bookingStatusHistory.create({
        data: {
          bookingId,
          from: 'IN_PROGRESS',
          to: 'COMPLETED',
          actorId: userId,
          note: `Meeting marked completed by ${isCustomer ? 'Customer' : 'Companion'}`,
        },
      });

      return updated;
    });
  }
}
