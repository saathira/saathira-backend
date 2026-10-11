import { Controller, Get } from '@nestjs/common';
import { Public } from '../auth/auth.decorators';
import { ActivitiesService } from './activities.service';

@Controller('activities')
export class ActivitiesController {
  constructor(private readonly activitiesService: ActivitiesService) {}

  @Public()
  @Get()
  findAll() {
    return this.activitiesService.findAll();
  }
}
