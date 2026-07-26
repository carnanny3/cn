import { IsIn } from 'class-validator';

const STATUSES = ['accepted', 'en_route', 'arrived', 'in_service', 'completed', 'cancelled'] as const;

export class UpdateRoadsideStatusDto {
  @IsIn(STATUSES)
  status!: (typeof STATUSES)[number];
}
