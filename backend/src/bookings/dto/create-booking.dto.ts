import { IsBoolean, IsDateString, IsIn, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateBookingDto {
  @IsIn(['service', 'roadside', 'concierge'])
  bookingType!: 'service' | 'roadside' | 'concierge';

  @IsString()
  vehicleId!: string;

  @IsOptional()
  @IsString()
  partnerId?: string;

  @IsOptional()
  @IsString()
  serviceCategory?: string;

  @IsDateString()
  scheduledAt!: string;

  @IsOptional()
  @IsBoolean()
  pickupDeliveryRequested?: boolean;

  @IsNumber()
  @Min(0)
  totalAmount!: number;
}
