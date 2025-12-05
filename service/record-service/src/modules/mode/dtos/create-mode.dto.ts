// File: src/modules/mode/dtos/create-mode.dto.ts

import { IsString, IsNotEmpty, MinLength } from 'class-validator';

/**
 * DTO for creating a new mode
 */
export class CreateModeDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  name: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  description: string;
}
