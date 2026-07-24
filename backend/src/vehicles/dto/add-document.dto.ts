import { IsDateString, IsIn, IsOptional, IsString } from 'class-validator';

export class AddDocumentDto {
  @IsIn(['registration', 'insurance', 'warranty', 'ownership_transfer', 'other'])
  type!: 'registration' | 'insurance' | 'warranty' | 'ownership_transfer' | 'other';

  @IsString()
  fileUrl!: string;

  @IsOptional()
  @IsDateString()
  issuedDate?: string;

  @IsOptional()
  @IsDateString()
  expiryDate?: string;
}
