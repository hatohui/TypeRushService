import { Injectable } from '@nestjs/common';
import type { PersonalRecord } from '../../../generated/prisma';
import { PrismaService } from 'src/prisma/prisma.service';
import { PersonalRecordCreate } from './dtos/create-personal-record';

@Injectable()
export class PersonalRecordRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: PersonalRecordCreate): Promise<PersonalRecord> {
    return await this.prisma.personalRecord.create({ data });
  }

  async findByAccountId(accountId: string): Promise<PersonalRecord | null> {
    return await this.prisma.personalRecord.findFirst({ where: { accountId } });
  }

  async findAll(): Promise<PersonalRecord[]> {
    return await this.prisma.personalRecord.findMany();
  }
}
