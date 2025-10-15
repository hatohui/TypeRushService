import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { UserAchievementRepository } from './user-achievement.repository';
import { CreateUserAchievementDto } from './dtos/create-user-achievement.dto';
import {
  UserAchievementResponseDto,
  UserAchievementListResponseDto,
} from './dtos/user-achievement-response.dto';

/**
 * Service for UserAchievement business logic
 */
@Injectable()
export class UserAchievementService {
  private readonly logger = new Logger(UserAchievementService.name);

  constructor(
    private readonly userAchievementRepository: UserAchievementRepository,
  ) {}

  /**
   * Create a new user achievement
   */
  async create(
    createDto: CreateUserAchievementDto,
  ): Promise<UserAchievementResponseDto> {
    this.logger.log(
      `Creating user achievement - accountId: ${createDto.accountId}, achievementId: ${createDto.achievementId}`,
    );

    const userAchievement =
      await this.userAchievementRepository.create(createDto);
    return new UserAchievementResponseDto(userAchievement);
  }

  /**
   * Find all user achievements with pagination and filters
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
    accountId?: string;
    achievementId?: number;
  }): Promise<UserAchievementListResponseDto> {
    const page = params?.page && params.page > 0 ? params.page : 1;
    const limit =
      params?.limit && params.limit > 0 && params.limit <= 100
        ? params.limit
        : 10;

    this.logger.log(
      `Fetching user achievements - page: ${page}, limit: ${limit}, accountId: ${params?.accountId}, achievementId: ${params?.achievementId}`,
    );

    const { userAchievements, total } =
      await this.userAchievementRepository.findAll({
        page,
        limit,
        accountId: params?.accountId,
        achievementId: params?.achievementId,
      });

    const responseDtos = userAchievements.map(
      (ua) => new UserAchievementResponseDto(ua),
    );

    return new UserAchievementListResponseDto(responseDtos, total, page, limit);
  }

  /**
   * Find a user achievement by composite key
   */
  async findById(
    accountId: string,
    achievementId: number,
  ): Promise<UserAchievementResponseDto> {
    this.logger.log(
      `Fetching user achievement - accountId: ${accountId}, achievementId: ${achievementId}`,
    );
    const userAchievement = await this.userAchievementRepository.findById(
      accountId,
      achievementId,
    );
    return new UserAchievementResponseDto(userAchievement);
  }

  /**
   * Update a user achievement by accountId and achievementId
   */
  async updateUserAchievement(
    accountId: string,
    achievementId: number,
  ): Promise<UserAchievementResponseDto> {
    this.logger.log(
      `Updating user achievement - accountId: ${accountId}, achievementId: ${achievementId}`,
    );

    // Check if the achievement exists
    const achievementExists =
      await this.userAchievementRepository.checkAchievementExists(
        achievementId,
      );
    if (!achievementExists) {
      throw new NotFoundException(
        `Achievement with ID ${achievementId} not found`,
      );
    }

    // Check if the user achievement exists
    const existingUserAchievement =
      await this.userAchievementRepository.findById(accountId, achievementId);
    if (!existingUserAchievement) {
      throw new NotFoundException(
        `User achievement not found for accountId: ${accountId} and achievementId: ${achievementId}`,
      );
    }

    // Perform the update (you can add more fields to update as needed)
    const updatedUserAchievement = await this.userAchievementRepository.update(
      accountId,
      achievementId,
      {
        // Add updateable fields here, for example:
        // updatedAt: new Date(),
        // status: 'completed', // if you add a status field
      },
    );

    return new UserAchievementResponseDto(updatedUserAchievement);
  }

  /**
   * Delete a user achievement by composite key
   */
  async delete(
    accountId: string,
    achievementId: number,
  ): Promise<UserAchievementResponseDto> {
    this.logger.log(
      `Deleting user achievement - accountId: ${accountId}, achievementId: ${achievementId}`,
    );
    const userAchievement = await this.userAchievementRepository.delete(
      accountId,
      achievementId,
    );
    return new UserAchievementResponseDto(userAchievement);
  }
}
