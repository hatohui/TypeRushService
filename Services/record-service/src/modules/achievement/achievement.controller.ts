import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
  ValidationPipe,
} from '@nestjs/common';
import { AchievementService } from './achievement.service';
import { CreateAchievementDto } from './dtos/create-achievement.dto';
import { UpdateAchievementDto } from './dtos/update-achievement.dto';
import {
  AchievementResponseDto,
  AchievementListResponseDto,
} from './dtos/achievement-response.dto';
import { IsOptional, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Query DTO for listing achievements
 */
class ListAchievementsQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limit?: number;
}

/**
 * Controller for Achievement endpoints
 */
@Controller('achievements')
export class AchievementController {
  constructor(private readonly achievementService: AchievementService) {}

  /**
   * Create a new achievement
   * POST /achievements
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    createDto: CreateAchievementDto,
  ): Promise<AchievementResponseDto> {
    return this.achievementService.create(createDto);
  }

  /**
   * Get all achievements with pagination
   * GET /achievements
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query(new ValidationPipe({ transform: true, whitelist: true }))
    query: ListAchievementsQueryDto,
  ): Promise<AchievementListResponseDto> {
    return this.achievementService.findAll(query);
  }

  /**
   * Get an achievement by ID
   * GET /achievements/:id
   */
  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findById(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<AchievementResponseDto> {
    return this.achievementService.findById(id);
  }

  /**
   * Update an achievement by ID
   * PUT /achievements/:id
   */
  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    updateDto: UpdateAchievementDto,
  ): Promise<AchievementResponseDto> {
    return this.achievementService.update(id, updateDto);
  }

  /**
   * Delete an achievement by ID
   * DELETE /achievements/:id
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async delete(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<AchievementResponseDto> {
    return this.achievementService.delete(id);
  }
}
