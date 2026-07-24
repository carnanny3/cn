import { IsOptional, IsString } from 'class-validator';

export class SendMessageDto {
  @IsString()
  content!: string;

  @IsOptional()
  @IsString()
  vehicleId?: string;
}
