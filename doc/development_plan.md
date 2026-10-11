# Saathira — Frontend & Backend Development Plan

Derived from [plan.md](./plan.md). Tracks *how* we build the MVP, phase by phase.

---

## 0. Repository Layout (adapted to current repo)

The Flutter project already lives at the repo root, so we keep it there instead of moving it to `apps/mobile`.

```text
saathira/
├── lib/                 # Flutter app (Customer + Companion)
├── android/ ios/ test/  # Flutter platform + tests
├── backend/             # NestJS + TypeScript + Prisma (PostgreSQL / Supabase)
├── admin/               # React + TS + Vite + Tailwind admin panel
├── firebase/            # firestore.rules, storage.rules, firebase.json
└── doc/                 # plan.md, development_plan.md, api.md, schema notes
```

---

## 1. Backend Plan (NestJS)

### 1.1 Stack
| Concern | Choice |
|---|---|
| Framework | NestJS 10 + TypeScript |
| ORM | Prisma → Supabase PostgreSQL |
| Auth | Firebase ID token verified via `firebase-admin`, mapped to DB user + role |
| Validation | `class-validator` + global `ValidationPipe` |
| Rate limiting | `@nestjs/throttler` |
| Payments | Razorpay SDK + HMAC webhook verification |
| Hosting | Firebase Functions (`onRequest` wrapping Nest Express app) |
| Local dev | `npm run start:dev` on port 3000 |

### 1.2 Modules
| Module | Responsibility | Phase |
|---|---|---|
| `prisma` | DB client | 1 |
| `health` | `/health` | 1 |
| `auth` | Firebase token guard, `RolesGuard`, `/auth/me`, `/auth/register` | 2 |
| `users` | Customer profile | 2 |
| `companions` | Profile, pricing, verification submit | 3 |
| `activities` | Activity catalogue (admin-managed) | 3 |
| `availability` | Weekly slots + blackouts | 3 |
| `discovery` | Search + filters + geo distance | 4 |
| `bookings` | Request, accept/reject, state machine, overlap prevention | 5 |
| `payments` | Razorpay orders, verify, webhook, commission, refunds | 6 |
| `notifications` | FCM push + DB notification log | 7 |
| `chat` | Issues Firestore conversation per booking, access control | 7 |
| `trust` | Reviews, reports, blocks, complaints, disputes | 8 |
| `admin` | Admin APIs (RBAC: SUPER_ADMIN/ADMIN/SUPPORT/MODERATOR/FINANCE) | 9 |
| `audit` | Audit log interceptor/service | 9 |

### 1.3 Booking State Machine (server-enforced)
```text
PENDING → ACCEPTED → PAYMENT_PENDING → CONFIRMED → IN_PROGRESS → COMPLETED
PENDING → REJECTED | EXPIRED | CANCELLED
ACCEPTED/PAYMENT_PENDING → CANCELLED | EXPIRED
CONFIRMED → CANCELLED → REFUND_PENDING → REFUNDED
IN_PROGRESS/COMPLETED → DISPUTED
```
- Transitions defined in one table (`booking-state.ts`); every change writes `booking_status_history`.
- Double booking prevented by a serializable transaction overlap check + PostgreSQL exclusion constraint on `(companion_id, tstzrange(start,end))` for active statuses.
- `CONFIRMED` only set by verified Razorpay signature/webhook.

### 1.4 API (v1, prefix `/api/v1`)
```text
GET    /health
POST   /auth/register            GET /auth/me
PATCH  /users/me
POST   /companions/me            PATCH /companions/me   POST /companions/me/verification
PUT    /companions/me/activities PUT /companions/me/availability
GET    /activities
GET    /discovery/companions?activity=&lat=&lng=&radiusKm=&minPrice=&maxPrice=&date=
GET    /companions/:id
POST   /bookings                 GET /bookings           GET /bookings/:id
POST   /bookings/:id/accept|reject|cancel|start|complete
POST   /payments/orders          POST /payments/verify   POST /payments/webhook
POST   /reviews  POST /reports  POST /blocks  POST /complaints  POST /disputes
/admin/*  (users, companions, verifications, bookings, payments, payouts, reports, audit-logs)
```

---

## 2. Mobile Frontend Plan (Flutter)

### 2.1 Stack
| Concern | Choice |
|---|---|
| State | Riverpod |
| Routing | go_router (role-based shells) |
| HTTP | Dio + Firebase token interceptor |
| Firebase | firebase_auth, cloud_firestore, firebase_messaging, crashlytics, analytics, storage |
| Payments | razorpay_flutter |
| Maps | google_maps_flutter + geolocator |

### 2.2 Structure
```text
lib/
├── main.dart  app.dart
├── core/ (config, network, errors, utils)
├── theme/      routing/      widgets/
├── models/     repositories/ providers/ services/
└── features/ auth, onboarding, home, discovery, companion, booking,
              chat, payments, notifications, profile, reviews, safety, support
```

### 2.3 Screens by phase
| Phase | Screens |
|---|---|
| 1 | Splash, theme/design system, mock data layer |
| 2 | Welcome, Phone OTP, Role select, Customer onboarding, Companion onboarding |
| 3 | Companion profile edit, Verification upload, Activities & pricing, Availability |
| 4 | Home, Search/filters, Companion detail |
| 5 | Booking request, My bookings, Booking detail, Companion requests inbox |
| 6 | Razorpay checkout, Payment result, Earnings |
| 7 | Chat list, Chat room, Notifications |
| 8 | Review, Report/Block, Safety centre/SOS, Support |

---

## 3. Admin Frontend Plan (React)

React + TS + Vite + Tailwind, Firebase Auth login, hosted on Firebase Hosting.
Pages: Login, Dashboard, Users, Companions, Verification queue, Activities, Bookings, Payments, Payouts, Reports/Complaints/Disputes, Reviews, Notifications, Coupons (P1), Audit logs.

---

## 4. Milestones & Status

| # | Phase | Backend | Mobile | Admin | Status |
|---|---|---|---|---|---|
| 1 | Foundation | Scaffold, Prisma schema, health | Structure, theme, router | — | ✅ Done |
| 2 | Auth | Firebase guard, roles, register | OTP, onboarding | Login | ✅ Done |
| 3 | Companion | Profile, verification, activities, availability | Companion screens | — | ✅ Done |
| 4 | Discovery | Search API, filters, block checks | Home search, filters, companion detail | — | ✅ Done |
| 5 | Booking | State machine, overlap | Booking flows | — | ✅ Done |
| 6 | Payments | Razorpay + webhook | Checkout | — | ✅ Done |
| 7 | Communication | FCM, chat access | Chat, notifications | — | ✅ Done |
| 8 | Trust | Reviews/reports/disputes | Safety screens | — | ✅ Done |
| 9 | Admin | Admin APIs, audit | — | All pages & portal | ✅ Done |
| 10 | Quality | Unit/e2e tests | Widget tests, Analyzer (0 issues) | Production bundle | ✅ Done |
| 11 | Release | Prod env & security | Android/iOS setup | Firebase Hosting build | 🚀 Ready |

## 5. Environment Variables (`backend/.env.example`)
`DATABASE_URL`, `DIRECT_URL`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `PLATFORM_COMMISSION_PERCENT`, `PORT`.
