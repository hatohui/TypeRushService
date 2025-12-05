import { IsInt, IsOptional } from 'class-validator';

/**
 * DTO for updating an existing match history
 * Note: Participants cannot be updated after creation
 */
export class UpdateMatchHistoryDto {
  @IsInt()
  @IsOptional()
  modeId?: number;
}
