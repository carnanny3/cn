import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateWarrantyPlanDto {
  @IsString()
  providerPartnerId!: string;

  @IsString()
  name!: string;

  @IsString()
  coverageSummary!: string;

  @IsOptional()
  @IsString()
  exclusions?: string;

  @IsNumber()
  @Min(0)
  price!: number;

  @IsOptional()
  eligibilityRules?: { maxAgeYears?: number; maxMileageKm?: number };
}
