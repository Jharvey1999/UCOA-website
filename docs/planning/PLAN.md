# UCOA Website Implementation Plan

**Status:** implementation in progress

**Last reviewed:** August 30, 2026

**Product owner:** UCOA executive responsible for construction and operational approval

This document is the implementation source of truth for replacing the UCOA club's core Meetup workflows. It turns the public Meetup research and the current repository notes into a staged plan for a private, responsive member portal.

## 1. Goal

Build a single UCOA website that supports public discovery, controlled membership, outdoor event operations, and executive administration without exposing private member or event data.

The replacement must support the patterns visible in the current UCOA community:

- Recurring indoor climbing sessions.
- One-off hikes and scrambles with difficulty labels.
- Multi-day camping and mountain trips.
- Social events and club-wide gatherings.
- Event hosts, attendee limits, waitlists, cancellations, and attendance.
- Member-only event descriptions, exact locations, and attendee information.
- Annual membership aligned to the school year.
- External e-transfer, waiver, Discord, social, and form workflows during the transition.

## 2. Product decisions

| Area | Decision | Reason |
| --- | --- | --- |
| Frontend and server boundary | Next.js App Router | The requested stack and the official Supabase starter provide the required server-rendered and authenticated application boundary. |
| Database and authentication | Supabase PostgreSQL, Auth, Row Level Security (RLS), and Storage | Keeps identity, authorization, relational data, and private media in one controlled platform. |
| Hosting | Vercel for Next.js and Supabase-hosted project for data/auth | Matches the requested low-cost deployment model. |
| Authentication | Supabase email/password with email confirmation and password reset | Simple account recovery and no dependency on a University SSO agreement. |
| Roles | Active member, organizer, executive | Matches the operational model without granting every organizer administrative access. |
| Membership authority | Import the legacy Google Sheet once, verify it, then make Supabase authoritative | Avoids a permanent spreadsheet synchronization dependency and makes access auditable. |
| Payments | No payment processor or bank credential collection | The website may show approved e-transfer instructions and record verification metadata only. |
| External integrations | Links and manual workflows at launch | Reduces integration risk while preserving the current club channels. |
| Mobile | Responsive web and PWA-friendly behavior | Covers phones without a separate native application in the first release. |
| Python | Deferred | A separate Python service is not justified until a concrete integration or scheduled workload cannot be handled by Next.js, Supabase, or a small server-side function. |
| Waivers | Model version and completion status now; approve final signing workflow before outdoor RSVP launch | Legal wording and enforceability must come from UCOA, not implementation assumptions. |

## 3. MVP scope

### Included

1. Public club information, eligibility, membership-year information, contact, and approved external links.
2. Supabase email authentication, email confirmation, password reset, and account claim flow for imported members.
3. Profile and membership application data with executive verification.
4. Membership status and access control for pending, active, expired, rejected, and suspended accounts.
5. Event creation, editing, publishing, cancellation, duplication, host assignment, capacity, waitlist, and attendance.
6. One-off events and bounded recurring event series with per-instance edits.
7. Public event summaries and member-only descriptions/locations.
8. Active-member RSVP, cancellation, waitlist promotion, and registration status.
9. Organizer tools limited to hosted events.
10. Executive tools for membership, roles, events, settings, imports, safe exports, and audit logs.
11. Private profile photos and controlled access through Supabase Storage.
12. Versioned waiver records and an approved interim completion/status workflow.
13. Database migrations, RLS policy tests, RSVP transaction tests, and responsive acceptance checks.

### Deferred

These are valid future features, but they must not be represented as working features in the MVP:

- Course progression and certificates.
- Insurance-company portal or external insurance role.
- Pro-deal administration.
- Alpine Club Canada (ACC) integration beyond approved informational links.
- Gear inventory and checkout workflow.
- Member photo gallery.
- Automated Discord invitations or role synchronization.
- Historical Meetup event archive and live Meetup synchronization.
- Native iOS/Android application.
- Separate Python API or background service.

## 4. Roles and audiences

| Audience | Capabilities |
| --- | --- |
| Anonymous visitor | Read public club content and public-safe event summaries; start an application or sign-in flow. |
| Authenticated pending or expired user | Manage their own account/application state and read public content; no member-only event access or RSVP. |
| Active member | Read approved member-only event details and locations, RSVP/cancel, view their own status, manage their own profile, and access approved member links. |
| Organizer | Active-member capabilities plus manage, publish, cancel, and check in attendees for events they host. Cannot assign roles or read unrelated private records. |
| Executive | Full operational management, membership approval, role assignment, site settings, safe import/export, audit review, and all event administration. |

