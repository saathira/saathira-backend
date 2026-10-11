Yes. Based on the current decisions, the original proposal, and the cost discussion, this is the **final Saathira MVP technical and infrastructure plan** I would approve.

The original proposal was for **SaathLy**, but the product name is now **Saathira**. The core scope remains the companionship/activity-based booking marketplace described in the proposal. SaathLy_Project_Proposal_and_Qu…

# 🚀 Saathira — Final MVP Plan

## 1. Product

**Saathira** is an Android-first marketplace where users can find and book verified companions for permitted activities such as:

- Shopping
- Doctor visits
- Movies/events
- Cafe/dinner
- City exploration
- Activities/hobbies
- Conversation/social companionship
- Professional/event companionship
- Non-sexual romantic-style companionship, subject to strict safety rules

The fundamental flow remains:

**Search → Choose → Request → Accept → Pay → Meet → Complete → Review**. SaathLy_Project_Proposal_and_Qu…

---

# 2. User Roles

### Customer

Can:

- Register/login
- Create profile
- Search companions
- Filter by activity, location, availability and price
- View companion profile
- Request booking
- Pay
- Chat
- Cancel
- Review
- Report/block

### Companion

Can:

- Register
- Create profile
- Submit verification
- Select activities
- Set pricing
- Set availability
- Accept/reject bookings
- Chat
- View calendar
- Track earnings
- Manage payout information
- Receive reviews
- Report/block

These align with the original customer and companion scope. SaathLy_Project_Proposal_and_Qu…

### Admin

Can manage:

- Users
- Companions
- Verification
- Activities
- Bookings
- Payments
- Commission
- Payouts
- Complaints
- Disputes
- Reviews
- Reports
- Notifications
- Coupons
- Analytics

SaathLy_Project_Proposal_and_Qu…

---

# 3. Final Technology Stack

## Mobile

**Flutter + Dart**

One Flutter codebase supporting:

```text
Customer
+
Companion
```

We do **not** create two completely separate Flutter projects.

---

## Backend

### **NestJS + TypeScript**

NestJS will contain the important business logic:

- Authentication/authorization
- Companion verification
- Discovery
- Availability
- Booking engine
- Booking state transitions
- Payment integration
- Razorpay webhooks
- Commission
- Payout logic
- Cancellation/refund rules
- Reports/disputes
- Admin APIs
- Notifications
- Audit logs

---

# 4. Backend Hosting — Final Decision

Instead of paying for a VPS initially:

### **Firebase Cloud Functions**

Host the NestJS backend through Firebase Functions.

```text
Flutter
   ↓
Firebase HTTPS / Cloud Functions
   ↓
NestJS API
   ↓
Supabase PostgreSQL
```

This keeps the initial infrastructure cost very low.

**Important:** Firebase Functions requires the **Blaze plan**, so we need billing enabled. It is usage-based rather than a fixed server rental.

We should configure billing alerts before production.

---

# 5. Database

### **Supabase PostgreSQL**

PostgreSQL remains the **main Saathira database**.

Store:

```text
users
companions
companion_verifications
activities
companion_activities
availability
bookings
booking_status_history
payments
commissions
payouts
reviews
reports
complaints
disputes
notifications
admin_users
audit_logs
```

### Why PostgreSQL?

Because Saathira has relationships and transactions such as:

```text
Companion
   ↓
Activity
   ↓
Availability
   ↓
Booking
   ↓
Payment
   ↓
Commission
   ↓
Payout
```

We need reliable transactions and double-booking prevention.

---

# 6. Firebase Services

Firebase will **not replace PostgreSQL**.

It will provide supporting services.

### Firebase Authentication

- Phone OTP
- Email/password
- Google login if required

### Firestore

**Chat only initially.**

```text
booking
   ↓
conversation
   ↓
messages
```

This prevents us from turning the entire marketplace database into Firestore.

### Firebase Cloud Messaging

Push notifications:

- Booking request
- Booking accepted/rejected
- Payment
- Reminder
- Cancellation
- Chat
- Verification
- Review reminder
- Admin announcement

### Firebase Crashlytics

Crash/error monitoring.

### Firebase Analytics

Track:

```text
App Open
Signup
Login
Search
View Companion
Booking Request
Booking Accepted
Payment Started
Payment Success
Booking Completed
Review Submitted
```

### Firebase Storage

For:

- Profile photos
- Activity images
- Verification documents

**Verification documents must remain private.**

---

# 7. Admin Panel

### Technology

**React + TypeScript + Vite + Tailwind CSS**

Hosted on:

### **Firebase Hosting**

Initially:

