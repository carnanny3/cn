# Car Nanny Admin Dashboard

React + Vite + TypeScript web dashboard for internal operations: Overview,
Users, Vehicles, Partners (with verify/reject), Inspections (QA queue with
report approval), and Bookings.

## Setup

```bash
npm install
npm run dev
```

Runs at `http://localhost:5173`. Expects the backend at
`http://localhost:3000/api/v1` by default — override with a `.env` file:

```
VITE_API_BASE_URL=http://localhost:3000/api/v1
```

## Login

Uses the same phone-OTP flow as the consumer app, against the same backend —
any user with an `admin_*` role can sign in (see the seeded admin account,
`+971500000099`, in `../backend/prisma/seed.ts`). Signing in as a `customer`
role account will authenticate but every `/admin/*` and partner-verification
call will correctly return 403 Forbidden (role-gated server-side, not just
hidden in the UI).

## Verified

- `npm run build` — production build succeeds (Vite + esbuild).
- `npm run typecheck` — zero TypeScript errors.
- Manually verified in-browser: login screen renders in both light and dark
  mode, and network/API errors surface as a readable message instead of a
  crash (tested by running the dashboard against a backend without a live
  database connection).

## What's not built yet

Everything here talks to the real `/admin/*` and `/partners/:id/verify` /
`/inspections/:id/approve-report` endpoints — there is no demo-data fallback
(unlike the mobile app), since an ops dashboard showing fake data would be
actively misleading. Bring the backend up (with Postgres) to see real data.
Not yet built: RBAC-aware UI (all admin roles see the same nav today, even
though the backend enforces role checks per endpoint), CMS/promotions/refunds
screens, and the full audit log viewer described in the product spec.
