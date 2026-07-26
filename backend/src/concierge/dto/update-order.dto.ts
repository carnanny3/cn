import { IsIn, IsOptional, IsString } from 'class-validator';

const STATUSES = ['requested', 'assigned', 'in_progress', 'completed', 'cancelled'] as const;

export class UpdateConciergeOrderDto {
  @IsOptional()
  @IsIn(STATUSES)
  status?: (typeof STATUSES)[number];

  @IsOptional()
  @IsString()
  assignedPartnerId?: string;

  @IsOptional()
  @IsString()
  assignedAdminId?: string;
}
