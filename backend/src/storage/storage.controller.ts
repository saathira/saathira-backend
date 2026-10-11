import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  UseGuards,
  Query,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { CurrentAuth, AuthContext } from '../auth/auth.decorators';
import { StorageService } from './storage.service';

@Controller('uploads')
@UseGuards(FirebaseAuthGuard)
export class StorageController {
  constructor(private readonly storageService: StorageService) {}

  /**
   * Upload user/companion profile avatar (Public bucket)
   * Updates user.photoUrl directly in PostgreSQL
   */
  @Post('avatar')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(
    @CurrentAuth() auth: AuthContext,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!auth.user?.id) {
      throw new BadRequestException('User profile not found. Please register first.');
    }
    if (!file) {
      throw new BadRequestException('Image file is required');
    }

    const result = await this.storageService.uploadAvatar(auth.user.id, file);
    return {
      success: true,
      message: 'Avatar uploaded and profile updated successfully',
      photoUrl: result.photoUrl,
      path: result.path,
    };
  }

  /**
   * Upload companion KYC verification document or selfie (Private bucket)
   */
  @Post('verification')
  @UseInterceptors(FileInterceptor('file'))
  async uploadVerification(
    @CurrentAuth() auth: AuthContext,
    @UploadedFile() file: Express.Multer.File,
    @Query('type') type?: 'document' | 'selfie',
  ) {
    if (!auth.user?.id) {
      throw new BadRequestException('User profile not found.');
    }
    if (!file) {
      throw new BadRequestException('Document file is required');
    }

    const docType = type === 'selfie' ? 'selfie' : 'document';
    const result = await this.storageService.uploadVerificationDocument(auth.user.id, file, docType);

    return {
      success: true,
      message: 'Verification document uploaded securely',
      path: result.path,
    };
  }
}
