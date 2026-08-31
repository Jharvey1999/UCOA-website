# UCOA Website Construction Timeline

This document records major planning, implementation, migration, testing, and launch milestones. Add a dated entry when a milestone is completed or a decision changes the plan. Do not record passwords, tokens, member exports, banking data, or other sensitive values here.

## Baseline - August 29, 2026

- Repository is documentation-only; application code and database migrations have not yet been scaffolded.
- The product goal is to replace the UCOA club's core Meetup workflows with a private responsive portal.
- The agreed MVP stack is Next.js App Router, the official Supabase `with-supabase` starter, Supabase Auth/Postgres/Storage, and Vercel.
- A separate Python backend is deferred.
- The Google Sheet is a one-time migration source; Supabase will become authoritative after verification.
- MVP roles are active member, organizer, and executive.
- The current Meetup group is private, with member-only event details, locations, attendee information, and media.
- The current public source inventory includes Meetup, Instagram, Campsite.bio, Discord, Jotform, Google Forms, communal gear, and contact email.
- A Discord invite discrepancy exists between the original README and the current public Meetup/Campsite.bio links and must be resolved before launch.

## Application scaffold - August 29, 2026

- Scaffolded the Next.js App Router application from the official Supabase `with-supabase` starter, preserving the existing README, docs, and .github guidance.
- The starter provides Supabase SSR clients (`lib/supabase/client.ts`, `lib/supabase/server.ts`), email/password auth routes, a protected route example, Tailwind, and shadcn-style UI components.
- Ran `supabase init` to create `supabase/config.toml` for reproducible local development and migrations.
- Added `typecheck` and `test` scripts; lint, typecheck, and production build all pass. Database test execution requires the local Supabase runtime.

## Initial membership authorization - August 29, 2026

- Added the first reproducible migration for Auth-linked profiles, date-bounded membership lifecycle states, trusted executive-assigned roles, and audit records.
- Separated executive-only payment verification, legacy references, approval identity, and notes into `membership_admin`; members can read their own lifecycle status without receiving operational metadata.
- Added explicit authenticated grants, operation-specific RLS policies, fixed-search-path security-definer helpers, audit triggers, indexes, constraints, and a deferred active-approval invariant.
- Added pgTAP coverage for anonymous denial, applicant creation, cross-user profile isolation, membership and role escalation denial, expired organizer access, executive access, and audit creation.
- The suite passes as part of the local five-suite pgTAP run, with 32 assertions covering membership and role authorization.

## Event authorization - August 29, 2026

- Added event series, concrete event instances, private details, and event-host relations with bounded recurrence fields and IANA timezone validation.
- Added explicit public event-column grants, a private event-management projection, member/private detail policies, host-scoped organizer management, executive management, and cross-series ownership checks.
- Added immutable event and series ownership, protected linked-series deletion, deferred publication validation, safe event/host/series audit records, and 73 pgTAP assertions covering privacy, role scope, failed mutations, and audit attribution.
- The suite passes as part of the local five-suite pgTAP run, with 73 assertions covering event privacy and management scope.

## Private Storage authorization - August 29, 2026

- Added private `profile-photos` and `event-media` buckets with image MIME allowlists and five/fifty megabyte limits.
- Added fixed-path helpers and operation-specific Storage policies for profile ownership, executive access, active-member event reads, hosted-organizer writes, and guessed-ID denial.
- Added 54 pgTAP assertions covering anonymous, pending, active, expired, suspended, organizer, executive, malformed/nested paths, orphan event IDs, ownership integrity, and protected delete behavior.
- Signed URL issuance, upload MIME/dimension validation through the Storage API, and application upload routes remain pending.
- The suite passes as part of the local five-suite pgTAP run, with 54 assertions covering private Storage access and ownership.

## RSVP transaction draft - August 29, 2026

- Added the initial `event_registrations` schema, active-member registration RPC, cancellation RPC, capacity locking, deterministic waitlist promotion, stale-membership skipping, direct-DML denial, and safe registration audit records.
- Added 56 pgTAP assertions for pending/expired denial, idempotent registration, full-event behavior, waitlist promotion, rejoin, closed events, capacity protection, unlimited capacity, visibility, and audit records.
- This slice was superseded by the review fixes and concurrency coverage recorded below; the waiver-required path remains fail-closed pending executive approval.
- The completed slice passes as part of the local five-suite pgTAP run, with 58 assertions covering RSVP, waitlist, cancellation, and audit behavior.

## RSVP review fixes and concurrency test - August 30, 2026

