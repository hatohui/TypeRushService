import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PersonalRecordModule } from './modules/personal-record/personal-record.module';
import { LoggerMiddleware } from './common/middlewares/logger.middleware';
import { APP_FILTER } from '@nestjs/core';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { MatchHistoryModule } from './modules/match-history/match-history.module';
import { MatchParticipantModule } from './modules/match-participant/match-participant.module';
import { AchievementModule } from './modules/achievement/achievement.module';
import { UserAchievementModule } from './modules/user-achievement/user-achievement.module';
import { ModeModule } from './modules/mode/mode.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  providers: [
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
  ],
  imports: [
    ConfigModule.forRoot({ envFilePath: '.env', isGlobal: true }),
    PersonalRecordModule,
    PrismaModule,
    ModeModule,
    MatchHistoryModule,
    MatchParticipantModule,
    AchievementModule,
    UserAchievementModule,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*');
  }
}
