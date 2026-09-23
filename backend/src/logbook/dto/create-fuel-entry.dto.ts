import { IsBoolean, IsDateString, IsInt, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateFuelEntryDto {
  /** YYYY-MM-DD */
  @IsDateString()
  date!: string;

  @IsInt()
  @Min(0)
  odometerKm!: number;

  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0.1)
  liters!: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  cost?: number;

  @IsOptional()
  @IsBoolean()
  fullTank?: boolean;

  @IsOptional()
  @IsBoolean()
  missedPrevious?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
