import { IsDateString, IsIn, IsInt, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export const RECORD_TYPES = ['service', 'repair', 'upgrade', 'fee'] as const;

export class CreateRecordDto {
  @IsIn(RECORD_TYPES)
  type!: (typeof RECORD_TYPES)[number];

  /** YYYY-MM-DD */
  @IsDateString()
  date!: string;

  @IsString()
  @MaxLength(200)
  title!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  odometerKm?: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  cost?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
