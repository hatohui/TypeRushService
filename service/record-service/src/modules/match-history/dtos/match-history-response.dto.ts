import { Exclude, Expose, Type } from 'class-transformer';

/**
 * DTO for match participant in responses
 */
@Exclude()
export class MatchParticipantResponseDto {
  @Expose()
  accountId: string;

  @Expose()
  rank: number;

  @Expose()
  accuracy: number;

  @Expose()
  raw: number;

  constructor(partial: Partial<MatchParticipantResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for mode in match history responses
 */
@Exclude()
export class ModeInMatchResponseDto {
  @Expose()
  id: number;

  @Expose()
  name: string;

  @Expose()
  description: string;

  constructor(partial: Partial<ModeInMatchResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for match history API responses
 */
@Exclude()
export class MatchHistoryResponseDto {
  @Expose()
  id: number;

  @Expose()
  modeId: number;

  @Expose()
  createdAt: Date;

  @Expose()
  @Type(() => ModeInMatchResponseDto)
  mode?: ModeInMatchResponseDto;

  @Expose()
  @Type(() => MatchParticipantResponseDto)
  participants?: MatchParticipantResponseDto[];

  constructor(partial: Partial<MatchHistoryResponseDto>) {
    Object.assign(this, partial);
  }
}

/**
 * DTO for paginated match history list responses
 */
export class MatchHistoryListResponseDto {
  data: MatchHistoryResponseDto[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;

  constructor(
    data: MatchHistoryResponseDto[],
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
