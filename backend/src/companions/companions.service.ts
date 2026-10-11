import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.module';
import {
  SubmitVerificationDto,
  SyncAvailabilityDto,
  SyncCompanionActivitiesDto,
  UpdateCompanionProfileDto,
} from './companions.dto';

@Injectable()
export class CompanionsService {
  constructor(private readonly prisma: PrismaService) {}

  private async getCompanionIdByUserId(userId: string): Promise<string> {
    const companion = await this.prisma.companion.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!companion) throw new NotFoundException('Companion profile not found');
    return companion.id;
  }

  async getMe(userId: string) {
    const companion = await this.prisma.companion.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            photoUrl: true,
            city: true,
            gender: true,
            status: true,
          },
        },
        activities: {
          include: {
            activity: true,
          },
        },
        availability: {
          orderBy: [{ dayOfWeek: 'asc' }, { startMinute: 'asc' }],
        },
        verifications: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
    });

    if (!companion) throw new NotFoundException('Companion profile not found');
    return companion;
  }

  async getById(id: string) {
    const companion = await this.prisma.companion.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            photoUrl: true,
            city: true,
            gender: true,
          },
        },
        activities: {
          include: {
            activity: true,
          },
        },
        availability: {
          orderBy: [{ dayOfWeek: 'asc' }, { startMinute: 'asc' }],
        },
      },
    });

    if (!companion) throw new NotFoundException('Companion not found');
    return companion;
  }

  async updateProfile(userId: string, dto: UpdateCompanionProfileDto) {
    const companionId = await this.getCompanionIdByUserId(userId);
    return this.prisma.companion.update({
      where: { id: companionId },
      data: dto,
    });
  }

  async submitVerification(userId: string, dto: SubmitVerificationDto) {
    const companionId = await this.getCompanionIdByUserId(userId);

    return this.prisma.$transaction(async (tx) => {
      const verification = await tx.companionVerification.create({
        data: {
          companionId,
          documentType: dto.documentType,
          documentPath: dto.documentPath,
          selfiePath: dto.selfiePath,
          status: 'PENDING',
        },
      });

      await tx.companion.update({
        where: { id: companionId },
        data: { verificationStatus: 'PENDING' },
      });

      return verification;
    });
  }

  async syncActivities(userId: string, dto: SyncCompanionActivitiesDto) {
    const companionId = await this.getCompanionIdByUserId(userId);

    // Validate that activities exist
    if (dto.activities.length > 0) {
      const activityIds = dto.activities.map((a) => a.activityId);
      const existing = await this.prisma.activity.findMany({
        where: { id: { in: activityIds }, isActive: true },
        select: { id: true },
      });
      if (existing.length !== activityIds.length) {
        throw new BadRequestException('One or more selected activities are invalid or inactive');
      }
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.companionActivity.deleteMany({
        where: { companionId },
      });

      if (dto.activities.length > 0) {
        await tx.companionActivity.createMany({
          data: dto.activities.map((a) => ({
            companionId,
            activityId: a.activityId,
            customRate: a.customRate,
          })),
        });
      }

      return tx.companionActivity.findMany({
        where: { companionId },
        include: { activity: true },
      });
    });
  }

  async syncAvailability(userId: string, dto: SyncAvailabilityDto) {
    const companionId = await this.getCompanionIdByUserId(userId);

    // Validate time windows
    for (const slot of dto.slots) {
      if (slot.startMinute >= slot.endMinute) {
        throw new BadRequestException(
          `Slot startMinute (${slot.startMinute}) must be strictly less than endMinute (${slot.endMinute})`,
        );
      }
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.availability.deleteMany({
        where: { companionId },
      });

      if (dto.slots.length > 0) {
        await tx.availability.createMany({
          data: dto.slots.map((s) => ({
            companionId,
            dayOfWeek: s.dayOfWeek,
            startMinute: s.startMinute,
            endMinute: s.endMinute,
          })),
        });
      }

      return tx.availability.findMany({
        where: { companionId },
        orderBy: [{ dayOfWeek: 'asc' }, { startMinute: 'asc' }],
      });
    });
  }
}
