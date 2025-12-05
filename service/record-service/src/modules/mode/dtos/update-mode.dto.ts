// File: src/modules/mode/dtos/update-mode.dto.ts

import { IsString, IsOptional, MinLength } from 'class-validator';

/**
 * DTO for updating an existing mode
 */
export class UpdateModeDto {
  @IsString()
  @IsOptional()
  @MinLength(2)
  name?: string;

  @IsString()
  @IsOptional()
  @MinLength(10)
  description?: string;
}
