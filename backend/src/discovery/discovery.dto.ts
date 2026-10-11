import { Type } from 'class-transformer';
import { IsIn, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class DiscoveryQueryDto {
  /** Activity slug or id */
  @IsOptional() @IsString() activity?: string;
  @IsOptional() @IsString() city?: string;
  /** Free-text search on name / bio */
  @IsOptional() @IsString() q?: string;

  /** Price filters in rupees per hour */
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) minPrice?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) maxPrice?: number;

  @IsOptional() @Type(() => Number) @IsNumber() lat?: number;
  @IsOptional() @Type(() => Number) @IsNumber() lng?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(200) radiusKm?: number;

  /** 0=Sun..6=Sat — only companions with a slot that day */
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(6) day?: number;
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0) @Max(5) minRating?: number;

  @IsOptional() @IsIn(['rating', 'price_asc', 'price_desc', 'distance']) sort?: string;

  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50) pageSize?: number;
}
