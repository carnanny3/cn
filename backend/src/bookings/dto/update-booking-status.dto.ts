import { IsIn } from 'class-validator';

export class UpdateBookingStatusDto {
  @IsIn(['confirmed', 'in_progress', 'completed', 'cancelled'])
  status!: 'confirmed' | 'in_progress' | 'completed' | 'cancelled';
}
