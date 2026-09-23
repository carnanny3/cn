import { IsEmail } from 'class-validator';

export class AddCoOwnerDto {
  @IsEmail()
  email!: string;
}
