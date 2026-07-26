import { Type } from 'class-transformer';
import { IsDefined, IsIn, IsNumber, IsString, ValidateNested } from 'class-validator';

const SERVICE_TYPES = ['tow', 'jumpstart', 'flat_tire', 'fuel_delivery', 'lockout'] as const;

class LocationDto {
  @IsNumber()
  lat!: number;

  @IsNumber()
  lng!: number;
}

export class CreateRoadsideRequestDto {
  @IsString()
  vehicleId!: string;

  @IsIn(SERVICE_TYPES)
  serviceType!: (typeof SERVICE_TYPES)[number];

  @IsDefined()
  @ValidateNested()
  @Type(() => LocationDto)
  location!: LocationDto;
}
