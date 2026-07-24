import { IsEmail, IsIn, IsOptional, IsPhoneNumber, IsString } from 'class-validator';

const PARTNER_TYPES = [
  'garage',
  'inspector',
  'insurer',
  'warranty_provider',
  'finance_provider',
  'roadside_provider',
  'detailer',
  'transporter',
] as const;

export class RegisterPartnerDto {
  @IsString()
  businessName!: string;

  @IsIn(PARTNER_TYPES)
  partnerType!: (typeof PARTNER_TYPES)[number];

  @IsOptional()
  @IsPhoneNumber(undefined)
  contactPhone?: string;

  @IsOptional()
  @IsEmail()
  contactEmail?: string;

  @IsOptional()
  @IsString()
  tradeLicenseUrl?: string;
}
