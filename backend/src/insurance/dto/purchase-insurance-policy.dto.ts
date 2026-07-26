import { IsString } from 'class-validator';

export class PurchaseInsurancePolicyDto {
  @IsString()
  quoteId!: string;
}
