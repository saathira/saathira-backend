import { BadRequestException, Body, ConflictException, Controller, Get, Patch, Post } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.module';
import { AllowUnregistered, AuthContext, CurrentAuth } from './auth.decorators';
import { RegisterDto, UpdateMeDto } from './auth.dto';

const MIN_AGE = 18;

function assertAdult(dob?: string) {
  if (!dob) return;
  const d = new Date(dob);
  const cutoff = new Date();
  cutoff.setFullYear(cutoff.getFullYear() - MIN_AGE);
  if (d > cutoff) throw new BadRequestException(`Users must be at least ${MIN_AGE} years old`);
}

@Controller()
export class AuthController {
  constructor(private readonly prisma: PrismaService) {}

  /** Returns the current user (with companion profile) or `registered: false`. */
  @Get('auth/me')
  @AllowUnregistered()
  async me(@CurrentAuth() auth: AuthContext) {
    if (!auth.user) return { registered: false, adminRole: auth.adminRole ?? null };
    const user = await this.prisma.user.findUnique({
      where: { id: auth.user.id },
      include: { companion: true },
    });
    return { registered: true, adminRole: auth.adminRole ?? null, user };
  }

  /** Creates DB user for a Firebase-authenticated person. Companion role also creates an empty profile. */
  @Post('auth/register')
  @AllowUnregistered()
  async register(@CurrentAuth() auth: AuthContext, @Body() dto: RegisterDto) {
    assertAdult(dto.dateOfBirth);
    if (auth.user) {
      return this.prisma.user.update({
        where: { id: auth.user.id },
        data: {
          fullName: dto.fullName,
          email: dto.email ?? auth.email,
          gender: dto.gender,
          city: dto.city,
          dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
          role: dto.role,
        },
        include: { companion: true },
      });
    }

    return this.prisma.user.upsert({
      where: { firebaseUid: auth.uid },
      update: {
        fullName: dto.fullName,
        email: dto.email ?? auth.email,
        gender: dto.gender,
        city: dto.city,
        dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
        role: dto.role,
      },
      create: {
        firebaseUid: auth.uid,
        phone: auth.phone,
        email: dto.email ?? auth.email,
        role: dto.role,
        fullName: dto.fullName,
        gender: dto.gender,
        city: dto.city,
        dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
        companion: dto.role === 'COMPANION' ? { create: { hourlyRate: 0 } } : undefined,
      },
      include: { companion: true },
    });
  }

  @Patch('users/me')
  async updateMe(@CurrentAuth() auth: AuthContext, @Body() dto: UpdateMeDto) {
    assertAdult(dto.dateOfBirth);
    return this.prisma.user.update({
      where: { id: auth.user!.id },
      data: { ...dto, dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined },
    });
  }
}