- Applied the four paused-handoff review fixes: `cancel_event_registration` now returns one generic unavailable error for unknown and inaccessible event IDs, direct registration `UPDATE`/`DELETE` assertions expect the privilege-layer denial with unchanged rows, the member-scoped read assertion expects only the caller's row, and the `authenticated` role is restored around the capacity-change checks so organizer RLS is exercised.
- Added a hidden-draft-event fixture proving the cancellation RPC emits identical errors for unknown and undisclosed events (suite now 58 assertions).
- Added a two-session `dblink` concurrent final-slot race suite (7 assertions): the second session provably blocks on the event lock, then lands waitlisted at position one with safe audit records, using committed fixtures with idempotent cleanup.
- Made the Storage migration compatible with Supabase's managed `storage` schema by removing table-level ownership operations, casting managed text `owner_id` values correctly, and preserving owner immutability through RLS rather than a custom trigger.
- Recorded the interim waiver decision: waiver-required events fail closed and reject registration until the executive approves the acknowledgement workflow.
- `npx --yes supabase start` now applies all four migrations and the seed successfully, and `npm test` passes all five pgTAP suites with 224 assertions. `npm run lint`, `npm run typecheck`, and `npm run build` also pass.

## Public event calendar - August 30, 2026

- Replaced the starter-only homepage with a UCOA public portal entry point that links directly to the event calendar and member authentication flows.
- Added the server-rendered `/events` route, which selects only public-safe event columns and relies on the existing anonymous RLS policy for published and cancelled public events.
- Added the server-rendered `/events/[id]` route for public summaries and RLS-gated member descriptions and exact locations, with malformed and unauthorized IDs returning a non-disclosing not-found response.
- Updated the SSR proxy allowlist so anonymous visitors can reach `/events`, `/events/*`, and `/auth/*`, while protected application paths still require validated Supabase claims.
- Added a claims-validated RSVP server action and event-detail control that call the existing transactional registration/cancellation RPCs, display the caller's own confirmed or waitlisted state, and map waiver, capacity, closed-event, and membership failures to safe messages.
- Added timezone-aware dates and times, activity and difficulty labels, cancellation state, a protected-details notice, and deliberate empty and unavailable states without exposing exact locations, attendees, waivers, or media.
- The homepage, calendar route, and valid event-detail route return successfully through the local Next.js server; malformed event IDs return `404`. With no `.env` or `.env.local` configured, the calendar and detail route correctly render their unavailable configuration states.

## Attendance workflow - August 30, 2026

- Added the manager-scoped `record_event_attendance` RPC for active hosted organizers and executives, with published/completed event checks, confirmed-registration checks, correction support, fixed search paths, explicit grants, and audited `attended`/`no_show` transitions.
- Added the manager-scoped `list_event_attendance` RPC, which returns only first name, last-name initial, registration status, and attendance timestamp; direct organizer profile reads remain denied.
- Added the protected `/protected/events/[id]/attendance` route and roster controls, with claims validation, RLS-backed registration resolution, safe errors, and a manager-only link from event details.
- Added 35 pgTAP assertions covering anonymous, pending, expired, active-member, non-host, host, executive, cross-event, invalid-status, cancelled/waitlisted target, direct-DML, profile-isolation, and audit cases. The attendance-focused run passed 259 assertions across six suites; the full local run at that milestone passed 293 assertions across seven suites.

## Recurring event generation - August 30, 2026

- Added the bounded `generate_event_series_instances` database RPC with owner/executive authorization, series locking, draft/published template selection, daily/weekly/monthly recurrence, IANA timezone-aware local-time conversion, duration preservation, safe template detail and host copying, `max_instances` bounds, and idempotency by `(series_id, starts_at)`.
- Added a named unique constraint for generated series starts and explicit authenticated-only execution grants; anonymous, pending, expired, and non-owner callers receive safe authorization failures.
- Added 34 pgTAP assertions covering authorization, generic unavailable errors, weekly dates, DST conversion, monthly day bounds, caps, empty templates, executive access, idempotency, copied fields, and audit attribution.
- At this milestone, `npx --yes supabase db reset --local --yes` applied all six migrations and the seed, and `npm test` passed all seven pgTAP suites with 293 assertions.

## Per-instance event editing - August 30, 2026

