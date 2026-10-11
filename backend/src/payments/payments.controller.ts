import {
  Body,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthContext, CurrentAuth, Public, Roles } from '../auth/auth.decorators';
import { CreateOrderDto, VerifyPaymentDto } from './payments.dto';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Roles(UserRole.CUSTOMER)
  @Post('orders')
  createOrder(@CurrentAuth() auth: AuthContext, @Body() dto: CreateOrderDto) {
    return this.paymentsService.createOrder(auth.user!.id, dto);
  }

  @Roles(UserRole.CUSTOMER)
  @Post('verify')
  verifyPayment(@CurrentAuth() auth: AuthContext, @Body() dto: VerifyPaymentDto) {
    return this.paymentsService.verifyPayment(auth.user!.id, dto);
  }

  @Public()
  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  handleWebhook(
    @Body() body: any,
    @Headers('x-razorpay-signature') signature: string,
  ) {
    return this.paymentsService.handleWebhook(body, signature);
  }
}
