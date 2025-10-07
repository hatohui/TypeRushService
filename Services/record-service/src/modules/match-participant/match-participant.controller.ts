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
import { MatchParticipantService } from './match-participant.service';
import { CreateMatchParticipantDto } from './dtos/create-match-participant.dto';
import { UpdateMatchParticipantDto } from './dtos/update-match-participant.dto';
import {
  MatchParticipantResponseDto,
  MatchParticipantListResponseDto,
} from './dtos/match-participant-response.dto';
import { IsOptional, IsNumber, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Query DTO for listing match participants
 */
class ListMatchParticipantsQueryDto {
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
  @IsString()
  accountId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  historyId?: number;
}

/**
 * Controller for MatchParticipant endpoints
 */
@Controller('match-participants')
export class MatchParticipantController {
  constructor(
    private readonly matchParticipantService: MatchParticipantService,
  ) {}

  /**
   * Create a new match participant
   * POST /match-participants
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    createDto: CreateMatchParticipantDto,
  ): Promise<MatchParticipantResponseDto> {
    return this.matchParticipantService.create(createDto);
  }

  /**
   * Get all match participants with pagination and filters
   * GET /match-participants
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query(new ValidationPipe({ transform: true, whitelist: true }))
    query: ListMatchParticipantsQueryDto,
  ): Promise<MatchParticipantListResponseDto> {
    return this.matchParticipantService.findAll(query);
  }

  /**
   * Get a match participant by composite key
   * GET /match-participants/:historyId/:accountId
   */
  @Get(':historyId/:accountId')
  @HttpCode(HttpStatus.OK)
  async findById(
    @Param('historyId', ParseIntPipe) historyId: number,
    @Param('accountId') accountId: string,
  ): Promise<MatchParticipantResponseDto> {
    return this.matchParticipantService.findById(historyId, accountId);
  }

  /**
   * Update a match participant by composite key
   * PUT /match-participants/:historyId/:accountId
   */
  @Put(':historyId/:accountId')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('historyId', ParseIntPipe) historyId: number,
    @Param('accountId') accountId: string,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    updateDto: UpdateMatchParticipantDto,
  ): Promise<MatchParticipantResponseDto> {
    return this.matchParticipantService.update(historyId, accountId, updateDto);
  }

  /**
   * Delete a match participant by composite key
   * DELETE /match-participants/:historyId/:accountId
   */
  @Delete(':historyId/:accountId')
  @HttpCode(HttpStatus.OK)
  async delete(
    @Param('historyId', ParseIntPipe) historyId: number,
    @Param('accountId') accountId: string,
  ): Promise<MatchParticipantResponseDto> {
    return this.matchParticipantService.delete(historyId, accountId);
  }
}
