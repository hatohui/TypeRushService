import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { AchievementRepository } from './achievement.repository';
import { CreateAchievementDto } from './dtos/create-achievement.dto';
import { UpdateAchievementDto } from './dtos/update-achievement.dto';
import {
  AchievementResponseDto,
  AchievementListResponseDto,
} from './dtos/achievement-response.dto';

/**
 * Service for Achievement business logic
 */
@Injectable()
export class AchievementService {
  private readonly logger = new Logger(AchievementService.name);

  constructor(private readonly achievementRepository: AchievementRepository) {}

  /**
   * Create a new achievement
   */
  async create(
    createDto: CreateAchievementDto,
  ): Promise<AchievementResponseDto> {
    this.logger.log(`Creating achievement: ${createDto.name}`);

    const achievement = await this.achievementRepository.create(createDto);
    return new AchievementResponseDto(achievement);
  }

  /**
   * Find all achievements with pagination
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
  }): Promise<AchievementListResponseDto> {
    const page = params?.page && params.page > 0 ? params.page : 1;
    const limit =
      params?.limit && params.limit > 0 && params.limit <= 100
        ? params.limit
        : 10;

    this.logger.log(`Fetching achievements - page: ${page}, limit: ${limit}`);

    const { achievements, total } = await this.achievementRepository.findAll({
      page,
      limit,
    });

    const responseDtos = achievements.map(
      (achievement) => new AchievementResponseDto(achievement),
    );

    return new AchievementListResponseDto(responseDtos, total, page, limit);
  }

  /**
   * Find an achievement by ID
   */
  async findById(id: number): Promise<AchievementResponseDto> {
    this.logger.log(`Fetching achievement with id: ${id}`);
    const achievement = await this.achievementRepository.findById(id);
    return new AchievementResponseDto(achievement);
  }

  /**
   * Update an achievement by ID
   */
  async update(
    id: number,
    updateDto: UpdateAchievementDto,
  ): Promise<AchievementResponseDto> {
    if (!updateDto.name && !updateDto.description && !updateDto.wpmCriteria) {
      throw new BadRequestException('At least one field must be provided');
    }

    this.logger.log(`Updating achievement with id: ${id}`);
    const achievement = await this.achievementRepository.update(id, updateDto);
    return new AchievementResponseDto(achievement);
  }

  /**
   * Delete an achievement by ID
   */
  async delete(id: number): Promise<AchievementResponseDto> {
    this.logger.log(`Deleting achievement with id: ${id}`);
    const achievement = await this.achievementRepository.delete(id);
    return new AchievementResponseDto(achievement);
  }
}
