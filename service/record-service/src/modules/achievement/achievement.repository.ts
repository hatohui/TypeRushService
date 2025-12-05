import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Achievement, Prisma } from '../../../generated/prisma';
import { CreateAchievementDto } from './dtos/create-achievement.dto';
import { UpdateAchievementDto } from './dtos/update-achievement.dto';

/**
 * Repository for Achievement entity operations
 */
@Injectable()
export class AchievementRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new achievement
   */
  async create(data: CreateAchievementDto): Promise<Achievement> {
    return this.prisma.achievement.create({
      data: {
        name: data.name,
        description: data.description,
        wpmCriteria: data.wpmCriteria,
      },
    });
  }

  /**
   * Find all achievements with optional pagination
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
  }): Promise<{ achievements: Achievement[]; total: number }> {
    const { page = 1, limit = 10 } = params || {};
    const skip = (page - 1) * limit;

    const [achievements, total] = await Promise.all([
      this.prisma.achievement.findMany({
        skip,
        take: limit,
        orderBy: { wpmCriteria: 'asc' },
      }),
      this.prisma.achievement.count(),
    ]);

    return { achievements, total };
  }

  /**
   * Find an achievement by ID
   */
  async findById(id: number): Promise<Achievement> {
    const achievement = await this.prisma.achievement.findUnique({
      where: { id },
    });

    if (!achievement) {
      throw new NotFoundException(`Achievement with ID ${id} not found`);
    }

    return achievement;
  }

  /**
   * Update an achievement by ID
   */
  async update(id: number, data: UpdateAchievementDto): Promise<Achievement> {
    try {
      return await this.prisma.achievement.update({
        where: { id },
        data,
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(`Achievement with ID ${id} not found`);
        }
      }
      throw error;
    }
  }

  /**
   * Delete an achievement by ID
   */
  async delete(id: number): Promise<Achievement> {
    try {
      return await this.prisma.achievement.delete({
        where: { id },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(`Achievement with ID ${id} not found`);
        }
      }
      throw error;
    }
  }
}
