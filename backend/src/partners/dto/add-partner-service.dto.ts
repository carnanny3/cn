import { IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class AddPartnerServiceDto {
  @IsString()
  serviceCategory!: string;

  @IsNumber()
  @Min(0)
  price!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  durationEstimateMinutes?: number;
}