Role assignment must be executive-controlled and database-enforced. Authorization cannot depend on a value users can edit in profile metadata.

## 5. Core user journeys

### Public discovery

The home page explains UCOA's outdoor mission, eligibility, annual membership period, fee/payment boundary, contact method, and public-safe upcoming events. It links to sign in, apply, Discord, Instagram, approved forms, and other club resources.

The site must use UCOA-owned or explicitly licensed images. Meetup or Instagram assets must not be copied into the application without permission.

### New applicant

1. Applicant creates a Supabase Auth account and confirms their email.
2. Applicant completes the minimum profile/application fields required by UCOA.
3. Applicant sees the approved membership fee and e-transfer/cash instructions.
4. Executive reviews eligibility, application information, and payment evidence through a controlled workflow.
5. Executive approves, rejects, or requests correction. Approval creates an active membership for a defined membership year.
6. Approved members receive the member portal and the verified Discord onboarding link if UCOA chooses to provide it.

The application must never collect bank logins, passwords, card details, or unnecessary identity data.

### Imported member

1. Executive uploads a reviewed CSV export through an executive-only dry-run/import flow.
2. The system normalizes values, reports duplicates and missing identifiers, and previews changes.
3. Executive verifies each mapping and chooses which records to import.
4. Imported records begin as `needs_verification` unless reliable dates and status are available.
5. The system sends an account-claim or password-reset invitation only after the email/person mapping is verified.

### Member event participation

1. Member browses a calendar or list filtered by date, activity type, and difficulty.
2. Member opens an event and sees the description and location only when their membership and event policy allow it.
3. Member completes the approved waiver workflow if required.
4. Member RSVPs. A database transaction confirms the member or places them in the waitlist.
5. Member can cancel. The next eligible waitlisted member is promoted atomically.
6. Organizer records attendance after the event.

### Organizer event management

Organizers can draft, publish, edit, duplicate, cancel, and manage only events they host. The form supports explicit start/end times, timezone, public summary, member description, member-only location, difficulty, activity type, capacity, waitlist, hosts, and waiver status.

### Executive administration

Executives can review applications, update membership years, assign roles, manage all events, edit external links, preview imports, export safe reports, inspect audit logs, and revoke access by expiry or suspension.

## 6. Technical architecture

### Application

Initialize from the official Supabase starter:

```text
npx create-next-app@latest <app-directory> -e with-supabase
```

Use TypeScript, the App Router, Tailwind CSS, and ESLint. Keep the generated SSR pattern:

- `lib/supabase/client.ts` for browser components.
- `lib/supabase/server.ts` for Server Components, Server Actions, and Route Handlers.
- The generated Next.js proxy/session refresh path for request cookies.

Use `supabase.auth.getClaims()` for server-side protection, as required by current Supabase SSR guidance. Do not use an unvalidated session object as the basis for authorization.

### Data access

Prefer Server Components for read-only protected pages and Server Actions or Route Handlers for mutations. Keep domain authorization close to the mutation and repeat the database authorization through RLS. Client-side visibility checks are for user experience only.

### Environment variables

The committed `.env.example` should contain only public client configuration:

```text
NEXT_PUBLIC_SUPABASE_URL=<supabase-project-url>
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<supabase-publishable-key>
```

Administrative secret keys belong only in server-side deployment variables and local secret stores. They must never appear in browser code, committed files, screenshots, logs, or client-exposed Vercel variables.

### Recommended repository layout

```text
app/                         Next.js routes and route-level UI
components/                  Reusable UI and form components
lib/                         Domain helpers, validation, authorization, and Supabase clients
supabase/migrations/         Reproducible database schema, grants, and RLS policies
supabase/tests/              pgTAP security and transaction tests
supabase/seed.sql            Non-production fixtures only
docs/                        Product, security, migration, and operational documentation
.github/                     Project instructions, custom agents, and reusable skills
```

## 7. Data model

The first schema should include these entities. Names are provisional until the first migration is reviewed.

