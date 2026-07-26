import { IsString } from 'class-validator';

export class PurchaseWarrantyPolicyDto {
  @IsString()
  planId!: string;

  @IsString()
  vehicleId!: string;
}