- Added the atomic `update_event_instance` database RPC with manager authorization, server-side input validation, IANA timezone conversion for local form values, public and member-only field updates, and unchanged publication status.
- Added an immutable series-link trigger so direct event updates cannot detach a generated instance or move it to another series; creator and series identity remain fixed.
- Added the protected `/protected/events/[id]/edit` route, claims-validated server action, responsive event form, safe errors, and manager-only edit link from event details.
- Added 30 pgTAP assertions covering anonymous, pending, expired, non-host, owner, executive, malformed-input, DST conversion, atomic private-detail, series-link, and audit cases. The local run at that milestone passed 323 assertions across eight suites.

## Organizer publishing and status moderation - August 30, 2026

- Added the authenticated-only `set_event_status` RPC with host/executive authorization, draft publication, event cancellation, ended-event completion, idempotent repeated status requests, safe transition errors, and fixed search paths.
- Removed direct `status` updates from the authenticated event-table grant while retaining the separate event-edit and capacity columns required by existing manager workflows.
- Event cancellation now closes confirmed and waitlisted registrations in the same database operation and preserves audited event and registration changes.
- Added the protected status control to `/protected/events/[id]/edit`; hosted organizers can manage their events and executives can moderate any event visible through the management projection.
- Added 37 pgTAP assertions covering function privileges, column privileges, anonymous/pending/expired/cross-organizer denial, host publication and cancellation, missing private details, transition bounds, executive moderation, registration closure, idempotency, and status audit attribution. The local run now passes 360 assertions across nine suites.

## Planned milestones

### 1. Decisions and ownership

**Status:** not started

- Name the executive product owner, data owner, and backup owner.
- Approve public mission, eligibility, membership-year, fee, and contact copy.
- Verify canonical Discord, Instagram, forms, gear, and membership links.
- Approve the waiver workflow and outdoor RSVP gate.
- Define data retention, emergency-contact handling, UCID handling, and attendee visibility.

### 2. Application foundation

**Status:** in progress (scaffold complete August 29, 2026; env examples, Auth redirects, and typed database generation remain)

- Scaffold from `with-supabase`.
- Configure local environment examples and Auth redirects.
- Add lint, typecheck, test, and production-build commands.
- Preserve the documentation and add typed database generation conventions.

### 3. Database and security

**Status:** in progress (membership, event authorization, and Storage slices complete August 29, 2026; generated types and remaining RLS slices remain)

- Add schema migrations for profiles, memberships, roles, events, series, hosts, registrations, waivers, settings, and audit logs.
- Add grants, RLS policies, Storage policies, indexes, constraints, and pgTAP tests.
- Verify anonymous, pending, expired, member, organizer, and executive access.

### 4. Public and membership workflows

**Status:** not started

- Build public discovery pages and approved external links.
- Build Auth, profile/application onboarding, e-transfer instructions, and membership status.
- Build executive application review and private profile-photo handling.

### 5. Event workflows

**Status:** in progress (event authorization schema complete August 29, 2026; recurring generation and per-instance editing complete August 30, 2026; organizer workflow implementation remains)

- Build event list/calendar and public/member detail views.
- Build bounded recurring series generation and per-instance editing.
- Build organizer publishing, capacity, waitlist, cancellation, waiver status, and attendance.
- Add transaction tests for concurrent RSVP and promotion.

### 6. Migration rehearsal

**Status:** not started

- Obtain a sanitized sample of the Google Sheet.
- Run import preview and reconciliation.
- Confirm no credentials, banking data, or unapproved fields enter the system.
- Import and verify a small pilot cohort.

### 7. Executive acceptance and member pilot

**Status:** not started

- Run the complete executive workflow.
- Pilot with a small set of members and organizers.
- Compare membership, calendar, RSVP, and attendance outcomes with Meetup.
- Record unresolved risks and owners.

### 8. Production cutover

**Status:** not started

- Configure Vercel and Supabase environments, Auth email delivery, redirects, backups, monitoring, and domain.
- Complete deployed privacy/security checks.
- Run Meetup and UCOA in parallel for the approved period.
- Announce UCOA as the primary calendar and retain only the approved Meetup transition/archive path.

## Entry template

Copy this template for future milestones:

```markdown
### YYYY-MM-DD - Milestone title

- **Status:** planned | in progress | complete | blocked
- **Owner:** role or person
- **Change:** concise description
- **Validation:** command, test, review, or acceptance result
- **Open items:** remaining decisions or follow-up
```

## Related documentation

- [Implementation plan](../planning/PLAN.md)
- [Security model](../security/SECURITY.md)
- [Membership migration](../membership/members-list-plan.md)
- [Meetup findings](../legacy/oldwebsite-meetup.md)