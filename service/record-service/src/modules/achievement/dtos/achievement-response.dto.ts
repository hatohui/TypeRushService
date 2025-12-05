import { Exclude, Expose } from 'class-transformer';

/**
 * DTO for achievement API responses
 */
@Exclude()
export class AchievementResponseDto {
  @Expose()
  id: number;

  @Expose()
  name: string;

  @Expose()
  description: string;

  @Expose()
  wpmCriteria: number;

  constructor(partial: Partial<AchievementResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for paginated achievement list responses
 */
export class AchievementListResponseDto {
  data: AchievementResponseDto[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;

  constructor(
    data: AchievementResponseDto[],
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
