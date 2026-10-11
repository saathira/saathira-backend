import { Injectable, Logger, BadRequestException, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { PrismaService } from '../prisma/prisma.module';

@Injectable()
export class StorageService implements OnModuleInit {
  private readonly logger = new Logger(StorageService.name);
  private supabase: SupabaseClient | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  onModuleInit() {
    const url = this.config.get<string>('SUPABASE_URL') || process.env.SUPABASE_URL;
    const secretKey = this.config.get<string>('SUPABASE_SECRET_KEY') || process.env.SUPABASE_SECRET_KEY;

    if (!url || !secretKey) {
      this.logger.warn('SUPABASE_URL or SUPABASE_SECRET_KEY is missing. Storage uploads will fail.');
      return;
    }

    this.supabase = createClient(url, secretKey, {
      auth: { persistSession: false },
    });
    this.logger.log('Supabase Storage client initialized successfully.');
  }

  private getClient(): SupabaseClient {
    if (!this.supabase) {
      throw new BadRequestException('Supabase storage client is not configured.');
    }
    return this.supabase;
  }

  /**
   * Upload user or companion avatar to public 'avatars' bucket
   * Automatically updates User.photoUrl in PostgreSQL database
   */
  async uploadAvatar(userId: string, file: Express.Multer.File): Promise<{ photoUrl: string; path: string }> {
    if (!file) throw new BadRequestException('No image file provided');

    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
    if (!allowedMimes.includes(file.mimetype)) {
      throw new BadRequestException('Avatar must be an image (JPEG, PNG, or WebP)');
    }

    if (file.size > 5 * 1024 * 1024) {
      throw new BadRequestException('Avatar file size must be less than 5MB');
    }

    const client = this.getClient();
    const cleanExt = (file.originalname.split('.').pop() || 'jpg').toLowerCase();
    const filePath = `${userId}/avatar-${Date.now()}.${cleanExt}`;

    const { error } = await client.storage.from('avatars').upload(filePath, file.buffer, {
      contentType: file.mimetype,
      upsert: true,
    });

    if (error) {
      this.logger.error(`Supabase avatar upload failed: ${error.message}`);
      throw new BadRequestException(`Failed to upload avatar: ${error.message}`);
    }

    const { data: publicData } = client.storage.from('avatars').getPublicUrl(filePath);
    const photoUrl = publicData.publicUrl;

    // Persist to user record in DB
    await this.prisma.user.update({
      where: { id: userId },
      data: { photoUrl },
    });

    this.logger.log(`Avatar uploaded and user updated: ${userId} -> ${photoUrl}`);
    return { photoUrl, path: filePath };
  }

  /**
   * Upload sensitive KYC identity documents or selfies to private 'verifications' bucket
   */
  async uploadVerificationDocument(
    userId: string,
    file: Express.Multer.File,
    docType: 'document' | 'selfie' = 'document',
  ): Promise<{ path: string }> {
    if (!file) throw new BadRequestException('No document file provided');

    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf'];
    if (!allowedMimes.includes(file.mimetype)) {
      throw new BadRequestException('Verification document must be an image or PDF');
    }

    if (file.size > 10 * 1024 * 1024) {
      throw new BadRequestException('Verification file size must be less than 10MB');
    }

    const client = this.getClient();
    const cleanExt = (file.originalname.split('.').pop() || 'jpg').toLowerCase();
    const filePath = `${userId}/${docType}-${Date.now()}.${cleanExt}`;

    const { error } = await client.storage.from('verifications').upload(filePath, file.buffer, {
      contentType: file.mimetype,
      upsert: true,
    });

    if (error) {
      this.logger.error(`Supabase verification upload failed: ${error.message}`);
      throw new BadRequestException(`Failed to upload verification document: ${error.message}`);
    }

    this.logger.log(`Verification document uploaded for companion ${userId}: ${filePath}`);
    return { path: filePath };
  }

  /**
   * Generate temporary signed URL for private verification review (e.g. for Admin Panel)
   */
  async getSignedVerificationUrl(path: string, expiresInSeconds: number = 3600): Promise<string | null> {
    if (!path) return null;
    // If it's already a full http/https url (e.g. legacy/mock path)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    try {
      const client = this.getClient();
      // Remove any leading bucket prefix if present
      const cleanPath = path.replace(/^verifications\//, '');
      const { data, error } = await client.storage
        .from('verifications')
        .createSignedUrl(cleanPath, expiresInSeconds);

      if (error || !data) {
        this.logger.warn(`Could not create signed URL for path: ${path} - ${error?.message}`);
        return null;
      }
      return data.signedUrl;
    } catch (err: any) {
      this.logger.warn(`Error generating signed URL for ${path}: ${err.message}`);
      return null;
    }
  }
}
