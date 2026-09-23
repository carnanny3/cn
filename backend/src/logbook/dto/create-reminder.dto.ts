import { IsDateString, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

/** A reminder needs a due date, a due odometer, or both; the service enforces that. */
export class CreateReminderDto {
  @IsString()
  @MaxLength(200)
  title!: string;

  /** YYYY-MM-DD */
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  dueOdometerKm?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(120)
  repeatMonths?: number;

  @IsOptional()
  @IsInt()
  @Min(100)
  repeatKm?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
