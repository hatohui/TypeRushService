import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
  ValidationPipe,
} from '@nestjs/common';
import { UserAchievementService } from './user-achievement.service';
import { CreateUserAchievementDto } from './dtos/create-user-achievement.dto';
import {
  UserAchievementResponseDto,
  UserAchievementListResponseDto,
} from './dtos/user-achievement-response.dto';
import { IsOptional, IsNumber, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Query DTO for listing user achievements
 */
class ListUserAchievementsQueryDto {
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

  @IsOptional()
  @IsString()
  accountId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  achievementId?: number;
}

/**
 * Controller for UserAchievement endpoints
 */
@Controller('user-achievements')
export class UserAchievementController {
  constructor(
    private readonly userAchievementService: UserAchievementService,
  ) {}

  /**
   * Create a new user achievement
   * POST /user-achievements
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    createDto: CreateUserAchievementDto,
  ): Promise<UserAchievementResponseDto> {
    return this.userAchievementService.create(createDto);
  }

  /**
   * Get all user achievements with pagination and filters
   * GET /user-achievements
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query(new ValidationPipe({ transform: true, whitelist: true }))
    query: ListUserAchievementsQueryDto,
  ): Promise<UserAchievementListResponseDto> {
    return this.userAchievementService.findAll(query);
  }

  /**
   * Get a user achievement by composite key
   * GET /user-achievements/:accountId/:achievementId
   */
  @Get(':accountId/:achievementId')
  @HttpCode(HttpStatus.OK)
  async findById(
    @Param('accountId') accountId: string,
    @Param('achievementId', ParseIntPipe) achievementId: number,
  ): Promise<UserAchievementResponseDto> {
    return this.userAchievementService.findById(accountId, achievementId);
  }

  /**
   * Delete a user achievement by composite key
   * DELETE /user-achievements/:accountId/:achievementId
   */
  @Delete(':accountId/:achievementId')
  @HttpCode(HttpStatus.OK)
  async delete(
    @Param('accountId') accountId: string,
    @Param('achievementId', ParseIntPipe) achievementId: number,
  ): Promise<UserAchievementResponseDto> {
    return this.userAchievementService.delete(accountId, achievementId);
  }
}
