import { Controller, Get } from '@nestjs/common';
import { Public } from '../auth/auth.decorators';

@Public()
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok', service: 'saathira-api', time: new Date().toISOString() };
  }
}
