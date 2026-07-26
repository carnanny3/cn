import { IsIn, IsOptional, IsString } from 'class-validator';

const STATUSES = [
  'submitted',
  'under_review',
  'inspection_required',
  'approved',
  'rejected',
  'repair_authorized',
  'completed',
  'closed',
] as const;

export class UpdateClaimStatusDto {
  @IsIn(STATUSES)
  status!: (typeof STATUSES)[number];

  @IsOptional()
  @IsString()
  rejectionReason?: string;

  @IsOptional()
  @IsString()
  assignedGarageId?: string;
}
