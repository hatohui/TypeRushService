// File: src/modules/personal-record/personal-record.repository.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { PersonalRecord, Prisma } from '../../../generated/prisma';
import { CreatePersonalRecordDto } from './dtos/create-personal-record.dto';
import { UpdatePersonalRecordDto } from './dtos/update-personal-record.dto';

/**
 * Query parameters for finding all personal records
 */
export interface FindAllParams {
  page?: number;
  limit?: number;
  sort?: string;
  order?: 'asc' | 'desc';
  accountId?: string;
  startDate?: string;
  endDate?: string;
  minAccuracy?: number;
  maxAccuracy?: number;
}

/**
 * Repository for PersonalRecord entity operations
 */
@Injectable()
export class PersonalRecordRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new personal record
   */
  async create(data: CreatePersonalRecordDto): Promise<PersonalRecord> {
    return this.prisma.personalRecord.create({
      data: {
        accountId: data.accountId,
        accuracy: data.accuracy,
        raw: data.raw,
      },
    });
  }

  /**
   * Find all personal records with optional filtering, pagination, and sorting
   */
  async findAll(params?: FindAllParams): Promise<{
    records: PersonalRecord[];
    total: number;
  }> {
    const {
      page = 1,
      limit = 10,
      sort = 'createdAt',
      order = 'desc',
      accountId,
      startDate,
      endDate,
      minAccuracy,
      maxAccuracy,
    } = params || {};

    // Build where clause for filtering
    const where: Prisma.PersonalRecordWhereInput = {};

    if (accountId) {
      where.accountId = accountId;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt.gte = new Date(startDate);
      }
      if (endDate) {
        where.createdAt.lte = new Date(endDate);
      }
    }

    if (minAccuracy !== undefined || maxAccuracy !== undefined) {
      where.accuracy = {};
      if (minAccuracy !== undefined) {
        where.accuracy.gte = minAccuracy;
      }
      if (maxAccuracy !== undefined) {
        where.accuracy.lte = maxAccuracy;
      }
    }

    // Build orderBy clause
    const orderBy: Prisma.PersonalRecordOrderByWithRelationInput = {
      [sort]: order,
    };

    // Calculate pagination
    const skip = (page - 1) * limit;
    const take = limit;

    // Execute queries in parallel
    const [records, total] = await Promise.all([
      this.prisma.personalRecord.findMany({
        where,
        orderBy,
        skip,
        take,
      }),
      this.prisma.personalRecord.count({ where }),
    ]);

    return { records, total };
  }

  /**
   * Find a personal record by ID
   */
  async findById(id: string): Promise<PersonalRecord> {
    const record = await this.prisma.personalRecord.findFirst({
      where: { accountId: id },
    });

    if (!record) {
      throw new NotFoundException(`Personal record with ID ${id} not found`);
    }

    return record;
  }

  /**
   * Update a personal record by ID
   */
  async update(
    id: number,
    data: UpdatePersonalRecordDto,
  ): Promise<PersonalRecord> {
    try {
      return await this.prisma.personalRecord.update({
        where: { id },
        data,
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(
            `Personal record with ID ${id} not found`,
          );
        }
      }
      throw error;
    }
  }

  /**
   * Delete a personal record by ID
   */
  async delete(id: number): Promise<PersonalRecord> {
    try {
      return await this.prisma.personalRecord.delete({
        where: { id },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(
            `Personal record with ID ${id} not found`,
          );
        }
      }
      throw error;
    }
  }
}
