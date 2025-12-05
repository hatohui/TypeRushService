// File: src/modules/mode/mode.repository.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Mode, Prisma } from '../../../generated/prisma';
import { CreateModeDto } from './dtos/create-mode.dto';
import { UpdateModeDto } from './dtos/update-mode.dto';

/**
 * Repository for Mode entity operations
 */
@Injectable()
export class ModeRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new mode
   */
  async create(data: CreateModeDto): Promise<Mode> {
    return this.prisma.mode.create({
      data: {
        name: data.name,
        description: data.description,
      },
    });
  }

  /**
   * Find all modes with optional pagination
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
  }): Promise<{ modes: Mode[]; total: number }> {
    const { page = 1, limit = 10 } = params || {};
    const skip = (page - 1) * limit;

    const [modes, total] = await Promise.all([
      this.prisma.mode.findMany({
        skip,
        take: limit,
        orderBy: { id: 'asc' },
      }),
      this.prisma.mode.count(),
    ]);

    return { modes, total };
  }

  /**
   * Find a mode by ID with optional relations
   */
  async findById(id: number, includeMatchHistories = false): Promise<Mode> {
    const mode = await this.prisma.mode.findUnique({
      where: { id },
      include: {
        matchHistories: includeMatchHistories,
      },
    });

    if (!mode) {
      throw new NotFoundException(`Mode with ID ${id} not found`);
    }

    return mode;
  }

  /**
   * Update a mode by ID
   */
  async update(id: number, data: UpdateModeDto): Promise<Mode> {
    try {
      return await this.prisma.mode.update({
        where: { id },
        data,
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(`Mode with ID ${id} not found`);
        }
      }
      throw error;
    }
  }

  /**
   * Delete a mode by ID
   */
  async delete(id: number): Promise<Mode> {
    try {
      return await this.prisma.mode.delete({
        where: { id },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2025') {
          throw new NotFoundException(`Mode with ID ${id} not found`);
        }
      }
      throw error;
    }
  }
}
