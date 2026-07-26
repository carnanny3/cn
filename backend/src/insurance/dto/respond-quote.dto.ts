import { IsDateString, IsIn, IsNumber, Min } from 'class-validator';

export class RespondQuoteDto {
  @IsNumber()
  @Min(0)
  premiumAmount!: number;

  @IsIn(['comprehensive', 'third_party_liability'])
  coverageType!: string;

  @IsNumber()
  @Min(0)
  excessAmount!: number;

  @IsDateString()
  validUntil!: string;
}
