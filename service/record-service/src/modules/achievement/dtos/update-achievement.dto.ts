import { IsString, IsInt, IsOptional, Min, MinLength } from 'class-validator';

/**
 * DTO for updating an existing achievement
 */
export class UpdateAchievementDto {
  @IsString()
  @IsOptional()
  @MinLength(3)
  name?: string;

  @IsString()
  @IsOptional()
  @MinLength(10)
  description?: string;

  @IsInt()
  @IsOptional()
  @Min(0)
  wpmCriteria?: number;
}
