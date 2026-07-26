import { IsIn, IsOptional, IsString } from 'class-validator';

const ORDER_TYPES = ['registration_renewal', 'ownership_transfer', 'pickup_delivery', 'detailing', 'driver_service'] as const;

export class CreateConciergeOrderDto {
  @IsIn(ORDER_TYPES)
  orderType!: (typeof ORDER_TYPES)[number];

  @IsString()
  vehicleId!: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
