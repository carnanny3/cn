import { IsBoolean, IsInt, IsNumber, IsOptional, Min } from 'class-validator';

export class UpdatePartnerServiceDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  durationEstimateMinutes?: number;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
