// File: src/modules/mode/dtos/mode-response.dto.ts

import { Exclude, Expose } from 'class-transformer';

/**
 * DTO for mode API responses
 */
@Exclude()
export class ModeResponseDto {
  @Expose()
  id: number;

  @Expose()
  name: string;

  @Expose()
  description: string;

  constructor(partial: Partial<ModeResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for paginated mode list responses
 */
export class ModeListResponseDto {
  data: ModeResponseDto[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;

  constructor(
    data: ModeResponseDto[],
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
