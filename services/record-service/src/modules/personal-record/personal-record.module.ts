import { Module } from '@nestjs/common';
import { PrismaModule } from 'src/prisma/prisma.module';
import { PersonalRecordController } from './personal-record.controller';
import { PersonalRecordRepository } from './personal-record.repository';
import { PersonalRecordService } from './personal-record.service';

@Module({
  imports: [PrismaModule],
  controllers: [PersonalRecordController],
  providers: [PersonalRecordService, PersonalRecordRepository],
  exports: [PersonalRecordRepository],
})
export class PersonalRecordModule {}
