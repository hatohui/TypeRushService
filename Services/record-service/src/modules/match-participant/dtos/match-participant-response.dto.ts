import { Exclude, Expose, Type } from 'class-transformer';

/**
 * DTO for match history in participant responses
 */
@Exclude()
export class MatchHistoryInParticipantResponseDto {
  @Expose()
  id: number;

  @Expose()
  modeId: number;

  @Expose()
  createdAt: Date;

  constructor(partial: Partial<MatchHistoryInParticipantResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for match participant API responses
 */
@Exclude()
export class MatchParticipantResponseDto {
  @Expose()
  historyId: number;

  @Expose()
  accountId: string;

  @Expose()
  rank: number;

  @Expose()
  accuracy: number;

  @Expose()
  raw: number;

  @Expose()
  @Type(() => MatchHistoryInParticipantResponseDto)
  history?: MatchHistoryInParticipantResponseDto;

  constructor(partial: Partial<MatchParticipantResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for paginated match participant list responses
 */
export class MatchParticipantListResponseDto {
  data: MatchParticipantResponseDto[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;

  constructor(
    data: MatchParticipantResponseDto[],
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
