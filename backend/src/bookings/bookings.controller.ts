import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthContext, CurrentAuth, Roles } from '../auth/auth.decorators';
import {
  CancelBookingDto,
  CreateBookingDto,
  QueryBookingsDto,
  RejectBookingDto,
} from './bookings.dto';
import { BookingsService } from './bookings.service';

@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Roles(UserRole.CUSTOMER)
  @Post()
  createBooking(@CurrentAuth() auth: AuthContext, @Body() dto: CreateBookingDto) {
    return this.bookingsService.createBooking(auth.user!.id, dto);
  }

  @Get()
  findMyBookings(@CurrentAuth() auth: AuthContext, @Query() q: QueryBookingsDto) {
    return this.bookingsService.findMyBookings(auth.user!.id, auth.user!.role, q);
  }

  @Get(':id')
  findById(@CurrentAuth() auth: AuthContext, @Param('id') id: string) {
    return this.bookingsService.findById(id, auth.user!.id, auth.adminRole);
  }

  @Roles(UserRole.COMPANION)
  @Post(':id/accept')
  acceptBooking(@CurrentAuth() auth: AuthContext, @Param('id') id: string) {
    return this.bookingsService.acceptBooking(id, auth.user!.id);
  }

  @Roles(UserRole.COMPANION)
  @Post(':id/reject')
  rejectBooking(@CurrentAuth() auth: AuthContext, @Param('id') id: string, @Body() dto: RejectBookingDto) {
    return this.bookingsService.rejectBooking(id, auth.user!.id, dto);
  }

  @Post(':id/cancel')
  cancelBooking(@CurrentAuth() auth: AuthContext, @Param('id') id: string, @Body() dto: CancelBookingDto) {
    return this.bookingsService.cancelBooking(id, auth.user!.id, dto);
  }

  @Roles(UserRole.COMPANION)
  @Post(':id/start')
  startBooking(@CurrentAuth() auth: AuthContext, @Param('id') id: string) {
    return this.bookingsService.startBooking(id, auth.user!.id);
  }

  @Post(':id/complete')
  completeBooking(@CurrentAuth() auth: AuthContext, @Param('id') id: string) {
    return this.bookingsService.completeBooking(id, auth.user!.id);
  }
}
