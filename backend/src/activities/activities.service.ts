import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.module';

@Injectable()
export class ActivitiesService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.activity.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }
}
