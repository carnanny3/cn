import { IsString, MinLength } from 'class-validator';

export class CreateTicketDto {
  @IsString()
  category!: string;

  @IsString()
  @MinLength(3)
  subject!: string;

  @IsString()
  @MinLength(1)
  message!: string;
}
