import {
  IsOptional,
  IsString,
  IsNumber,
  IsDateString,
  Min,
  IsIn,
} from 'class-validator';
import { Type } from 'class-transformer';
export class ListPersonalRecordsQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  limit?: number;

  @IsOptional()
  @IsString()
  @IsIn(['id', 'createdAt', 'accuracy', 'raw'])
  sort?: string;

  @IsOptional()
  @IsString()
  @IsIn(['asc', 'desc'])
  order?: 'asc' | 'desc';

  @IsOptional()
  @IsString()
  accountId?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  minAccuracy?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  maxAccuracy?: number;
}
