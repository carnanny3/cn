import { IsDateString, IsIn, IsOptional } from 'class-validator';

/**
 * Accompanies the uploaded file on POST /vehicles/:id/documents. There is
 * deliberately no `fileUrl` field — the server derives the storage key from the
 * upload itself, so a client can't pass off an arbitrary URL as a document.
 */
export class AddDocumentDto {
  @IsIn(['registration', 'insurance', 'warranty', 'ownership_transfer', 'other'])
  type!: 'registration' | 'insurance' | 'warranty' | 'ownership_transfer' | 'other';

  @IsOptional()
  @IsDateString()
  issuedDate?: string;

  @IsOptional()
  @IsDateString()
  expiryDate?: string;
}