**₹0 hosting cost**, provided usage stays within Firebase's current free Hosting allowance.

Architecture:

```text
admin.saathira.com
        ↓
Firebase Hosting
        ↓
React Admin Panel
        ↓
NestJS API
        ↓
Supabase PostgreSQL
```

The original proposal calls for a responsive web-based admin dashboard. SaathLy_Project_Proposal_and_Qu…

---

# 8. Payment

### Razorpay

Payment flow:

```text
Customer
   ↓
Booking Request
   ↓
Companion Accepts
   ↓
NestJS creates Razorpay Order
   ↓
Flutter Razorpay Checkout
   ↓
Payment
   ↓
Razorpay Webhook
   ↓
NestJS verifies payment
   ↓
Booking = CONFIRMED
```

### Critical rule

**Never trust only the Flutter payment callback.**

The backend must verify the payment/server webhook.

---

# 9. Booking State Machine

This is one of the most important parts of Saathira.

```text
PENDING
   ↓
ACCEPTED
   ↓
PAYMENT_PENDING
   ↓
CONFIRMED
   ↓
IN_PROGRESS
   ↓
COMPLETED
```

Alternative states:

```text
REJECTED
CANCELLED
EXPIRED
REFUND_PENDING
REFUNDED
DISPUTED
```

The backend must prevent:

- Double booking
- Overlapping bookings
- Booking unavailable companions
- Unauthorized status changes
- Fake payment confirmation

---

# 10. Chat

Use:

### Firestore

But chat should be connected to bookings.

For MVP:

```text
Booking requested
        ↓
Chat available
        ↓
Booking completed
        ↓
Chat becomes read-only / retention policy
```

I would **not launch unrestricted social messaging** initially.

That reduces spam, harassment and moderation problems.

---

# 11. Location

### Google Maps Platform

Use for:

- Location selection
- Search nearby companions
- Maps
- Places
- Distance calculation where required

### Do NOT launch continuous live tracking in MVP

The proposal specifically lists live location as a requirement to be decided. SaathLy_Project_Proposal_and_Qu…

For V1:

**Location-based discovery is enough.**

Live tracking can become P1 after validating the use case.

---

# 12. Safety — P0

This is not an optional feature for Saathira.

The proposal already identifies verification, report/block, emergency support, trusted contacts, privacy and prohibited activities as core safety requirements. SaathLy_Project_Proposal_and_Qu…

### MVP safety:

- Companion verification
- Profile verification badge
- Report
- Block
- Complaint system
- Dispute system
- Community guidelines
- Prohibited-use policy
- Privacy controls
- Cancellation/refund policy
- Safety support
- Emergency/SOS where technically and legally appropriate
- Trusted contact/check-in if feasible

### Strictly prohibited

- Sexual services
- Prostitution
- Exploitation
- Illegal activities

This is explicitly stated in the proposal. SaathLy_Project_Proposal_and_Qu…

---

# 13. Security

Minimum requirements:

### Backend

- JWT/token validation
- RBAC
- Request validation
- Rate limiting
- Secure API endpoints
- HTTPS
- Secure secrets
- Payment webhook verification

### Database

- Proper constraints
- Transactions
- Foreign keys
- Indexes
- Backup strategy

### Firebase

- Firestore security rules
- Storage security rules
- Private verification files

### Admin

Roles such as:

```text
SUPER_ADMIN
ADMIN
SUPPORT
MODERATOR
FINANCE
```

And:

### Audit logs

Record important actions such as:

```text
Admin approved companion
Admin suspended user
Refund processed
Payout approved
Booking modified
Complaint resolved
```

---

# 14. Repository Structure

```text
saathira/
│
├── apps/
│   ├── mobile/
│   │
│   └── admin/
│
├── backend/
│
├── docs/
│
├── README.md
├── .gitignore
└── .env.example
```

### Flutter

```text
apps/mobile/lib/

core/
config/
models/
services/
repositories/
providers/
routing/
theme/
widgets/

features/
├── auth/
├── onboarding/
├── home/
├── discovery/
├── companion/
├── booking/
├── chat/
├── payments/
├── notifications/
├── profile/
├── reviews/
├── safety/
└── support/
```

---

# 15. Development Order

Do **not** ask an AI coding agent to build the entire application in one prompt.

Build in controlled phases.

### Phase 1 — Foundation

1. Requirements
2. Architecture
3. Database ER diagram
4. PostgreSQL schema
5. API specification
6. Repository setup
7. Environment configuration

### Phase 2 — Authentication

8. Firebase Auth
9. User roles
10. JWT/API authorization
11. Customer onboarding
12. Companion onboarding

