import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.module';
import { DiscoveryQueryDto } from './discovery.dto';

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number) {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

@Injectable()
export class DiscoveryService {
  constructor(private readonly prisma: PrismaService) {}

  async search(q: DiscoveryQueryDto, viewerId?: string) {
    const page = q.page ?? 1;
    const pageSize = q.pageSize ?? 20;

    const where: Prisma.CompanionWhereInput = {
      verificationStatus: 'APPROVED',
      isAvailable: true,
      hourlyRate: {
        ...(q.minPrice != null ? { gte: q.minPrice * 100 } : {}),
        ...(q.maxPrice != null ? { lte: q.maxPrice * 100 } : {}),
      },
      user: {
        status: 'ACTIVE',
        ...(q.city ? { city: { equals: q.city, mode: 'insensitive' } } : {}),
        // Hide companions who blocked the viewer or were blocked by them
        ...(viewerId
          ? {
              blocks: { none: { blockedId: viewerId } },
              blockedBy: { none: { blockerId: viewerId } },
            }
          : {}),
      },
      ...(q.activity
        ? {
            activities: {
              some: { activity: { OR: [{ slug: q.activity }, { id: q.activity }], isActive: true } },
            },
          }
        : {}),
      ...(q.day != null ? { availability: { some: { dayOfWeek: q.day } } } : {}),
      ...(q.minRating != null ? { ratingAvg: { gte: q.minRating } } : {}),
      ...(q.q
        ? {
            OR: [
              { bio: { contains: q.q, mode: 'insensitive' } },
              { user: { fullName: { contains: q.q, mode: 'insensitive' } } },
            ],
          }
        : {}),
    };

    const rows = await this.prisma.companion.findMany({
      where,
      include: {
        user: { select: { id: true, fullName: true, photoUrl: true, city: true, gender: true } },
        activities: { include: { activity: true } },
      },
      take: 500, // MVP cap; geo filtering happens in memory below
    });

    const hasGeo = q.lat != null && q.lng != null;
    let results = rows.map((c) => ({
      ...c,
      distanceKm:
        hasGeo && c.latitude != null && c.longitude != null
          ? Math.round(haversineKm(q.lat!, q.lng!, c.latitude, c.longitude) * 10) / 10
          : null,
    }));

    if (hasGeo && q.radiusKm) {
      results = results.filter((c) => c.distanceKm != null && c.distanceKm <= q.radiusKm!);
    }

    switch (q.sort) {
      case 'price_asc':
        results.sort((a, b) => a.hourlyRate - b.hourlyRate);
        break;
      case 'price_desc':
        results.sort((a, b) => b.hourlyRate - a.hourlyRate);
        break;
      case 'distance':
        results.sort((a, b) => (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity));
        break;
      default:
        results.sort((a, b) => b.ratingAvg - a.ratingAvg || b.ratingCount - a.ratingCount);
    }

    const total = results.length;
    const items = results.slice((page - 1) * pageSize, page * pageSize);
    return { items, total, page, pageSize };
  }
}
