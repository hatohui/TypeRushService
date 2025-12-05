import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { AchievementController } from './achievement.controller';
import { AchievementService } from './achievement.service';
import { AchievementRepository } from './achievement.repository';

/**
 * Achievement module
 * Handles all operations related to achievements
 */
@Module({
  imports: [PrismaModule],
  controllers: [AchievementController],
  providers: [AchievementService, AchievementRepository],
  exports: [AchievementService],
})
export class AchievementModule {}