### Phase 3 — Companion

13. Companion profile
14. Verification
15. Activities
16. Pricing
17. Availability

### Phase 4 — Discovery

18. Search
19. Filters
20. Location
21. Companion profile
22. Availability display

### Phase 5 — Booking

23. Booking request
24. Accept/reject
25. Booking state machine
26. Double-booking prevention
27. Cancellation

### Phase 6 — Payments

28. Razorpay
29. Order creation
30. Payment verification
31. Webhooks
32. Commission
33. Refund logic

### Phase 7 — Communication

34. Firestore chat
35. FCM notifications

### Phase 8 — Trust

36. Report
37. Block
38. Complaints
39. Disputes
40. Reviews
41. Safety

### Phase 9 — Admin

42. Dashboard
43. Users
44. Companions
45. Verification
46. Bookings
47. Payments
48. Payouts
49. Reports
50. Reviews
51. Notifications
52. Coupons
53. Audit logs

### Phase 10 — Quality

54. Unit tests
55. API tests
56. Flutter testing
57. Payment testing
58. Security testing
59. Crashlytics
60. Analytics verification

### Phase 11 — Release

61. Production environment
62. Production database
63. Android AAB
64. Play Console
65. Privacy policy
66. Terms
67. Community guidelines
68. Safety policy
69. Production launch

---

# 16. MVP vs Later

## 🔴 P0 — Must Have

- Customer app
- Companion functionality
- Authentication
- Verification
- Discovery
- Activities
- Availability
- Booking
- Payment
- Chat
- Notifications
- Reviews
- Report/block
- Admin panel
- Complaints
- Basic analytics
- Android release

This matches the core MVP scope in the proposal. SaathLy_Project_Proposal_and_Qu…

## 🟡 P1 — After launch

- Coupons
- Better payout management
- Advanced moderation
- Enhanced location
- Better analytics
- Trusted contact improvements
- More sophisticated safety features

## 🟢 P2 — Don't build now

- AI matching
- Video calling
- Complex wallet
- Social feed
- Stories/reels
- iOS
- Customer web app
- Multi-country payments/tax
- Advanced recommendation engine

The proposal itself identifies AI matching, video calling, complex wallets, multi-country tax handling, advanced analytics and additional platforms as scope changes. SaathLy_Project_Proposal_and_Qu…

---

# 17. Estimated Infrastructure Cost

For the initial MVP:

| Component | Initial approach |
|---|---|
| Flutter | Free |
| NestJS | Firebase Functions |
| PostgreSQL | Supabase Free |
| Firebase Auth | Free/no-cost allowances |
| Firestore | Usage-based |
| FCM | Free |
| Crashlytics | Free |
| Analytics | Free |
| Admin Hosting | Firebase Hosting |
| Storage | Firebase Storage |
| Payments | Razorpay |
| Maps | Google Maps Platform |
| Domain | Paid |
| Play Console | One-time Google fee |

### Planning budget

For **up to ~1,000 users**, infrastructure can potentially remain very low.

For **~5,000 users**, I would provisionally budget around **₹1,500/month for Firebase-related infrastructure**, then replace this estimate with actual billing data after launch.

**Do not treat ₹1,500 as a guaranteed Firebase bill.** Actual cost depends on reads/writes, Functions execution, storage, bandwidth, OTP usage and other usage patterns.

---

# 18. Final Architecture

This is the architecture I would lock for the MVP:

```text
                         SAATHIRA
                            │
              ┌─────────────┴─────────────┐
              │                           │
        Flutter Mobile              React Admin
        Customer + Companion              │
              │                            │
              └───────────┬────────────────┘
                          │
                          ▼
               Firebase / HTTPS
                          │
                          ▼
               NestJS + TypeScript
               Firebase Functions
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
     PostgreSQL       Firestore          Firebase
     Supabase            │              Services
          │              │          ┌─────┼─────┐
          │            Chat          │     │     │
          │                         FCM  Auth Analytics
          │                              │
          └──────────────┬───────────────┘
                         │
                  ┌──────┴──────┐
                  ▼             ▼
               Razorpay    Google Maps
```

## Final PM decision

**I would approve this architecture for Saathira MVP.**

The key principle is:

> **Firebase handles infrastructure services and realtime functionality; NestJS handles business logic; PostgreSQL handles marketplace data.**

That gives us low initial infrastructure cost **without sacrificing the transactional reliability we need for bookings and payments**.

And I would keep the original proposal's **8–9 week target only as a planning target**, not a guaranteed delivery date; the proposal itself says the final timeline depends on scope approval and required client inputs. SaathLy_Project_Proposal_and_Qu…