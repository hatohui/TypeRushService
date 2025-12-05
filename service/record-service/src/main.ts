import { NestFactory } from '@nestjs/core';
//import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );

  // ==================== Swagger Configuration ====================
  // This configuration automatically discovers and includes ALL controllers
  // from all modules in your application. No need to register controllers manually.
  // Just add @Controller() to your classes and they'll appear in Swagger.

  const config = new DocumentBuilder()
    .setTitle('TypeRush Record Service API')
    .setDescription(
      'Complete REST API documentation for TypeRush Record Service.\n\n' +
        'This API manages game records, achievements, match history, and player statistics.\n\n' +
        '**Authentication:** All endpoints require JWT Bearer token authentication.',
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter your JWT token (without "Bearer" prefix)',
        in: 'header',
      },
      'JWT-auth', // This identifier is used in @ApiBearerAuth('JWT-auth')
    )
    .build();

  // Create the Swagger document - automatically includes all controllers
  const document = SwaggerModule.createDocument(app, config);

  // Setup Swagger UI with enhanced options
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true, // Keep JWT token after page reload
      docExpansion: 'none', // Collapse all sections by default
      filter: true, // Enable search/filter
      showRequestDuration: true, // Show API request duration
      tryItOutEnabled: true, // Enable "Try it out" by default
      displayRequestDuration: true,
    },
    customSiteTitle: 'TypeRush API Documentation',
    customCss: `
      .swagger-ui .topbar { display: none }
      .swagger-ui .info { margin: 20px 0; }
      .swagger-ui table thead tr th { text-align: left; }
      .swagger-ui .responses-inner h4, .swagger-ui .responses-inner h5 { font-weight: 600; }
    `,
  });

  // ==================== End Swagger Configuration ====================

  await app.listen(3000);
}

void bootstrap();
