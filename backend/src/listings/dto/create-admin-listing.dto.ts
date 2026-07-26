import { IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateAdminListingDto {
  @IsOptional()
  @IsString()
  vehicleId?: string;

  @IsString()
  make!: string;

  @IsString()
  model!: string;

  @IsInt()
  @Min(1980)
  year!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  mileageKm?: number;

  @IsNumber()
  @Min(0)
  askingPrice!: number;

  @IsOptional()
  @IsString()
  inspectionId?: string;

  @IsOptional()
  @IsString({ each: true })
  photoUrls?: string[];
}
