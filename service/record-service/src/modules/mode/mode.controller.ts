// File: src/modules/mode/mode.controller.ts

import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
  ValidationPipe,
} from '@nestjs/common';
import { ModeService } from './mode.service';
import { CreateModeDto } from './dtos/create-mode.dto';
import { UpdateModeDto } from './dtos/update-mode.dto';
import { ModeResponseDto, ModeListResponseDto } from './dtos/mode-response.dto';
import { IsOptional, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Query DTO for listing modes
 */
class ListModesQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limit?: number;
}

/**
 * Controller for Mode endpoints
 */
@Controller('modes')
export class ModeController {
  constructor(private readonly modeService: ModeService) {}

  /**
   * Create a new mode
   * POST /modes
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    createDto: CreateModeDto,
  ): Promise<ModeResponseDto> {
    return this.modeService.create(createDto);
  }

  /**
   * Get all modes with pagination
   * GET /modes
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query(new ValidationPipe({ transform: true, whitelist: true }))
    query: ListModesQueryDto,
  ): Promise<ModeListResponseDto> {
    return this.modeService.findAll(query);
  }

  /**
   * Get a mode by ID
   * GET /modes/:id
   */
  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findById(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<ModeResponseDto> {
    return this.modeService.findById(id);
  }

  /**
   * Update a mode by ID
   * PUT /modes/:id
   */
  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    updateDto: UpdateModeDto,
  ): Promise<ModeResponseDto> {
    return this.modeService.update(id, updateDto);
  }

  /**
   * Delete a mode by ID
   * DELETE /modes/:id
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async delete(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<ModeResponseDto> {
    return this.modeService.delete(id);
  }
}
