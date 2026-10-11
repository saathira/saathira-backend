import { UserRole } from '@prisma/client';
import { IsDateString, IsEmail, IsEnum, IsOptional, IsString, Length, MaxLength } from 'class-validator';

export class RegisterDto {
  @IsEnum(UserRole)
  role: UserRole;

  @IsString()
  @Length(2, 80)
  fullName: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  gender?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  city?: string;
}

export class UpdateMeDto {
  @IsOptional() @IsString() @Length(2, 80) fullName?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() @MaxLength(20) gender?: string;
  @IsOptional() @IsDateString() dateOfBirth?: string;
  @IsOptional() @IsString() @MaxLength(60) city?: string;
  @IsOptional() @IsString() @MaxLength(500) photoUrl?: string;
  @IsOptional() @IsString() @MaxLength(300) fcmToken?: string;
}
