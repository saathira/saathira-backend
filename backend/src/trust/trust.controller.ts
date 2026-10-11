import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { AuthContext, CurrentAuth } from '../auth/auth.decorators';
import {
  CreateBlockDto,
  CreateComplaintDto,
  CreateDisputeDto,
  CreateReportDto,
  CreateReviewDto,
} from './trust.dto';
import { TrustService } from './trust.service';

@Controller()
export class TrustController {
  constructor(private readonly trustService: TrustService) {}

  @Post('reviews')
  createReview(@CurrentAuth() auth: AuthContext, @Body() dto: CreateReviewDto) {
    return this.trustService.createReview(auth.user!.id, dto);
  }

  @Post('reports')
  createReport(@CurrentAuth() auth: AuthContext, @Body() dto: CreateReportDto) {
    return this.trustService.createReport(auth.user!.id, dto);
  }

  @Post('blocks')
  createBlock(@CurrentAuth() auth: AuthContext, @Body() dto: CreateBlockDto) {
    return this.trustService.createBlock(auth.user!.id, dto);
  }

  @Get('blocks')
  getMyBlocks(@CurrentAuth() auth: AuthContext) {
    return this.trustService.getMyBlocks(auth.user!.id);
  }

  @Delete('blocks/:id')
  deleteBlock(@CurrentAuth() auth: AuthContext, @Param('id') blockedId: string) {
    return this.trustService.deleteBlock(auth.user!.id, blockedId);
  }

  @Post('complaints')
  createComplaint(@CurrentAuth() auth: AuthContext, @Body() dto: CreateComplaintDto) {
    return this.trustService.createComplaint(auth.user!.id, dto);
  }

  @Get('complaints')
  getMyComplaints(@CurrentAuth() auth: AuthContext) {
    return this.trustService.getMyComplaints(auth.user!.id);
  }

  @Post('disputes')
  createDispute(@CurrentAuth() auth: AuthContext, @Body() dto: CreateDisputeDto) {
    return this.trustService.createDispute(auth.user!.id, dto);
  }

  @Get('disputes')
  getMyDisputes(@CurrentAuth() auth: AuthContext) {
    return this.trustService.getMyDisputes(auth.user!.id);
  }
}
