import { IsBoolean, IsIn, IsString } from 'class-validator';

export class SetPreferenceDto {
  @IsString()
  category!: string;

  @IsIn(['push', 'sms', 'email', 'whatsapp'])
  channel!: 'push' | 'sms' | 'email' | 'whatsapp';

  @IsBoolean()
  enabled!: boolean;
}
