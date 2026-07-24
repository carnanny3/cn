# Car Nanny — MVP Implementation

This is the working implementation of the MVP scoped in
[`../car-nanny-prd/CAR_NANNY_PRD.md`](../car-nanny-prd/CAR_NANNY_PRD.md)
(Section 30.2): Auth, My Garage, Pre-Purchase Inspection, Service Booking,
Vehicle Health Score, a scoped AI Assistant, Notifications, a Partner Portal
(garage + inspector), and a core Admin Dashboard.

```
car-nanny/
  backend/   NestJS + Prisma + PostgreSQL API — the foundation everything else calls
  mobile/    Flutter consumer app (Auth, Home, My Garage, Inspection, Services, AI, Profile)
  admin/     React + Vite ops dashboard (Overview, Users, Vehicles, Partners, Inspections, Bookings)
```

## Status: what's actually been verified

Docker Desktop and Flutter are both installed and working now (Docker needed
a WSL2 install + restart first). The full stack has been run for real,
against a live PostgreSQL database, end to end:

| Component | Verified here |
|---|---|
| **Backend** | Compiles clean, Prisma Client generates, **20/20 unit tests pass**. Beyond that: migrated a real schema into live Postgres, seeded it, and exercised the running server with real HTTP requests — register → OTP → real JWT issuance; fetched the seeded vehicle and its computed Health Score (which correctly flagged an expired seed document, catching a seed-data bug in the process); fetched a real inspection report; asked the AI Assistant "Is my insurance active?" and got a correct, data-grounded answer citing the real document's expiry date; logged in as the seeded admin and confirmed `/admin/*` endpoints return real data while a non-admin token correctly gets `403`; registered a new partner, approved it as admin, added a service to its catalog, and had the customer book it — the booking shows up correctly in `/admin/bookings` with the right VAT calculation. This testing also caught and fixed a real bug: `POST /partners/register` was blocked by the global auth guard when it should be public (a prospective partner has no session yet). |
| **Admin dashboard** | Builds clean, zero TypeScript errors. Logged in for real via the live OTP flow (admin account), and confirmed the Overview and Bookings pages render the exact real data created via the API testing above — not mocked, not stale. |
| **Mobile app** | `flutter analyze` clean, `flutter test` passes, `flutter build web` succeeds, and the app was run live in a browser with real interaction confirmed (Sign up/Log in toggle actually changes the widget tree). Not yet re-tested against the now-live backend (still points at demo-data fallbacks by default unless you pass `--dart-define=API_BASE_URL=http://localhost:3000/api/v1`). Android build needs the Android SDK (not installed here) — platform folder is scaffolded but not built to an APK. iOS needs macOS/Xcode, unavailable on Windows. |

### Known gap surfaced by this testing

`POST /partners/:id/services` is currently gated to admin roles as an interim
measure — there's no partner-authenticated session (Partner isn't linked to a
User/JWT identity in this MVP schema), so a partner can't yet manage their
own catalog directly. This is flagged in a code comment on that endpoint;
building real partner login is Phase 1 follow-up work, not a Phase 2 nice-to-have.

## Quick start

Flutter is already set up at `D:\flutter` (not added to PATH — either add
`D:\flutter\bin` to your PATH yourself, or call `D:\flutter\bin\flutter`
directly as below). Docker Desktop is installed and running.

```bash
# 1. Backend
cd backend
npm install
cp .env.example .env
docker compose up -d
npx prisma migrate dev --name init
npm run prisma:seed
npm run start:dev   # http://localhost:3000/api/v1, docs at /api/docs

# 2. Admin dashboard (separate terminal)
cd admin
npm install
npm run dev          # http://localhost:5173

# 3. Mobile app (separate terminal) — platform folders already generated for web+android
cd mobile
D:\flutter\bin\flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Each app's own README has more detail: [`backend/README.md`](backend/README.md), [`mobile/README.md`](mobile/README.md), [`admin/README.md`](admin/README.md).

## Deliberately simulated (documented inline, not hidden)

- **SMS/OTP delivery** — logged to console + returned in dev responses, no real gateway.
- **Payments** — simulated capture unless `STRIPE_SECRET_KEY` is set.
- **AI Assistant** — a genuine rule-based/RAG-style implementation grounded in real vehicle data, not a call to an external LLM (see the doc comment in `backend/src/ai/ai.service.ts` for how to upgrade it).
- **Vehicle registration lookup** — manual entry; no RTA/traffic-authority API integration.

These match the PRD's explicit `[FUTURE INTEGRATION]` flags — nothing here should be read as a claim that those integrations exist.
