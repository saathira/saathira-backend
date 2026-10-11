import { UserStatus } from '@prisma/client';
import { IsBoolean, IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class QueryAdminDto {
  @IsOptional()
  page?: number;

  @IsOptional()
  pageSize?: number;

  @IsOptional()
  query?: string;

  @IsOptional()
  status?: string;
}

export class ReviewVerificationDto {
  @IsString()
  @IsOptional()
  note?: string;
}

export class UpdateUserStatusDto {
  @IsEnum(UserStatus)
  status: UserStatus;
}

export class ResolveReportDto {
  @IsString()
  @IsNotEmpty()
  resolutionNote: string;

  @IsBoolean()
  @IsOptional()
  suspendUser?: boolean;
}

export class ResolveDisputeDto {
  @IsString()
  @IsNotEmpty()
  resolution: string;

  @IsBoolean()
  @IsOptional()
  refundCustomer?: boolean;
}
