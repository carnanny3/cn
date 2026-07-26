import { IsIn, IsOptional, IsString } from 'class-validator';

const STATUSES = ['open', 'in_progress', 'resolved', 'closed'] as const;

export class UpdateTicketStatusDto {
  @IsIn(STATUSES)
  status!: (typeof STATUSES)[number];

  @IsOptional()
  @IsString()
  assignedAdminId?: string;
}
