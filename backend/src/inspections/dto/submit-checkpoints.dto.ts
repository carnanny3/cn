import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsIn, IsOptional, IsString, ValidateNested } from 'class-validator';

const CATEGORIES = [
  'engine', 'transmission', 'chassis', 'brakes', 'suspension', 'steering',
  'electrical', 'battery', 'ac', 'tires', 'wheels', 'interior', 'exterior',
  'fluids', 'paint_thickness', 'obd', 'road_test',
] as const;

const RESULTS = ['pass', 'minor_defect', 'critical_defect', 'not_applicable'] as const;

class CheckpointInput {
  @IsIn(CATEGORIES)
  category!: (typeof CATEGORIES)[number];

  @IsString()
  checkpointName!: string;

  @IsIn(RESULTS)
  result!: (typeof RESULTS)[number];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class SubmitCheckpointsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CheckpointInput)
  checkpoints!: CheckpointInput[];

  @IsOptional()
  @IsString()
  roadTestNotes?: string;
}
