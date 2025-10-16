import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction } from 'express';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  use(req: Request, _res: Response, next: NextFunction) {
    console.log(
      `[${new Date().toISOString()}] ${req.method} to ${req.url} by ${req.referrer}`,
    );
    next();
  }
}
