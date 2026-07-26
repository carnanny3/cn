import { IsEmail, IsOptional, IsPhoneNumber, IsString } from 'class-validator';

export class UpdatePartnerProfileDto {
  @IsOptional()
  @IsString()
  businessName?: string;

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
