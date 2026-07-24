import { IsEmail, IsOptional, IsPhoneNumber, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail(undefined, { message: 'email must be a valid email address' })
  email!: string;

  @IsString()
  @MinLength(8, { message: 'password must be at least 8 characters' })
  password!: string;

  @IsString()
  @MinLength(2)
  fullName!: string;

  @IsOptional()
  @IsPhoneNumber(undefined, { message: 'phoneNumber must be a valid phone number in international format, e.g. +9715XXXXXXXX' })
  phoneNumber?: string;
}