| Entity | Purpose |
| --- | --- |
| `profiles` | Auth-linked display name, first name, last-name initial, affiliation, profile photo path, contact preferences, and timestamps. |
| `memberships` | Membership year, lifecycle status, approval metadata, safe payment verification metadata, and legacy import reference. |
| `user_roles` | Executive-assigned `member`, `organizer`, or `executive` role. |
| `event_series` | Bounded recurring-event definition and timezone. |
| `events` | Explicit event instance, public/member content, schedule, location policy, activity type, difficulty, capacity, status, waiver reference, and series reference. |
| `event_hosts` | Event-to-organizer many-to-many relation. |
| `event_registrations` | RSVP, waitlist, cancellation, promotion, attendance, and safe organizer notes. |
| `waivers` | Versioned waiver metadata and event applicability. |
| `waiver_acknowledgements` | Member, waiver version, event, status, timestamp, and approved evidence reference. |
| `site_settings` | Executive-managed public contact, membership instructions, Discord, Instagram, forms, and other links. No secrets. |
| `audit_log` | Actor, action, entity, safe metadata, timestamp, and request context for sensitive operational actions. |

Use constraints for valid statuses, non-negative capacity, event start before end, valid membership ranges, unique active registrations, and consistent visibility settings. Use explicit IANA timezone values and store timestamps in a timezone-safe format.

## 8. Authorization and security

The full security model is in [docs/security/SECURITY.md](../security/SECURITY.md). The implementation must:

1. Enable RLS on every exposed table.
2. Revoke default `anon` and `authenticated` grants and add only required privileges.
3. Use separate policies for `select`, `insert`, `update`, and `delete`.
4. Keep role checks in trusted server/database logic, not user-editable metadata.
5. Use a private, fixed-search-path security-definer helper only when necessary to avoid policy recursion or permit a narrow role lookup.
6. Add indexes for columns used by RLS filters.
7. Test cross-user isolation, pending/expired denial, organizer scope, role escalation denial, and guessed-ID access.
8. Protect Storage independently with private buckets, path policies, and expiring signed URLs.
9. Avoid caching user-specific protected responses through a public CDN.
10. Write audit entries for approvals, role changes, imports, exports, RSVP overrides, and destructive actions.

## 9. Event and RSVP rules

Events are concrete instances even when they come from a series. Recurring generation must be bounded by an end date or an explicit instance count, with a safe maximum. An organizer can edit or cancel a single instance without silently changing the whole series.

RSVP and waitlist operations must use a server-side database transaction or stored procedure. The operation must:

- Check that the caller is an active member and eligible for the event.
- Enforce waiver requirements once the approved workflow is defined.
- Prevent duplicate active registrations.
- Reserve the last available place atomically.
- Assign a deterministic waitlist position when full.
- Promote the next eligible member after a confirmed cancellation.
- Be idempotent for retries and double submissions.
- Record cancellation, promotion, and organizer overrides in the audit trail where appropriate.

Attendee identity visibility is a product decision and defaults to private. Show only the minimum member information approved by the executive.

## 10. Migration and cutover

The Google Sheet and Meetup are migration sources, not permanent application dependencies. See [docs/membership/members-list-plan.md](../membership/members-list-plan.md) and [docs/legacy/oldwebsite-meetup.md](../legacy/oldwebsite-meetup.md).

### Migration sequence

1. Name a data owner and confirm executive authority to import the sheet.
2. Inventory columns, row count, duplicate rules, date interpretation, missing-email policy, and consent/retention requirements without placing the source export in Git.
3. Produce a sanitized sample and dry-run report.
4. Normalize email and name values and detect duplicates before writes.
5. Import only approved fields into a recorded import batch.
6. Mark uncertain rows `needs_verification`; do not grant access because a row exists.
7. Send account-claim invitations only after identity mapping is verified.
8. Manually recreate or import only authorized upcoming events.
9. Run Meetup and UCOA in parallel for a short pilot period.
10. Publish UCOA as the primary calendar and retain Meetup only as a read-only transition reference.

Do not scrape private Meetup content or copy member photos without explicit authorization. Historical event migration is optional and out of the first cutover.

## 11. Implementation phases

### Phase 1 - Decisions and source inventory

- Confirm executive owner, operational contacts, approved public copy, branding assets, canonical Discord invite, and external forms.
- Approve membership lifecycle and the data retention/consent rules.
- Approve waiver wording and completion workflow before outdoor RSVP.
- Inventory and sanitize the Google Sheet.

**Exit check:** written decisions exist for identity, membership authority, waiver enforcement, external links, and migration ownership.

### Phase 2 - Foundation

- Scaffold from `with-supabase`.
- Configure environment examples and Auth redirect behavior.
- Establish route, component, validation, and error-handling conventions.
- Add CI commands for lint, typecheck, tests, and build.

**Exit check:** a clean starter runs locally with no real credentials committed.

**Progress:** The official `with-supabase` starter, Auth routes, SSR clients, lint, typecheck, test, and build commands are present. Local environment configuration, Auth redirects, and generated database types remain.

### Phase 3 - Schema and authorization

