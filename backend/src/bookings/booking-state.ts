import { BookingStatus } from '@prisma/client';

/** Single source of truth for allowed booking transitions (plan.md §9). */
export const BOOKING_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  PENDING: ['ACCEPTED', 'REJECTED', 'CANCELLED', 'EXPIRED'],
  ACCEPTED: ['PAYMENT_PENDING', 'CANCELLED', 'EXPIRED'],
  PAYMENT_PENDING: ['CONFIRMED', 'CANCELLED', 'EXPIRED'],
  CONFIRMED: ['IN_PROGRESS', 'CANCELLED', 'REFUND_PENDING'],
  IN_PROGRESS: ['COMPLETED', 'DISPUTED'],
  COMPLETED: ['DISPUTED'],
  REJECTED: [],
  CANCELLED: ['REFUND_PENDING'],
  EXPIRED: [],
  REFUND_PENDING: ['REFUNDED'],
  REFUNDED: [],
  DISPUTED: ['COMPLETED', 'REFUND_PENDING'],
};

/** Statuses that hold a companion's time slot (used for overlap prevention). */
export const ACTIVE_BOOKING_STATUSES: BookingStatus[] = [
  'PENDING',
  'ACCEPTED',
  'PAYMENT_PENDING',
  'CONFIRMED',
  'IN_PROGRESS',
];

export function canTransition(from: BookingStatus, to: BookingStatus): boolean {
  return BOOKING_TRANSITIONS[from].includes(to);
}
