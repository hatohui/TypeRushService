// File: src/modules/personal-record/personal-record.service.ts

import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import {
  PersonalRecordRepository,
  FindAllParams,
} from './personal-record.repository';
import { CreatePersonalRecordDto } from './dtos/create-personal-record.dto';
import { UpdatePersonalRecordDto } from './dtos/update-personal-record.dto';
import {
  PersonalRecordResponseDto,
  PersonalRecordListResponseDto,
} from './dtos/personal-record-response.dto';

/**
 * Service for PersonalRecord business logic
 */
@Injectable()
export class PersonalRecordService {
  private readonly logger = new Logger(PersonalRecordService.name);

  constructor(
    private readonly personalRecordRepository: PersonalRecordRepository,
  ) {}

  /**
   * Create a new personal record
   */
  async create(
    createDto: CreatePersonalRecordDto,
  ): Promise<PersonalRecordResponseDto> {
    // Business rule validations
    if (createDto.accuracy < 0 || createDto.accuracy > 100) {
      throw new BadRequestException('Accuracy must be between 0 and 100');
    }

    if (createDto.raw < 0) {
      throw new BadRequestException('Raw WPM cannot be negative');
    }

    this.logger.log(
      `Creating personal record for account: ${createDto.accountId}`,
    );

    const record = await this.personalRecordRepository.create(createDto);
    return new PersonalRecordResponseDto(record);
  }

  /**
   * Find all personal records with filtering and pagination
   */
  async findAll(
    params?: FindAllParams,
  ): Promise<PersonalRecordListResponseDto> {
    const page = params?.page && params.page > 0 ? params.page : 1;
    const limit =
      params?.limit && params.limit > 0 && params.limit <= 100
        ? params.limit
        : 10;

    // Validate sort field
    const validSortFields = ['id', 'createdAt', 'accuracy', 'raw'];
    const sortField = params?.sort || 'createdAt';

    if (!validSortFields.includes(sortField)) {
      throw new BadRequestException(
        `Invalid sort field. Must be one of: ${validSortFields.join(', ')}`,
      );
    }

    this.logger.log(
      `Fetching personal records - page: ${page}, limit: ${limit}`,
    );

    const { records, total } = await this.personalRecordRepository.findAll({
      ...params,
      page,
      limit,
      sort: sortField,
    });

    const responseDtos = records.map(
      (record) => new PersonalRecordResponseDto(record),
    );

    return new PersonalRecordListResponseDto(responseDtos, total, page, limit);
  }

  /**
   * Find a personal record by ID
   */
  async findById(id: string): Promise<PersonalRecordResponseDto> {
    this.logger.log(`Fetching personal record with id: ${id}`);
    const record = await this.personalRecordRepository.findById(id);
    return new PersonalRecordResponseDto(record);
  }

  /**
   * Update a personal record by ID
   */
  async update(
    id: number,
    updateDto: UpdatePersonalRecordDto,
  ): Promise<PersonalRecordResponseDto> {
    // Business rule validations
    if (
      updateDto.accuracy !== undefined &&
      (updateDto.accuracy < 0 || updateDto.accuracy > 100)
    ) {
      throw new BadRequestException('Accuracy must be between 0 and 100');
    }

    if (updateDto.raw !== undefined && updateDto.raw < 0) {
      throw new BadRequestException('Raw WPM cannot be negative');
    }

    this.logger.log(`Updating personal record with id: ${id}`);
    const record = await this.personalRecordRepository.update(id, updateDto);
    return new PersonalRecordResponseDto(record);
  }

  /**
   * Delete a personal record by ID
   */
  async delete(id: number): Promise<PersonalRecordResponseDto> {
    this.logger.log(`Deleting personal record with id: ${id}`);
    const record = await this.personalRecordRepository.delete(id);
    return new PersonalRecordResponseDto(record);
  }
}
