# Car Nanny Backend (NestJS + Prisma + PostgreSQL)

MVP backend implementing: Auth (phone OTP), Users, Vehicles ("My Garage"),
Partners, Inspections (booking + report generation), Bookings (service
lifecycle), Payments (simulated), Notifications, and a rule-based AI
Assistant. See `../car-nanny-prd/CAR_NANNY_PRD.md` for the full product spec
this implements.

## Prerequisites

- Node.js 20+ (tested with Node 24)
- Docker (for local PostgreSQL) — or point `DATABASE_URL` at any Postgres 14+ instance

## Setup

```bash
npm install
cp .env.example .env
docker compose up -d          # starts PostgreSQL on localhost:5432
npx prisma migrate dev --name init
npm run prisma:seed
npm run start:dev
```

API runs at `http://localhost:3000/api/v1`. Swagger docs at `http://localhost:3000/api/docs`.

## Dev-mode auth flow

There is no real SMS gateway wired up yet. `POST /auth/register` and
`POST /auth/login` log the OTP to the server console (and return it directly
in the response body when `NODE_ENV` is not `production`) so you can test the
full flow without a real phone. Seeded sample accounts:

- Customer: `+971500000001`
- Admin: `+971500000099`

## Testing

```bash
npm test
```

Unit tests mock the Prisma client — they do **not** require a running
database, so they should pass even without Docker/Postgres installed.

## What's simulated / needs a real integration before production

- **Payments** — no real Stripe call is made unless `STRIPE_SECRET_KEY` is set. Card/wallet payments auto-capture in dev mode; `pay_at_service` stays pending.
- **Notifications** — logged to console instead of sent via FCM/SMS/WhatsApp.
- **AI Assistant** — deterministic, rule-based responses grounded in real vehicle/inspection/document data (a legitimate RAG-style implementation), not a call to an external LLM. See the doc comment in `src/ai/ai.service.ts` for how to swap in a real model later without changing the contract.
- **Vehicle registration lookup** — no RTA/traffic-authority API integration; vehicles are entered manually.

## Project layout

```
src/
  auth/          registration, OTP verification, login, JWT issuance/refresh
  users/         profile
  vehicles/      "My Garage" — CRUD, documents, health score
  partners/      partner registration, verification, search/ranking
  inspections/   booking, checkpoint submission, report generation
  bookings/      service booking lifecycle
  payments/      payment intent simulation
  notifications/ in-app notification storage + preferences
  ai/            conversational assistant grounded in vehicle data
  common/        guards, decorators, error handling shared across modules
prisma/
  schema.prisma  full data model (PostgreSQL)
  seed.ts        sample data for local development
```
