import { IsInt, IsOptional, IsString } from 'class-validator';

export class UpdateCmsContentDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  body?: string;

  @IsOptional()
  @IsInt()
  order?: number;
}
