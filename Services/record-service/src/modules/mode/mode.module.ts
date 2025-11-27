// File: src/modules/mode/mode.module.ts

import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { ModeController } from './mode.controller';
import { ModeService } from './mode.service';
import { ModeRepository } from './mode.repository';

/**
 * Mode module
 * Handles all operations related to game modes
 */
@Module({
  imports: [PrismaModule],
  controllers: [ModeController],
  providers: [ModeService, ModeRepository],
  exports: [ModeService],
})
export class ModeModule {}
