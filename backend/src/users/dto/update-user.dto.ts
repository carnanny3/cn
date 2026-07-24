import { IsEmail, IsIn, IsOptional, IsPhoneNumber, IsString, MinLength } from 'class-validator';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  fullName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsPhoneNumber(undefined, { message: 'phoneNumber must be a valid phone number in international format, e.g. +9715XXXXXXXX' })
  phoneNumber?: string;

  @IsOptional()
  @IsIn(['en', 'ar'])
  preferredLanguage?: string;

  @IsOptional()
  @IsString()
  emirate?: string;

  @IsOptional()
  @IsString()
  profilePhotoUrl?: string;
}
