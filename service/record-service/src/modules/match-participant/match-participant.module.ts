import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { MatchParticipantController } from './match-participant.controller';
import { MatchParticipantService } from './match-participant.service';
import { MatchParticipantRepository } from './match-participant.repository';

/**
 * MatchParticipant module
 * Handles all operations related to match participants
 */
@Module({
  imports: [PrismaModule],
  controllers: [MatchParticipantController],
  providers: [MatchParticipantService, MatchParticipantRepository],
  exports: [MatchParticipantService],
})
export class MatchParticipantModule {}
