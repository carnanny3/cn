import { IsEmail, IsString, Length, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(6, 6, { message: 'code must be a 6-digit code' })
  code!: string;

  @IsString()
  @MinLength(8, { message: 'newPassword must be at least 8 characters' })
  newPassword!: string;
}
