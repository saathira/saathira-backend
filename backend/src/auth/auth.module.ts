import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { FirebaseService } from '../firebase/firebase.service';
import { AuthController } from './auth.controller';
import { FirebaseAuthGuard } from './firebase-auth.guard';

@Global()
@Module({
  controllers: [AuthController],
  providers: [FirebaseService, { provide: APP_GUARD, useClass: FirebaseAuthGuard }],
  exports: [FirebaseService],
})
export class AuthModule {}
