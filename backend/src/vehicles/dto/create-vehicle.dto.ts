import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateVehicleDto {
  @IsOptional()
  @IsString()
  vin?: string;

  @IsString()
  plateNumber!: string;

  @IsString()
  emirateRegistered!: string;

  @IsString()
  make!: string;

  @IsString()
  model!: string;

  @IsInt()
  @Min(1980)
  @Max(new Date().getFullYear() + 1)
  year!: number;

  @IsOptional()
  @IsString()
  bodyType?: string;

  @IsOptional()
  @IsIn(['petrol', 'diesel', 'hybrid', 'electric'])
  fuelType?: string;

  @IsOptional()
  @IsIn(['auto', 'manual'])
  transmission?: string;

  @IsOptional()
  @IsBoolean()
  gccSpec?: boolean;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  mileageKm?: number;

  @IsOptional()
  @IsString()
  primaryPhotoUrl?: string;
}
