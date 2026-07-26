import { IsString } from 'class-validator';

export class CreateInsuranceProviderDto {
  @IsString()
  name!: string;
}
