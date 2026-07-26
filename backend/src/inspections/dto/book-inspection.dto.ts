import { Type } from 'class-transformer';
import { IsDateString, IsDefined, IsNumber, IsOptional, IsString, ValidateNested } from 'class-validator';

class LocationDto {
  @IsNumber()
  lat!: number;

  @IsNumber()
  lng!: number;

  @IsOptional()
  @IsString()
  address?: string;
}

export class BookInspectionDto {
  @IsOptional()
  @IsString()
  vehicleId?: string;

  @IsOptional()
  @IsString()
  plateNumber?: string;

  @IsOptional()
  @IsString()
  makeModelYear?: string;

  @IsDefined()
  @ValidateNested()
  @Type(() => LocationDto)
  location!: LocationDto;

  @IsDateString()
  scheduledAt!: string;
}
