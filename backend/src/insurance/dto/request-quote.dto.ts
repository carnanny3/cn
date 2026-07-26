import { IsIn, IsOptional, IsString } from 'class-validator';

export class RequestQuoteDto {
  @IsString()
  vehicleId!: string;

  @IsOptional()
  @IsIn(['comprehensive', 'third_party_liability'])
  coverageType?: string;
}
