import { IsString, IsNotEmpty, IsInt } from 'class-validator';

/**
 * DTO for creating a new user achievement
 */
export class CreateUserAchievementDto {
  @IsString()
  @IsNotEmpty()
  accountId: string;

  @IsInt()
  @IsNotEmpty()
  achievementId: number;
}
