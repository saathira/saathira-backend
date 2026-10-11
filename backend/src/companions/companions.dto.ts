import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class UpdateCompanionProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  bio?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(15)
  languages?: string[];

  @IsOptional()
  @IsInt()
  @Min(0)
  hourlyRate?: number; // in paise

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  serviceRadiusKm?: number;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  payoutUpi?: string;
}

export class SubmitVerificationDto {
  @IsString()
  @MaxLength(50)
  documentType: string;

  @IsString()
  @MaxLength(500)
  documentPath: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  selfiePath?: string;
}

export class ActivityItemDto {
  @IsString()
  activityId: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  customRate?: number; // in paise
}

export class SyncCompanionActivitiesDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ActivityItemDto)
  activities: ActivityItemDto[];
}

export class AvailabilitySlotDto {
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek: number; // 0 = Sunday, 1 = Monday ... 6 = Saturday

  @IsInt()
  @Min(0)
  @Max(1439)
  startMinute: number;

  @IsInt()
  @Min(0)
  @Max(1439)
  endMinute: number;
}

export class SyncAvailabilityDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AvailabilitySlotDto)
  slots: AvailabilitySlotDto[];
}
