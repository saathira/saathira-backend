import { Controller, Get, Module, Query } from '@nestjs/common';
import { AuthContext, CurrentAuth } from '../auth/auth.decorators';
import { DiscoveryQueryDto } from './discovery.dto';
import { DiscoveryService } from './discovery.service';

@Controller('discovery')
export class DiscoveryController {
  constructor(private readonly discovery: DiscoveryService) {}

  /** Requires a registered user so blocks can be applied. */
  @Get('companions')
  search(@CurrentAuth() auth: AuthContext, @Query() q: DiscoveryQueryDto) {
    return this.discovery.search(q, auth.user?.id);
  }
}

@Module({ controllers: [DiscoveryController], providers: [DiscoveryService] })
export class DiscoveryModule {}
