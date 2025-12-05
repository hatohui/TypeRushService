import {
  IsString,
  IsNotEmpty,
  IsInt,
  IsNumber,
  Min,
  Max,
} from 'class-validator';

/**
 * DTO for creating a new match participant
 */
export class CreateMatchParticipantDto {
  @IsInt()
  @IsNotEmpty()
  historyId: number;

  @IsString()
  @IsNotEmpty()
  accountId: string;

  @IsInt()
  @Min(1)
  rank: number;

  @IsNumber()
  @Min(0)
  @Max(100)
  accuracy: number;

  @IsNumber()
  @Min(0)
  raw: number;
}
