import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

/**
 * JWT Payload interface for type safety
 */
interface JwtPayload {
  user_id: string;
  perm_id: number;
  role?: string;
  exp: number;
  iat?: number;
}

/**
 * Permission response from Authorization Service
 */
interface PermissionResponse {
  perm_id: number;
  name: string;
  description?: string;
}

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly httpService: HttpService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    // Check if Authorization header exists
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException(
        'Missing or invalid Authorization header',
      );
    }

    const token = authHeader.replace('Bearer ', '');

    try {
      // Verify and decode JWT token with type safety
      const decoded = this.jwtService.verify<JwtPayload>(token);

      // Validate required fields in token
      if (!decoded.perm_id) {
        throw new ForbiddenException('Token missing required permission ID');
      }

      // Call Authorization Service to get permission details
      const { data: permission } = await firstValueFrom(
        this.httpService.get<PermissionResponse>(
          `http://localhost:3000/api/v1/permissions/${decoded.perm_id}`,
          {
            timeout: 5000, // 5 second timeout
            headers: {
              'Content-Type': 'application/json',
            },
          },
        ),
      );

      // Check if user has admin permission
      if (!permission || permission.name !== 'admin') {
        throw new ForbiddenException(
          'You do not have permission to perform this action',
        );
      }

      // Attach user info to request for use in controllers
      request.user = {
        userId: decoded.user_id,
        permissionId: decoded.perm_id,
        role: decoded.role,
      };

      return true;
    } catch (error) {
      // Handle different types of errors
      if (
        error instanceof ForbiddenException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }

      // Handle JWT verification errors
      if (error.name === 'JsonWebTokenError') {
        throw new UnauthorizedException('Invalid token format');
      }

      if (error.name === 'TokenExpiredError') {
        throw new UnauthorizedException('Token has expired');
      }

      // Handle HTTP request errors (Authorization Service down)
      if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
        throw new ForbiddenException('Permission service unavailable');
      }

      // Generic error fallback
      throw new ForbiddenException('Permission verification failed');
    }
  }
}
