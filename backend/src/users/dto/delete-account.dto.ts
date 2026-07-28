import { IsString } from 'class-validator';

/**
 * Deleting an account is irreversible and wipes uploaded documents, so it is
 * gated on the current password — a stolen access token alone shouldn't be
 * enough to destroy someone's data.
 */
export class DeleteAccountDto {
  @IsString()
  password!: string;
}