- Write migrations for the core entities, indexes, grants, RLS policies, Storage policies, and audit helpers.
- Generate typed database definitions.
- Add pgTAP tests for each exposed table and role scenario.

**Progress:** The membership, event authorization, private Storage, RSVP, attendance, recurring-generation, per-instance editing, and event-status workflow migrations and pgTAP suites cover date-bounded membership states, executive-only metadata, trusted roles, public-safe event columns, private event details, bounded series, host-scoped organizer access, path-scoped profile/event media, audit records, grants, RLS, transactional capacity/waitlist behavior, concurrent final-slot protection, manager-scoped attendee rosters, audited attendance transitions, idempotent daily/weekly/monthly instance generation, local-time and DST preservation, max-instance bounds, safe template copying, manager-scoped atomic instance edits, local-time input conversion, immutable series links, host/executive publishing and moderation, direct status-update denial, valid status transitions, and registration closure when events are cancelled. The Storage migration now leaves Supabase-managed table ownership and grants intact, compares managed text owner IDs correctly, and preserves owner immutability through RLS. Local migration and pgTAP execution passes with 360 assertions across nine suites. Generated database types, signed URL application code, upload validation, and broader workflow/UI scenarios remain.

**Exit check:** local migrations and RLS tests pass, including anonymous, pending, active-member, organizer, and executive cases.

### Phase 4 - Public and membership experience

- Build public club pages and approved external links.
- Build sign-up, confirmation, reset, profile/application, payment-status, and membership review workflows.
- Add private profile-photo upload and access checks.

**Exit check:** a visitor can apply without seeing private data, and an executive can approve or reject an application.

### Phase 5 - Events and participation

**Progress:** Event and series authorization schema is complete, and server-rendered public event calendar and detail routes are available at `/events` and `/events/[id]` with a discoverable homepage entry point. Detail pages return public summaries to visitors, keep member-only fields behind the existing RLS policy, and use a non-disclosing not-found response for malformed or unauthorized IDs. Authenticated event details now include claims-validated RSVP and cancellation controls backed by the transactional RPCs, with confirmed, waitlisted, cancelled, closed, waiver-blocked, and inactive-membership states. The RSVP/waitlist transaction slice received its review fixes on August 30, 2026: generic non-disclosing cancellation errors, privilege-aligned direct-DML assertions, member-scoped read expectations, organizer RLS coverage for capacity changes, a documented fail-closed interim waiver decision, and a two-session dblink concurrent final-slot test. Attendance recording is now available through a manager-authorized, audited database RPC and protected organizer route with a safe first-name/last-initial roster. Bounded recurring generation is available for daily, weekly, and monthly series: it locks the series, requires owner or executive authorization, preserves local time and duration across timezone changes, copies approved template details and hosts, respects `max_instances`, and is idempotent by series and start timestamp. Per-instance editing is now available at `/protected/events/[id]/edit` through a claims-validated manager page and server action backed by an atomic database RPC; it updates public and member-only fields with local-time conversion while preserving publication status, creator, and series links. Organizer publishing and executive moderation are now available through the same protected workspace and the `set_event_status` RPC: only hosted active organizers or executives can publish, cancel, or complete valid events, direct status updates are denied, and cancellation closes active registration queue entries. The full local database run now passes (360 assertions across nine suites). The approved waiver acknowledgement workflow and application workflow scenarios remain.

- Build calendar/list filters and public/member event detail views.
- Build bounded recurring series and concrete event instances.
- Build per-instance editing for recurring events.
- Build organizer publishing and executive moderation.
- Build transactional RSVP, waitlist, cancellation, promotion, waiver status, and attendance.

**Exit check:** the last-slot race, waitlist promotion, cancellation, event cancellation, and organizer scope tests pass.

### RSVP handoff - August 29, 2026 (resolved August 30, 2026)

The RSVP review fixes in [supabase/migrations/20260829030000_event_registrations.sql](../../supabase/migrations/20260829030000_event_registrations.sql) and [supabase/tests/004_event_registrations.sql](../../supabase/tests/004_event_registrations.sql) were applied on August 30, 2026:

