import {
  IsInt,
  IsNotEmpty,
  IsArray,
  ValidateNested,
  IsNumber,
  IsString,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO for creating a match participant
 */
export class CreateMatchParticipantDto {
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

/**
 * DTO for creating a new match history
 */
export class CreateMatchHistoryDto {
  @IsInt()
  @IsNotEmpty()
  modeId: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateMatchParticipantDto)
  participants: CreateMatchParticipantDto[];
}
