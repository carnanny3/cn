import { IsIn, IsNumber, IsString, Min } from 'class-validator';

export class CreatePaymentIntentDto {
  @IsIn(['booking', 'inspection', 'warranty_policy', 'insurance_policy', 'roadside_request'])
  relatedEntityType!: 'booking' | 'inspection' | 'warranty_policy' | 'insurance_policy' | 'roadside_request';

  @IsString()
  relatedEntityId!: string;

  @IsNumber()
  @Min(0)
  amount!: number;

  @IsIn(['card', 'apple_pay', 'google_pay', 'pay_at_service'])
  paymentMethod!: 'card' | 'apple_pay' | 'google_pay' | 'pay_at_service';
}
