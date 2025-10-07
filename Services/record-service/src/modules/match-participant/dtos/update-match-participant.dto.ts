import { IsInt, IsNumber, IsOptional, Min, Max } from 'class-validator';

/**
 * DTO for updating an existing match participant
 */
export class UpdateMatchParticipantDto {
  @IsInt()
  @IsOptional()
  @Min(1)
  rank?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  @Max(100)
  accuracy?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  raw?: number;
}
