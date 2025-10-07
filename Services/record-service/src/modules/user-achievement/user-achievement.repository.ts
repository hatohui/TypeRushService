import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { UserAchievement, Prisma } from '../../../generated/prisma';
import { CreateUserAchievementDto } from './dtos/create-user-achievement.dto';

/**
 * Repository for UserAchievement entity operations
 */
@Injectable()
export class UserAchievementRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new user achievement
   */
  async create(data: CreateUserAchievementDto): Promise<UserAchievement> {
    return this.prisma.userAchievement.create({
      data: {
        accountId: data.accountId,
        achievementId: data.achievementId,
      },
      include: {
        achievement: true,
      },
    });
  }

  /**
   * Find all user achievements with optional pagination and filters
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
    accountId?: string;
    achievementId?: number;
  }): Promise<{ userAchievements: UserAchievement[]; total: number }> {
    const { page = 1, limit = 10, accountId, achievementId } = params || {};
    const skip = (page - 1) * limit;

    const where: Prisma.UserAchievementWhereInput = {};

    if (accountId) {
      where.accountId = accountId;
    }

    if (achievementId) {
      where.achievementId = achievementId;
    }

    const [userAchievements, total] = await Promise.all([
      this.prisma.userAchievement.findMany({
        where,
        skip,
        take: limit,
        orderBy: { achievementId: 'asc' },
        include: {
          achievement: true,
        },
      }),
      this.prisma.userAchievement.count({ where }),
    ]);

    return { userAchievements, total };
  }

  /**
   * Find a user achievement by composite key
   */
  async findById(
    accountId: string,
    achievementId: number,
  ): Promise<UserAchievement> {
    const userAchievement = await this.prisma.userAchievement.findUnique({
      where: {
        accountId_achievementId: {
          accountId,
          achievementId,
        },
      },
      include: {
        achievement: true,
      },
    });

    if (!userAchievement) {
      throw new NotFoundException(
        `User achievement with accountId ${accountId} and achievementId ${achievementId} not found`,
      );
    }

    return userAchievement;
  }

  /**
   * Delete a user achievement by composite key
   */
  async delete(
    accountId: string,
    achievementId: number,
  ): Promise<UserAchievement> {
    try {
      return await this.prisma.userAchievement.delete({
        where: {
          accountId_achievementId: {
            accountId,
            achievementId,
          },
        },
        include: {
          achievement: true,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(
            `User achievement with accountId ${accountId} and achievementId ${achievementId} not found`,
          );
        }
      }
      throw error;
    }
  }
}
