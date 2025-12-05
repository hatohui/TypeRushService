import { Controller, Get, Param } from '@nestjs/common';
import { PersonalRecordService } from './personal-record.service';
import { PersonalRecord } from 'generated/prisma';

@Controller('records')
export class PersonalRecordController {
  constructor(private readonly recordService: PersonalRecordService) {}

  @Get()
  async getAll(): Promise<PersonalRecord[]> {
    return this.recordService.getAll();
  }

  @Get(':id')
  async getById(@Param('id') id: string): Promise<PersonalRecord | null> {
    return this.recordService.getById(id);
  }
}
