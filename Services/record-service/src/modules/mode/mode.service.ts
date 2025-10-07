// File: src/modules/mode/mode.service.ts

import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ModeRepository } from './mode.repository';
import { CreateModeDto } from './dtos/create-mode.dto';
import { UpdateModeDto } from './dtos/update-mode.dto';
import { ModeResponseDto, ModeListResponseDto } from './dtos/mode-response.dto';

/**
 * Service for Mode business logic
 */
@Injectable()
export class ModeService {
  private readonly logger = new Logger(ModeService.name);

  constructor(private readonly modeRepository: ModeRepository) {}

  /**
   * Create a new mode
   */
  async create(createDto: CreateModeDto): Promise<ModeResponseDto> {
    this.logger.log(`Creating mode: ${createDto.name}`);

    const mode = await this.modeRepository.create(createDto);
    return new ModeResponseDto(mode);
  }

  /**
   * Find all modes with pagination
   */
  async findAll(params?: {
    page?: number;
    limit?: number;
  }): Promise<ModeListResponseDto> {
    const page = params?.page && params.page > 0 ? params.page : 1;
    const limit =
      params?.limit && params.limit > 0 && params.limit <= 100
        ? params.limit
        : 10;

    this.logger.log(`Fetching modes - page: ${page}, limit: ${limit}`);

    const { modes, total } = await this.modeRepository.findAll({
      page,
      limit,
    });

    const responseDtos = modes.map((mode) => new ModeResponseDto(mode));

    return new ModeListResponseDto(responseDtos, total, page, limit);
  }

  /**
   * Find a mode by ID
   */
  async findById(id: number): Promise<ModeResponseDto> {
    this.logger.log(`Fetching mode with id: ${id}`);
    const mode = await this.modeRepository.findById(id);
    return new ModeResponseDto(mode);
  }

  /**
   * Update a mode by ID
   */
  async update(id: number, updateDto: UpdateModeDto): Promise<ModeResponseDto> {
    if (!updateDto.name && !updateDto.description) {
      throw new BadRequestException('At least one field must be provided');
    }

    this.logger.log(`Updating mode with id: ${id}`);
    const mode = await this.modeRepository.update(id, updateDto);
    return new ModeResponseDto(mode);
  }

  /**
   * Delete a mode by ID
   */
  async delete(id: number): Promise<ModeResponseDto> {
    this.logger.log(`Deleting mode with id: ${id}`);
    const mode = await this.modeRepository.delete(id);
    return new ModeResponseDto(mode);
  }
}
