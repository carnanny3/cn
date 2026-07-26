import { IsOptional, IsString, MinLength } from 'class-validator';

export class SubmitClaimDto {
  @IsString()
  policyId!: string;

  @IsString()
  @MinLength(5)
  description!: string;

  @IsOptional()
  @IsString({ each: true })
  documentUrls?: string[];
}
