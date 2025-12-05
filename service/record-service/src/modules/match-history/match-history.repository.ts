import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { MatchHistory, Prisma } from '../../../generated/prisma';
import { CreateMatchHistoryDto } from './dtos/create-match-history.dto';
import { UpdateMatchHistoryDto } from './dtos/update-match-history.dto';

/**
 * Repository for MatchHistory entity operations
 */
@Injectable()
export class MatchHistoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new match history with participants
   */
  async create(data: CreateMatchHistoryDto): Promise<MatchHistory> {
    return this.prisma.matchHistory.create({
      data: {
        modeId: data.modeId,
        participants: {
          create: data.participants.map((p) => ({
            accountId: p.accountId,
            rank: p.rank,
            accuracy: p.accuracy,
            raw: p.raw,
          })),
        },
      },
      include: {
        mode: true,
        participants: true,
      },
    });
  }

  /**
   * Find all match histories with optional pagination and filters
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
    modeId?: number;
    accountId?: string;
  }): Promise<{ matchHistories: MatchHistory[]; total: number }> {
    const { page = 1, limit = 10, modeId, accountId } = params || {};
    const skip = (page - 1) * limit;

    const where: Prisma.MatchHistoryWhereInput = {};

    if (modeId) {
      where.modeId = modeId;
    }

    if (accountId) {
      where.participants = {
        some: {
          accountId,
        },
      };
    }

    const [matchHistories, total] = await Promise.all([
      this.prisma.matchHistory.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          mode: true,
          participants: {
            orderBy: { rank: 'asc' },
          },
        },
      }),
      this.prisma.matchHistory.count({ where }),
    ]);

    return { matchHistories, total };
  }

  /**
   * Find a match history by ID with relations
   */
  async findById(id: number): Promise<MatchHistory> {
    const matchHistory = await this.prisma.matchHistory.findUnique({
      where: { id },
      include: {
        mode: true,
        participants: {
          orderBy: { rank: 'asc' },
        },
      },
    });

    if (!matchHistory) {
      throw new NotFoundException(`Match history with ID ${id} not found`);
    }

    return matchHistory;
  }

  /**
   * Update a match history by ID
   */
  async update(id: number, data: UpdateMatchHistoryDto): Promise<MatchHistory> {
    try {
      return await this.prisma.matchHistory.update({
        where: { id },
        data,
        include: {
          mode: true,
          participants: {
            orderBy: { rank: 'asc' },
          },
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(`Match history with ID ${id} not found`);
        }
      }
      throw error;
    }
  }

  /**
   * Delete a match history by ID
   */
  async delete(id: number): Promise<MatchHistory> {
    try {
      return await this.prisma.matchHistory.delete({
        where: { id },
        include: {
          mode: true,
          participants: true,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(`Match history with ID ${id} not found`);
        }
      }
      throw error;
    }
  }
}
