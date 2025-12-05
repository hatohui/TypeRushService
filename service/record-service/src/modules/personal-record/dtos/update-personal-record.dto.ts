// File: src/modules/personal-record/dtos/update-personal-record.dto.ts

import { IsString, IsNumber, Min, Max, IsOptional } from 'class-validator';

/**
 * DTO for updating an existing personal record
 */
export class UpdatePersonalRecordDto {
  @IsString()
  @IsOptional()
  accountId?: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  accuracy?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  raw?: number;
}
