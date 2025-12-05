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
import { MatchHistoryService } from './match-history.service';
import { CreateMatchHistoryDto } from './dtos/create-match-history.dto';
import { UpdateMatchHistoryDto } from './dtos/update-match-history.dto';
import {
  MatchHistoryResponseDto,
  MatchHistoryListResponseDto,
} from './dtos/match-history-response.dto';
import { IsOptional, IsNumber, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Query DTO for listing match histories
 */
class ListMatchHistoriesQueryDto {
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

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  modeId?: number;

  @IsOptional()
  @IsString()
  accountId?: string;
}

/**
 * Controller for MatchHistory endpoints
 */
@Controller('match-histories')
export class MatchHistoryController {
  constructor(private readonly matchHistoryService: MatchHistoryService) {}

  /**
   * Create a new match history
   * POST /match-histories
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    createDto: CreateMatchHistoryDto,
  ): Promise<MatchHistoryResponseDto> {
    return this.matchHistoryService.create(createDto);
  }

  /**
   * Get all match histories with pagination and filters
   * GET /match-histories
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query(new ValidationPipe({ transform: true, whitelist: true }))
    query: ListMatchHistoriesQueryDto,
  ): Promise<MatchHistoryListResponseDto> {
    return this.matchHistoryService.findAll(query);
  }

  /**
   * Get a match history by ID
   * GET /match-histories/:id
   */
  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findById(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<MatchHistoryResponseDto> {
    return this.matchHistoryService.findById(id);
  }

  /**
   * Update a match history by ID
   * PUT /match-histories/:id
   */
  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    updateDto: UpdateMatchHistoryDto,
  ): Promise<MatchHistoryResponseDto> {
    return this.matchHistoryService.update(id, updateDto);
  }

  /**
   * Delete a match history by ID
   * DELETE /match-histories/:id
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async delete(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<MatchHistoryResponseDto> {
    return this.matchHistoryService.delete(id);
  }
}
