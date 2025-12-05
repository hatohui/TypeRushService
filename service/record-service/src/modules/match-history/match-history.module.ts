import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { MatchHistoryController } from './match-history.controller';
import { MatchHistoryService } from './match-history.service';
import { MatchHistoryRepository } from './match-history.repository';

/**
 * MatchHistory module
 * Handles all operations related to match histories and participants
 */
@Module({
  imports: [PrismaModule],
  controllers: [MatchHistoryController],
  providers: [MatchHistoryService, MatchHistoryRepository],
  exports: [MatchHistoryService],
})
export class MatchHistoryModule {}
