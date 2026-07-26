import { IsInt, IsOptional, IsString } from 'class-validator';

export class CreateCmsContentDto {
  @IsString()
  section!: string;

  @IsOptional()
  @IsString()
  locale?: string;

  @IsString()
  title!: string;

  @IsString()
  body!: string;

  @IsOptional()
  @IsInt()
  order?: number;
}
