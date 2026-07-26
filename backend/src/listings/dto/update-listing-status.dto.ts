import { IsIn } from 'class-validator';

const STATUSES = ['draft', 'active', 'reserved', 'sold', 'withdrawn'] as const;

export class UpdateListingStatusDto {
  @IsIn(STATUSES)
  status!: (typeof STATUSES)[number];
}
