import { IsString, IsNotEmpty, IsInt, Min, MinLength } from 'class-validator';

/**
 * DTO for creating a new achievement
 */
export class CreateAchievementDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  name: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  description: string;

  @IsInt()
  @Min(0)
  wpmCriteria: number;
}
