import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import Razorpay from 'razorpay';
import { PrismaService } from '../prisma/prisma.module';
import { CreateOrderDto, VerifyPaymentDto } from './payments.dto';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private razorpayClient: Razorpay | null = null;
  private readonly keyId = process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder';
  private readonly keySecret = process.env.RAZORPAY_KEY_SECRET || 'rzp_secret_placeholder';

  constructor(private readonly prisma: PrismaService) {
    if (
      process.env.RAZORPAY_KEY_ID &&
      process.env.RAZORPAY_KEY_SECRET &&
      !process.env.RAZORPAY_KEY_ID.includes('placeholder')
    ) {
      this.razorpayClient = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
      });
      this.logger.log('Razorpay client initialized with live/test API keys');
    } else {
      this.logger.warn('Razorpay keys not configured; operating in simulation sandbox mode');
    }
  }

  async createOrder(customerId: string, dto: CreateOrderDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
      include: {
        companion: { include: { user: { select: { fullName: true } } } },
        activity: true,
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    if (booking.customerId !== customerId) {
      throw new ForbiddenException('You can only create payments for your own bookings');
    }
    if (booking.status !== 'PAYMENT_PENDING' && booking.status !== 'PENDING') {
      throw new BadRequestException(
        `Cannot create payment for booking in status ${booking.status}. It must be accepted by companion first.`,
      );
    }

    const amount = booking.amount; // paise
    let razorpayOrderId: string;

    if (this.razorpayClient) {
      try {
        const order = await this.razorpayClient.orders.create({
          amount,
          currency: 'INR',
          receipt: `rcpt_${booking.id.slice(0, 10)}`,
          notes: {
            bookingId: booking.id,
            customerId,
            companionId: booking.companionId,
          },
        });
        razorpayOrderId = order.id;
      } catch (err: any) {
        this.logger.error(`Razorpay order creation failed: ${err.message}`, err.stack);
        throw new BadRequestException(`Payment provider error: ${err.message}`);
      }
    } else {
      // Sandbox fallback order id
      razorpayOrderId = `order_sim_${Date.now()}_${booking.id.slice(0, 6)}`;
    }

    // Upsert payment record
    const payment = await this.prisma.payment.upsert({
      where: { razorpayOrderId },
      create: {
        bookingId: booking.id,
        razorpayOrderId,
        amount,
        currency: 'INR',
        status: 'CREATED',
      },
      update: {
        amount,
        status: 'CREATED',
      },
    });

    return {
      orderId: razorpayOrderId,
      amount: booking.amount,
      currency: 'INR',
      keyId: this.keyId,
      bookingId: booking.id,
      activityName: booking.activity.name,
      companionName: booking.companion.user.fullName ?? 'Companion',
    };
  }

  async verifyPayment(customerId: string, dto: VerifyPaymentDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    if (booking.customerId !== customerId) {
      throw new ForbiddenException('You can only verify payments for your own bookings');
    }

    // Verify HMAC-SHA256 signature if in live mode
    if (this.razorpayClient && dto.razorpaySignature) {
      const generatedSignature = crypto
        .createHmac('sha256', this.keySecret)
        .update(`${dto.razorpayOrderId}|${dto.razorpayPaymentId}`)
        .digest('hex');

      if (generatedSignature !== dto.razorpaySignature) {
        throw new BadRequestException('Invalid payment signature verification failed');
      }
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Update Payment record to CAPTURED
      await tx.payment.upsert({
        where: { razorpayOrderId: dto.razorpayOrderId },
        create: {
          bookingId: booking.id,
          razorpayOrderId: dto.razorpayOrderId,
          razorpayPaymentId: dto.razorpayPaymentId,
          amount: booking.amount,
          currency: 'INR',
          status: 'CAPTURED',
        },
        update: {
          razorpayPaymentId: dto.razorpayPaymentId,
          status: 'CAPTURED',
        },
      });

      // 2. Transition booking to CONFIRMED
      const updatedBooking = await tx.booking.update({
        where: { id: booking.id },
        data: { status: 'CONFIRMED' },
        include: {
          companion: { include: { user: true } },
          customer: true,
          activity: true,
        },
      });

      // 3. Record status history
      await tx.bookingStatusHistory.create({
        data: {
          bookingId: booking.id,
          from: booking.status,
          to: 'CONFIRMED',
          actorId: customerId,
          note: `Payment of ₹${Math.round(booking.amount / 100)} verified successfully. Meeting confirmed.`,
        },
      });

      return updatedBooking;
    });
  }

  async handleWebhook(rawBody: any, signature: string) {
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (webhookSecret && signature) {
      const expectedSignature = crypto
        .createHmac('sha256', webhookSecret)
        .update(typeof rawBody === 'string' ? rawBody : JSON.stringify(rawBody))
        .digest('hex');

      if (expectedSignature !== signature) {
        throw new BadRequestException('Invalid webhook signature');
      }
    }

    const event = typeof rawBody === 'string' ? JSON.parse(rawBody) : rawBody;
    const eventType = event.event;

    this.logger.log(`Received Razorpay webhook event: ${eventType}`);

    if (eventType === 'payment.captured' || eventType === 'order.paid') {
      const paymentEntity = event.payload?.payment?.entity;
      const orderId = paymentEntity?.order_id;
      const paymentId = paymentEntity?.id;
      const bookingId = paymentEntity?.notes?.bookingId;

      if (bookingId && orderId) {
        await this.prisma.$transaction(async (tx) => {
          await tx.payment.upsert({
            where: { razorpayOrderId: orderId },
            create: {
              bookingId,
              razorpayOrderId: orderId,
              razorpayPaymentId: paymentId,
              amount: paymentEntity.amount,
              currency: 'INR',
              status: 'CAPTURED',
            },
            update: {
              razorpayPaymentId: paymentId,
              status: 'CAPTURED',
            },
          });

          await tx.booking.updateMany({
            where: { id: bookingId, status: { in: ['PENDING', 'PAYMENT_PENDING'] } },
            data: { status: 'CONFIRMED' },
          });
        });
      }
    }

    return { received: true };
  }
}
