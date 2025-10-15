import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBody,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { UserAchievementService } from './user-achievement.service';
import {
  UserAchievementResponseDto,
  UserAchievementListResponseDto,
} from './dtos/user-achievement-response.dto';
import { IsInt, IsNotEmpty } from 'class-validator';

/**
 * Inline DTO for POST/PATCH/DELETE body containing achievementId
 */
class AchievementIdBodyDto {
  @IsInt()
  @IsNotEmpty()
  achievementId: number;
}

/**
 * Controller for UserAchievement endpoints
 */
@ApiTags('User Achievements')
@ApiBearerAuth('JWT-auth')
@Controller('user-achievements')
export class UserAchievementController {
  constructor(
    private readonly userAchievementService: UserAchievementService,
  ) {}

  /**
   * Get all achievements for a specific account
   * GET /user-achievements/:accountId
   */
  @Get(':accountId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get all achievements of an account' })
  @ApiParam({ name: 'accountId', type: 'string', description: 'Account ID' })
  @ApiResponse({
    status: 200,
    description: 'List of user achievements',
    type: UserAchievementListResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Account not found' })
  async findByAccount(
    @Param('accountId') accountId: string,
  ): Promise<UserAchievementListResponseDto> {
    return this.userAchievementService.findAll({ accountId });
  }

  /**
   * Unlock an achievement for an account
   * POST /user-achievements/:accountId
   */
  @Post(':accountId')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Unlock an achievement for an account' })
  @ApiParam({ name: 'accountId', type: 'string', description: 'Account ID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        achievementId: { type: 'number', example: 1 },
      },
      required: ['achievementId'],
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Achievement unlocked successfully',
    type: UserAchievementResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 404, description: 'Achievement not found' })
  @ApiResponse({ status: 409, description: 'Achievement already unlocked' })
  async create(
    @Param('accountId') accountId: string,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    body: AchievementIdBodyDto,
  ): Promise<UserAchievementResponseDto> {
    return this.userAchievementService.create({
      accountId,
      achievementId: body.achievementId,
    });
  }

  /**
   * Update/verify an achievement for an account
   * PATCH /user-achievements/:accountId
   */
  @Patch(':accountId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update an achievement for an account' })
  @ApiParam({ name: 'accountId', type: 'string', description: 'Account ID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        achievementId: { type: 'number', example: 1 },
      },
      required: ['achievementId'],
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Achievement updated successfully',
    type: UserAchievementResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 404, description: 'Achievement not found' })
  async update(
    @Param('accountId') accountId: string,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    body: AchievementIdBodyDto,
  ): Promise<UserAchievementResponseDto> {
    return this.userAchievementService.updateUserAchievement(
      accountId,
      body.achievementId,
    );
  }

  /**
   * Remove an achievement from an account
   * DELETE /user-achievements/:accountId
   */
  @Delete(':accountId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Remove an achievement from an account' })
  @ApiParam({ name: 'accountId', type: 'string', description: 'Account ID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        achievementId: { type: 'number', example: 1 },
      },
      required: ['achievementId'],
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Achievement removed successfully',
    type: UserAchievementResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 404, description: 'Achievement not found' })
  async delete(
    @Param('accountId') accountId: string,
    @Body(new ValidationPipe({ transform: true, whitelist: true }))
    body: AchievementIdBodyDto,
  ): Promise<UserAchievementResponseDto> {
    return this.userAchievementService.delete(accountId, body.achievementId);
  }
}
