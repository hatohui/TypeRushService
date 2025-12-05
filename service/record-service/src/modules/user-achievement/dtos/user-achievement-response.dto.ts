import { Exclude, Expose, Type } from 'class-transformer';

/**
 * DTO for achievement in user achievement responses
 */
@Exclude()
export class AchievementInUserAchievementResponseDto {
  @Expose()
  id: number;

  @Expose()
  name: string;

  @Expose()
  description: string;

  @Expose()
  wpmCriteria: number;

  constructor(partial: Partial<AchievementInUserAchievementResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for user achievement API responses
 */
@Exclude()
export class UserAchievementResponseDto {
  @Expose()
  accountId: string;

  @Expose()
  achievementId: number;

  @Expose()
  @Type(() => AchievementInUserAchievementResponseDto)
  achievement?: AchievementInUserAchievementResponseDto;

  constructor(partial: Partial<UserAchievementResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for paginated user achievement list responses
 */
export class UserAchievementListResponseDto {
  data: UserAchievementResponseDto[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;

  constructor(
    data: UserAchievementResponseDto[],
    total: number,
    page: number,
    limit: number,
  ) {
    this.data = data;
    this.total = total;
    this.page = page;
    this.limit = limit;
    this.totalPages = Math.ceil(total / limit);
  }
}
