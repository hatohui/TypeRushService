import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { UserAchievementController } from './user-achievement.controller';
import { UserAchievementService } from './user-achievement.service';
import { UserAchievementRepository } from './user-achievement.repository';

/**
 * UserAchievement module
 * Handles all operations related to user achievements
 */
@Module({
  imports: [PrismaModule],
  controllers: [UserAchievementController],
  providers: [UserAchievementService, UserAchievementRepository],
  exports: [UserAchievementService],
})
export class UserAchievementModule {}
