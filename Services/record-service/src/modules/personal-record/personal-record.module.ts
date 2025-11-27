// File: src/modules/personal-record/personal-record.module.ts

import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { PersonalRecordController } from './personal-record.controller';
import { PersonalRecordRepository } from './personal-record.repository';
import { PersonalRecordService } from './personal-record.service';
import { JwtModule } from '@nestjs/jwt';
import { HttpModule } from '@nestjs/axios';

/**
 * PersonalRecord module
 * Handles all operations related to personal typing records
 */
@Module({
  imports: [
    PrismaModule,
    JwtModule.register({
      secret: 'temporary-secret-key',
      signOptions: { expiresIn: '1h' },
    }),
    HttpModule,
  ],
  controllers: [PersonalRecordController],
  providers: [PersonalRecordService, PersonalRecordRepository],
  exports: [PersonalRecordService],
})
export class PersonalRecordModule {}
