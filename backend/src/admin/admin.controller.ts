import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { AdminRole } from '@prisma/client';
import { AuthContext, CurrentAuth, Roles } from '../auth/auth.decorators';
import {
  QueryAdminDto,
  ResolveDisputeDto,
  ResolveReportDto,
  ReviewVerificationDto,
  SendTestNotificationDto,
  UpdateUserStatusDto,
} from './admin.dto';
import { AdminService } from './admin.service';

@Roles(
  AdminRole.SUPER_ADMIN,
  AdminRole.ADMIN,
  AdminRole.SUPPORT,
  AdminRole.MODERATOR,
  AdminRole.FINANCE,
)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard/stats')
  getDashboardStats() {
    return this.adminService.getDashboardStats();
  }

  // Verifications
  @Get('verifications')
  getVerifications(@Query() q: QueryAdminDto) {
    return this.adminService.getVerifications(q);
  }

  @Post('verifications/:id/approve')
  approveVerification(
    @CurrentAuth() auth: AuthContext,
    @Param('id') id: string,
    @Body() dto: ReviewVerificationDto,
  ) {
    return this.adminService.approveVerification(id, auth.uid, dto);
  }

  @Post('verifications/:id/reject')
  rejectVerification(
    @CurrentAuth() auth: AuthContext,
    @Param('id') id: string,
    @Body() dto: ReviewVerificationDto,
  ) {
    return this.adminService.rejectVerification(id, auth.uid, dto);
  }

  // Users
  @Get('users')
  getUsers(@Query() q: QueryAdminDto) {
    return this.adminService.getUsers(q);
  }

  @Patch('users/:id/status')
  updateUserStatus(
    @CurrentAuth() auth: AuthContext,
    @Param('id') id: string,
    @Body() dto: UpdateUserStatusDto,
  ) {
    return this.adminService.updateUserStatus(id, dto.status, auth.uid);
  }

  // Bookings
  @Get('bookings')
  getBookings(@Query() q: QueryAdminDto) {
    return this.adminService.getBookings(q);
  }

  // Payments & Payouts
  @Get('payments')
  getPayments(@Query() q: QueryAdminDto) {
    return this.adminService.getPayments(q);
  }

  @Get('payouts')
  getPayouts(@Query() q: QueryAdminDto) {
    return this.adminService.getPayouts(q);
  }

  @Post('payouts/:id/approve')
  approvePayout(@CurrentAuth() auth: AuthContext, @Param('id') id: string) {
    return this.adminService.approvePayout(id, auth.uid);
  }

  // Reports & Disputes
  @Get('reports')
  getReports(@Query() q: QueryAdminDto) {
    return this.adminService.getReports(q);
  }

  @Patch('reports/:id/resolve')
  resolveReport(
    @CurrentAuth() auth: AuthContext,
    @Param('id') id: string,
    @Body() dto: ResolveReportDto,
  ) {
    return this.adminService.resolveReport(id, dto, auth.uid);
  }

  @Get('disputes')
  getDisputes(@Query() q: QueryAdminDto) {
    return this.adminService.getDisputes(q);
  }

  @Patch('disputes/:id/resolve')
  resolveDispute(
    @CurrentAuth() auth: AuthContext,
    @Param('id') id: string,
    @Body() dto: ResolveDisputeDto,
  ) {
    return this.adminService.resolveDispute(id, dto, auth.uid);
  }

  // Audit Logs
  @Get('audit-logs')
  getAuditLogs(@Query() q: QueryAdminDto) {
    return this.adminService.getAuditLogs(q);
  }

  // Notifications / Push Test
  @Post('notifications/test')
  sendTestNotification(
    @CurrentAuth() auth: AuthContext,
    @Body() dto: SendTestNotificationDto,
  ) {
    return this.adminService.sendTestNotification(dto, auth.uid);
  }
}
