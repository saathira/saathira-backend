import { IsOptional, IsString } from 'class-validator';

export class UpdateFcmTokenDto {
  @IsString()
  fcmToken: string;
}

export class QueryNotificationsDto {
  @IsOptional()
  page?: number;

  @IsOptional()
  pageSize?: number;
}
