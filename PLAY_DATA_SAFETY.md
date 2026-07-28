# Play Console — Data Safety answers

Prepared from the actual schema and code, not from assumption. Every row cites
where the data is defined so you can re-check it when the app changes.

**You are responsible for the final submission.** Play treats this form as a
binding declaration — inaccuracies can get the app suspended after launch, not
just rejected at review. Read each row before you tick it.

Sources: `backend/prisma/schema.prisma`, `backend/src/notifications/providers/*`,
`backend/src/payments/payments.service.ts`, `backend/src/storage/storage.provider.ts`.

---

## ⚠️ Blocker: no account deletion path

Play requires that any app offering account creation must provide **both**:

1. an in-app route to request account deletion, and
2. a publicly reachable **web URL** for deletion requests, entered in Play Console.

Car Nanny currently has neither. The only `@Delete` route in the entire backend
is `cms.controller.ts:70` (admin content). There is no way for a customer to
delete their account or data.

This will fail review. It needs a `DELETE /users/me` endpoint that removes or
anonymises the user's rows, a Profile screen entry that calls it with a
confirmation, and a public web page describing the process. Say the word and I
will build it — it is a few hours, not a redesign.

---

## Section 1 — Data collection and security

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any required user data types? | **Yes** | See section 2 |
| Is all user data encrypted in transit? | **Yes** | API is HTTPS only (Railway); the mobile app talks to `https://cn-production-5a70.up.railway.app` |
| Do you provide a way for users to request their data be deleted? | **No — must become Yes** | See blocker above |
| Do you collect data from children? | **No** | Target audience is vehicle owners |

## Section 2 — Data types

For each: **Collected** = leaves the device. **Shared** = transferred to another
company. **Required** = the app doesn't function without it.

| Play data type | Collected | Shared | Required | Purpose | Where it lives |
|---|---|---|---|---|---|
| Name | Yes | No | Required | Account management | `User.fullName` |
| Email address | Yes | Yes¹ | Required | Account management, comms | `User.email` |
| Phone number | Yes | Yes¹ | Optional | Comms, booking coordination | `User.phoneNumber` |
| User IDs | Yes | No | Required | Account management | `User.id`, JWT `sub` |
| Purchase history | Yes | No | Optional | App functionality | `Payment`, `Booking`, `Invoice` |
| Precise location | Yes | **Yes²** | Optional | App functionality (roadside dispatch) | `RoadsideRequest.locationLat/Lng` (required on that model), `Inspection.locationLat/Lng` |
| Photos | Yes | No | Optional | App functionality | `Vehicle.primaryPhotoUrl`, `VehicleDocument.fileUrl`, `VehicleListing.photos` |
| Other in-app messages | Yes | No | Optional | App functionality, support | `AiMessage.content`, `SupportTicketMessage.content` |
| Device or other IDs | Yes | Yes³ | Optional | Push notifications | `DeviceToken.token` |
| App interactions | Yes | No | Optional | Analytics/functionality | `AdminAuditLog`, booking status history |

**Do NOT tick "Payment info."** Card details never reach your server — Stripe
collects them and you store only an amount, a method, and Stripe's opaque
`providerReference` (`payments.service.ts`). Ticking it would over-declare.

**Vehicle registration and insurance documents** are photos, so they fall under
**Photos**, not "Files and docs" — the API accepts only JPG/PNG/WebP for the
`vehicle-docs` scope (`storage.service.ts`). If you ever re-enable PDF uploads,
this answer changes to include Files and docs.

### Footnotes — what "Shared" means per row

1. **Email / phone** — transferred to Twilio (SMS, WhatsApp) and your SMTP
   provider (email) purely to deliver messages you initiate.
   See `notifications/providers/{sms,whatsapp,email}.provider.ts`.
2. **Precise location** — a roadside request's coordinates are visible to the
   assigned provider, which is a separate business. That makes it sharing in
   Play's sense even though it stays inside your system.
3. **Device IDs** — FCM tokens go to Google/Firebase to route push
   (`push.provider.ts`).

## Section 3 — Third-party processors

| Processor | Receives | Configured by |
|---|---|---|
| Stripe | Payment amounts, opaque references | `STRIPE_SECRET_KEY` |
| Firebase Cloud Messaging | Device tokens | `FIREBASE_SERVICE_ACCOUNT_JSON` |
| Twilio | Phone numbers, message bodies | `TWILIO_*` |
| SMTP provider | Email addresses, message bodies | `SMTP_*` |
| Cloudflare R2 | Vehicle photos and document images | `R2_*` |
| Railway | Hosting and Postgres — all of the above at rest | platform |

Each must appear in the privacy policy by name or category.

**Note: the AI assistant does not send anything to a third party.** It is
rule-based retrieval over your own database (`ai.service.ts` — "it does not call
an external LLM"). If that is ever swapped for a real model, chat content becomes
data shared with the model provider, and both this form and the privacy policy
must be updated before that ships.

---

## Before submitting

- [ ] Build the account-deletion endpoint, UI, and public URL (blocker above)
- [ ] Publish the privacy policy and name every processor in section 3
- [ ] Set the R2 variables in Railway — document upload currently returns 503,
      so a reviewer testing the flagship feature hits an error
- [ ] Re-check this file whenever the schema gains a field that holds user data
