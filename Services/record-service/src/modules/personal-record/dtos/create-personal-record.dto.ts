// File: src/modules/personal-record/dtos/create-personal-record.dto.ts

import { IsString, IsNumber, Min, Max, IsNotEmpty } from 'class-validator';

/**
 * DTO for creating a new personal record
 */
export class CreatePersonalRecordDto {
  @IsString()
  @IsNotEmpty()
  accountId: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  accuracy: number;

  @IsNumber()
  @Min(0)
  raw: number;
}
