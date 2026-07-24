import { IsIn } from 'class-validator';

export class UpdateInspectionStatusDto {
  @IsIn(['assigned', 'in_progress', 'qa_review', 'completed', 'cancelled'])
  status!: 'assigned' | 'in_progress' | 'qa_review' | 'completed' | 'cancelled';
}
