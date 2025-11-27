import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { MatchHistoryRepository } from './match-history.repository';
import { CreateMatchHistoryDto } from './dtos/create-match-history.dto';
import { UpdateMatchHistoryDto } from './dtos/update-match-history.dto';
import {
  MatchHistoryResponseDto,
  MatchHistoryListResponseDto,
} from './dtos/match-history-response.dto';

/**
 * Service for MatchHistory business logic
 */
@Injectable()
export class MatchHistoryService {
  private readonly logger = new Logger(MatchHistoryService.name);

  constructor(
    private readonly matchHistoryRepository: MatchHistoryRepository,
  ) {}

  /**
   * Create a new match history
   */
  async create(
    createDto: CreateMatchHistoryDto,
  ): Promise<MatchHistoryResponseDto> {
    if (!createDto.participants || createDto.participants.length === 0) {
      throw new BadRequestException(
        'Match history must have at least one participant',
      );
    }

    this.logger.log(
      `Creating match history for mode ${createDto.modeId} with ${createDto.participants.length} participants`,
    );

    const matchHistory = await this.matchHistoryRepository.create(createDto);
    return new MatchHistoryResponseDto(matchHistory);
  }

  /**
   * Find all match histories with pagination and filters
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
    modeId?: number;
    accountId?: string;
  }): Promise<MatchHistoryListResponseDto> {
    const page = params?.page && params.page > 0 ? params.page : 1;
    const limit =
      params?.limit && params.limit > 0 && params.limit <= 100
        ? params.limit
        : 10;

    this.logger.log(
      `Fetching match histories - page: ${page}, limit: ${limit}, modeId: ${params?.modeId}, accountId: ${params?.accountId}`,
    );

    const { matchHistories, total } = await this.matchHistoryRepository.findAll(
      {
        page,
        limit,
        modeId: params?.modeId,
        accountId: params?.accountId,
      },
    );

    const responseDtos = matchHistories.map(
      (mh) => new MatchHistoryResponseDto(mh),
    );

    return new MatchHistoryListResponseDto(responseDtos, total, page, limit);
  }

  /**
   * Find a match history by ID
   */
  async findById(id: number): Promise<MatchHistoryResponseDto> {
    this.logger.log(`Fetching match history with id: ${id}`);
    const matchHistory = await this.matchHistoryRepository.findById(id);
    return new MatchHistoryResponseDto(matchHistory);
  }

  /**
   * Update a match history by ID
   */
  async update(
    id: number,
    updateDto: UpdateMatchHistoryDto,
  ): Promise<MatchHistoryResponseDto> {
    if (!updateDto.modeId) {
      throw new BadRequestException('At least one field must be provided');
    }

    this.logger.log(`Updating match history with id: ${id}`);
    const matchHistory = await this.matchHistoryRepository.update(
      id,
      updateDto,
    );
    return new MatchHistoryResponseDto(matchHistory);
  }

  /**
   * Delete a match history by ID
   */
  async delete(id: number): Promise<MatchHistoryResponseDto> {
    this.logger.log(`Deleting match history with id: ${id}`);
    const matchHistory = await this.matchHistoryRepository.delete(id);
    return new MatchHistoryResponseDto(matchHistory);
  }
}
