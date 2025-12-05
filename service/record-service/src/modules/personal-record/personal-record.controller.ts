// File: src/modules/personal-record/personal-record.controller.ts

import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
  ValidationPipe,
  ParseUUIDPipe,
  //UseGuards,
} from '@nestjs/common';
import { PersonalRecordService } from './personal-record.service';
import { CreatePersonalRecordDto } from './dtos/create-personal-record.dto';
import { UpdatePersonalRecordDto } from './dtos/update-personal-record.dto';
import {
  PersonalRecordResponseDto,
  PersonalRecordListResponseDto,
} from './dtos/personal-record-response.dto';

//import { PermissionGuard } from 'src/common/guards/permission.guard';
import { ListPersonalRecordsQueryDto } from './dtos/list-personalrecord-query.dto';

/**
 * Query DTO for listing personal records with filters
 */

/**
 * Controller for PersonalRecord endpoints
 * Uncomment @ApiTags if using Swagger: @ApiTags('personal-records')
 */
@Controller('personal-records')
export class PersonalRecordController {
  constructor(private readonly personalRecordService: PersonalRecordService) {}

  /**
   * Create a new personal record
   * POST /personal-records
   * Uncomment @ApiOperation if using Swagger: @ApiOperation({ summary: 'Create a new personal record' })
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    createDto: CreatePersonalRecordDto,
  ): Promise<PersonalRecordResponseDto> {
    return this.personalRecordService.create(createDto);
  }

  /**
   * Get all personal records with filtering and pagination
   * GET /personal-records
   * Query params: page, limit, sort, order, accountId, startDate, endDate, minAccuracy, maxAccuracy
   * Uncomment @ApiOperation if using Swagger: @ApiOperation({ summary: 'Get all personal records' })
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query(new ValidationPipe({ transform: true, whitelist: true }))
    query: ListPersonalRecordsQueryDto,
  ): Promise<PersonalRecordListResponseDto> {
    return this.personalRecordService.findAll(query);
  }

  /**
   * Get a personal record by ID
   * GET /personal-records/:id
   * Uncomment @ApiOperation if using Swagger: @ApiOperation({ summary: 'Get personal record by ID' })
   */
  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<PersonalRecordResponseDto> {
    return this.personalRecordService.findById(id);
  }

  /**
   * Update a personal record by ID
   * PATCH /personal-records/:id
   * Uncomment @ApiOperation if using Swagger: @ApiOperation({ summary: 'Update personal record' })
   */
  @Patch(':id')
  @HttpCode(HttpStatus.OK)
  // @UseGuards(PermissionGuard)
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    updateDto: UpdatePersonalRecordDto,
  ): Promise<PersonalRecordResponseDto> {
    return this.personalRecordService.update(id, updateDto);
  }

  /**
   * Delete a personal record by ID
   * DELETE /personal-records/:id
   * Uncomment @ApiOperation if using Swagger: @ApiOperation({ summary: 'Delete personal record' })
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async delete(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<PersonalRecordResponseDto> {
    return this.personalRecordService.delete(id);
  }
}
