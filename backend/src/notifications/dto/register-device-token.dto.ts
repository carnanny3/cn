import { IsIn, IsString } from 'class-validator';

export class RegisterDeviceTokenDto {
  @IsString()
  token!: string;

  @IsIn(['android', 'ios', 'web'])
  platform!: 'android' | 'ios' | 'web';
}