- `cancel_event_registration` now raises the identical generic `event registration unavailable` error for unknown event IDs and for accessible-looking IDs where the caller has no registration, so the RPC no longer discloses draft or private event existence. Test 004 asserts the exact same errcode and message for an unknown ID and an existing hidden draft event.
- The direct registration `UPDATE` and `DELETE` assertions now expect the privilege-layer `42501` denial that matches the select-only grant, and still prove the target rows are unchanged afterward.
- The member-scoped read assertion after the denied delete now expects exactly one row: the member's own registration.
- The `authenticated` role is restored before the capacity-increase checks so organizer RLS is exercised, and the post-cancellation waitlist reads run as the hosting organizer instead of relying on `postgres`.
- A two-session concurrent final-slot race test was added in [supabase/tests/005_event_registration_concurrency.sql](../../supabase/tests/005_event_registration_concurrency.sql) using `dblink`: session A confirms the last place inside an open transaction, session B provably blocks on the event lock, then finishes waitlisted at position one with safe audit records. It uses committed fixtures with idempotent cleanup and only the fixed local-development database credentials.
- The Storage migration was made compatible with Supabase's managed `storage` schema by removing table-level ownership operations, casting managed text `owner_id` values correctly, and enforcing unchanged ownership through RLS rather than a custom trigger.
- Waiver acknowledgement interim decision: waiver-required events continue to fail closed and reject registration until the executive approves the waiver wording and signing workflow (section 13). This is the recorded interim design, not a defect; the approved acknowledgement workflow remains Phase 5 work.

Runtime validation: `npx --yes supabase db reset --local --yes` applies all eight migrations and the seed, and `npm test` passes all nine pgTAP suites (360 assertions) as of August 30, 2026. `npm run lint`, `npm run typecheck`, and `npm run build` also pass. The local stack remains available at the configured local ports while Docker Desktop is running.

### Phase 6 - Migration and pilot

- Build import preview and audit-safe export.
- Rehearse with sanitized membership data.
- Recreate upcoming events and verify private locations.
- Run an executive acceptance pass and a small member pilot.

**Exit check:** migration reports reconcile, pilot feedback is recorded, and cutover risks have owners.

### Phase 7 - Production cutover

- Configure Supabase and Vercel environments separately.
- Configure Auth redirects, email templates, backups, monitoring, and custom domain.
- Run the privacy/security deployment pass.
- Announce the new primary calendar and maintain the agreed Meetup transition period.

**Exit check:** production acceptance checklist is signed by the executive owner.

## 12. Verification strategy

Every feature slice must run the narrowest relevant check before more work is added:

- ESLint, TypeScript, unit/integration tests, and production build.
- `supabase test db` for local migrations and pgTAP RLS tests.
- Playwright coverage for public, pending, active-member, organizer, and executive journeys.
- Database tests for concurrent final-slot RSVP, duplicate requests, cancellation/rejoin, waitlist promotion, and event cancellation.
- Migration rehearsal with row-level inserted/updated/rejected counts and no credentials or banking data.
- Preview deployment test for guessed IDs, cache behavior, signed media URLs, service-key exposure, and safe error responses.
- Responsive checks at phone, tablet, and desktop widths, including long titles, multi-day events, DST transitions, and keyboard navigation.

## 13. Open decisions and risks

| Decision or risk | Owner/action before launch |
| --- | --- |
| Waiver legal text and signing method | Executive obtains approved wording and selects built-in, external, or organizer-recorded completion. |
| Google Sheet ownership and data quality | Executive names data owner and approves a sanitized dry run. |
| Emergency contact necessity and retention | Executive confirms purpose, access, retention, and whether the field should be imported or collected anew. |
| Canonical Discord invite | Verify the current invite and update executive-managed settings. |
| Public attendee visibility | Executive approves the minimum member information shown to other members. |
| Insurance data audiences | Define legal and operational requirements before creating a separate role or document portal. |
| ACC relationship | Confirm whether this is informational, a partnership, or a future integration. |
| Email delivery | Configure a reliable Supabase Auth sender and operational contact before inviting imported members. |

## 14. Later roadmap

1. Courses as an event subtype or related model reusing hosts, registrations, waivers, attendance, and notifications.
2. Gear inventory and checkout.
3. Pro-deal administration with expiry and link verification.
4. Member event photos and gallery permissions.
5. Insurance documents with per-document authorization.
6. Discord automation and role synchronization after privacy and consent review.
7. ACC integration or approved reference pages.
8. Notifications, calendar feeds, and optional historical reporting.
9. A Python service only if a concrete integration or scheduled workload requires it.

## 15. Related documentation

- [Finance and e-transfer boundary](../finance/finance-plan.md)
- [Membership migration](../membership/members-list-plan.md)
- [Security model](../security/SECURITY.md)
- [Meetup findings](../legacy/oldwebsite-meetup.md)
- [Instagram findings](../legacy/instagram.md)
- [External service inventory](../legacy/external-services.md)
- [Construction timeline](../HISTORY/project-construction-timeline.md)