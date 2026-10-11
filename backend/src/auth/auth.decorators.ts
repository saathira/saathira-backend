import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import { AdminRole, User, UserRole } from '@prisma/client';

export const IS_PUBLIC = 'isPublic';
export const ROLES = 'roles';
export const ALLOW_UNREGISTERED = 'allowUnregistered';

/** Skip authentication (e.g. /health, Razorpay webhook). */
export const Public = () => SetMetadata(IS_PUBLIC, true);
/** Allow a valid Firebase user that has no DB record yet (used by /auth/register). */
export const AllowUnregistered = () => SetMetadata(ALLOW_UNREGISTERED, true);
/** Restrict to app roles and/or admin roles. */
export const Roles = (...roles: (UserRole | AdminRole)[]) => SetMetadata(ROLES, roles);

export interface AuthContext {
  uid: string;
  phone?: string;
  email?: string;
  user?: User;
  adminRole?: AdminRole;
}

export const CurrentAuth = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AuthContext => ctx.switchToHttp().getRequest().auth,
);
