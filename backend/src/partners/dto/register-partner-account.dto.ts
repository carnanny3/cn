import { IsEmail, IsIn, IsOptional, IsPhoneNumber, IsString, MinLength } from 'class-validator';

// Garages, inspectors, and roadside providers can self-register a login
// account — each has a real Partner Portal job queue. Other partner types
// (insurer, warranty_provider, etc.) are manual-workflow-only in this MVP,
// onboarded via the admin-managed `POST /partners/register` catalog entry.
const SELF_SERVE_PARTNER_TYPES = ['garage', 'inspector', 'roadside_provider'] as const;

export class RegisterPartnerAccountDto {
  @IsEmail(undefined, { message: 'email must be a valid email address' })
  email!: string;

  @IsString()
  @MinLength(8, { message: 'password must be at least 8 characters' })
  password!: string;

  @IsString()
  @MinLength(2)
  fullName!: string;

  @IsString()
  businessName!: string;

  @IsIn(SELF_SERVE_PARTNER_TYPES)
  partnerType!: (typeof SELF_SERVE_PARTNER_TYPES)[number];

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
