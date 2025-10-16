import { Injectable } from '@nestjs/common';
import { PersonalRecord } from 'generated/prisma';
import { PersonalRecordRepository } from './personal-record.repository';

@Injectable()
export class PersonalRecordService {
  constructor(
    private readonly personalRecordRepository: PersonalRecordRepository,
  ) {}

  async getById(accountId: string): Promise<PersonalRecord | null> {
    return this.personalRecordRepository.findByAccountId(accountId);
  }

  async getAll(): Promise<PersonalRecord[]> {
    return this.personalRecordRepository.findAll();
  }
}
