// File: src/modules/personal-record/dtos/personal-record-response.dto.ts

import { Exclude, Expose, Type } from 'class-transformer';

/**
 * DTO for personal record API responses
 */
@Exclude()
export class PersonalRecordResponseDto {
  @Expose()
  id: number;

  @Expose()
  accountId: string;

  @Expose()
  accuracy: number;

  @Expose()
  raw: number;

  @Expose()
  @Type(() => Date)
  createdAt: Date;

  constructor(partial: Partial<PersonalRecordResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for paginated personal record list responses
 */
export class PersonalRecordListResponseDto {
  data: PersonalRecordResponseDto[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;

  constructor(
    data: PersonalRecordResponseDto[],
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
