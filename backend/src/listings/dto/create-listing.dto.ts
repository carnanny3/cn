import { IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateListingDto {
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
  @IsString({ each: true })
  photoUrls?: string[];
}
