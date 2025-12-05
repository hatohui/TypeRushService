import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { MatchParticipantRepository } from './match-participant.repository';
import { CreateMatchParticipantDto } from './dtos/create-match-participant.dto';
import { UpdateMatchParticipantDto } from './dtos/update-match-participant.dto';
import {
  MatchParticipantResponseDto,
  MatchParticipantListResponseDto,
} from './dtos/match-participant-response.dto';

/**
 * Service for MatchParticipant business logic
 */
@Injectable()
export class MatchParticipantService {
  private readonly logger = new Logger(MatchParticipantService.name);

  constructor(
    private readonly matchParticipantRepository: MatchParticipantRepository,
  ) {}

  /**
   * Create a new match participant
   */
  async create(
    createDto: CreateMatchParticipantDto,
  ): Promise<MatchParticipantResponseDto> {
    this.logger.log(
      `Creating match participant - historyId: ${createDto.historyId}, accountId: ${createDto.accountId}`,
    );

    const participant = await this.matchParticipantRepository.create(createDto);
    return new MatchParticipantResponseDto(participant);
  }

  /**
   * Find all match participants with pagination and filters
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
    accountId?: string;
    historyId?: number;
  }): Promise<MatchParticipantListResponseDto> {
    const page = params?.page && params.page > 0 ? params.page : 1;
    const limit =
      params?.limit && params.limit > 0 && params.limit <= 100
        ? params.limit
        : 10;

    this.logger.log(
      `Fetching match participants - page: ${page}, limit: ${limit}, accountId: ${params?.accountId}, historyId: ${params?.historyId}`,
    );

    const { matchParticipants, total } =
      await this.matchParticipantRepository.findAll({
        page,
        limit,
        accountId: params?.accountId,
        historyId: params?.historyId,
      });

    const responseDtos = matchParticipants.map(
      (mp) => new MatchParticipantResponseDto(mp),
    );

    return new MatchParticipantListResponseDto(
      responseDtos,
      total,
      page,
      limit,
    );
  }

  /**
   * Find a match participant by composite key
   */
  async findById(
    historyId: number,
    accountId: string,
  ): Promise<MatchParticipantResponseDto> {
    this.logger.log(
      `Fetching match participant - historyId: ${historyId}, accountId: ${accountId}`,
    );
    const participant = await this.matchParticipantRepository.findById(
      historyId,
      accountId,
    );
    return new MatchParticipantResponseDto(participant);
  }

  /**
   * Update a match participant by composite key
   */
  async update(
    historyId: number,
    accountId: string,
    updateDto: UpdateMatchParticipantDto,
  ): Promise<MatchParticipantResponseDto> {
    if (!updateDto.rank && !updateDto.accuracy && !updateDto.raw) {
      throw new BadRequestException('At least one field must be provided');
    }

    this.logger.log(
      `Updating match participant - historyId: ${historyId}, accountId: ${accountId}`,
    );
    const participant = await this.matchParticipantRepository.update(
      historyId,
      accountId,
      updateDto,
    );
    return new MatchParticipantResponseDto(participant);
  }

  /**
   * Delete a match participant by composite key
   */
  async delete(
    historyId: number,
    accountId: string,
  ): Promise<MatchParticipantResponseDto> {
    this.logger.log(
      `Deleting match participant - historyId: ${historyId}, accountId: ${accountId}`,
    );
    const participant = await this.matchParticipantRepository.delete(
      historyId,
      accountId,
    );
    return new MatchParticipantResponseDto(participant);
  }
}
