import { Body, Controller, Get, Param, Patch, Post, Put } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthContext, CurrentAuth, Public, Roles } from '../auth/auth.decorators';
import {
  SubmitVerificationDto,
  SyncAvailabilityDto,
  SyncCompanionActivitiesDto,
  UpdateCompanionProfileDto,
} from './companions.dto';
import { CompanionsService } from './companions.service';

@Controller('companions')
export class CompanionsController {
  constructor(private readonly companionsService: CompanionsService) {}

  @Roles(UserRole.COMPANION)
  @Get('me')
  getMe(@CurrentAuth() auth: AuthContext) {
    return this.companionsService.getMe(auth.user!.id);
  }

  @Roles(UserRole.COMPANION)
  @Patch('me')
  updateProfile(@CurrentAuth() auth: AuthContext, @Body() dto: UpdateCompanionProfileDto) {
    return this.companionsService.updateProfile(auth.user!.id, dto);
  }

  @Roles(UserRole.COMPANION)
  @Post('me/verification')
  submitVerification(@CurrentAuth() auth: AuthContext, @Body() dto: SubmitVerificationDto) {
    return this.companionsService.submitVerification(auth.user!.id, dto);
  }

  @Roles(UserRole.COMPANION)
  @Put('me/activities')
  syncActivities(@CurrentAuth() auth: AuthContext, @Body() dto: SyncCompanionActivitiesDto) {
    return this.companionsService.syncActivities(auth.user!.id, dto);
  }

  @Roles(UserRole.COMPANION)
  @Put('me/availability')
  syncAvailability(@CurrentAuth() auth: AuthContext, @Body() dto: SyncAvailabilityDto) {
    return this.companionsService.syncAvailability(auth.user!.id, dto);
  }

  @Public()
  @Get(':id')
  getById(@Param('id') id: string) {
    return this.companionsService.getById(id);
  }
}
