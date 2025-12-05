import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { MatchParticipant, Prisma } from '../../../generated/prisma';
import { CreateMatchParticipantDto } from './dtos/create-match-participant.dto';
import { UpdateMatchParticipantDto } from './dtos/update-match-participant.dto';

/**
 * Repository for MatchParticipant entity operations
 */
@Injectable()
export class MatchParticipantRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new match participant
   */
  async create(data: CreateMatchParticipantDto): Promise<MatchParticipant> {
    return this.prisma.matchParticipant.create({
      data: {
        historyId: data.historyId,
        accountId: data.accountId,
        rank: data.rank,
        accuracy: data.accuracy,
        raw: data.raw,
      },
      include: {
        history: true,
      },
    });
  }

  /**
   * Find all match participants with optional pagination and filters
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
    accountId?: string;
    historyId?: number;
  }): Promise<{ matchParticipants: MatchParticipant[]; total: number }> {
    const { page = 1, limit = 10, accountId, historyId } = params || {};
    const skip = (page - 1) * limit;

    const where: Prisma.MatchParticipantWhereInput = {};

    if (accountId) {
      where.accountId = accountId;
    }

    if (historyId) {
      where.historyId = historyId;
    }

    const [matchParticipants, total] = await Promise.all([
      this.prisma.matchParticipant.findMany({
        where,
        skip,
        take: limit,
        orderBy: { rank: 'asc' },
        include: {
          history: true,
        },
      }),
      this.prisma.matchParticipant.count({ where }),
    ]);

    return { matchParticipants, total };
  }

  /**
   * Find a match participant by composite key
   */
  async findById(
    historyId: number,
    accountId: string,
  ): Promise<MatchParticipant> {
    const participant = await this.prisma.matchParticipant.findUnique({
      where: {
        historyId_accountId: {
          historyId,
          accountId,
        },
      },
      include: {
        history: true,
      },
    });

    if (!participant) {
      throw new NotFoundException(
        `Match participant with historyId ${historyId} and accountId ${accountId} not found`,
      );
    }

    return participant;
  }

  /**
   * Update a match participant by composite key
   */
  async update(
    historyId: number,
    accountId: string,
    data: UpdateMatchParticipantDto,
  ): Promise<MatchParticipant> {
    try {
      return await this.prisma.matchParticipant.update({
        where: {
          historyId_accountId: {
            historyId,
            accountId,
          },
        },
        data,
        include: {
          history: true,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(
            `Match participant with historyId ${historyId} and accountId ${accountId} not found`,
          );
        }
      }
      throw error;
    }
  }

  /**
   * Delete a match participant by composite key
   */
  async delete(
    historyId: number,
    accountId: string,
  ): Promise<MatchParticipant> {
    try {
      return await this.prisma.matchParticipant.delete({
        where: {
          historyId_accountId: {
            historyId,
            accountId,
          },
        },
        include: {
          history: true,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(
            `Match participant with historyId ${historyId} and accountId ${accountId} not found`,
          );
        }
      }
      throw error;
    }
  }
}
