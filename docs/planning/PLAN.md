# UCOA Website Implementation Plan

**Status:** implementation in progress

**Last reviewed:** September 21, 2026

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
| Membership authority | Google Drive remains the authoritative member master; Supabase stores website accounts, operational access, events, and waiver records | Keeps the executive-owned directory canonical while giving the website a controlled, auditable operational record. Executives reconcile through an on-demand Excel export and manual copy/paste. |
| Payments | No payment processor or bank credential collection | The website may show approved e-transfer instructions and record verification metadata only. |
| External integrations | Links and manual workflows at launch | Reduces integration risk while preserving the current club channels. |
| Mobile | Responsive web and PWA-friendly behavior | Covers phones without a separate native application in the first release. |
| Python | Deferred | A separate Python service is not justified until a concrete integration or scheduled workload cannot be handled by Next.js, Supabase, or a small server-side function. |
| Waivers | Model version, completion status, and private document references now; approve final signing workflow before outdoor RSVP launch | Legal wording and enforceability must come from UCOA, not implementation assumptions. |

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
10. Executive tools for membership, roles, events, settings, on-demand directory exports, signed-waiver downloads, and audit logs.
11. Private profile photos and controlled access through Supabase Storage.
12. Versioned waiver records, private document references, and an approved interim completion/status workflow.
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

### Existing directory member

1. A person creates a website account and supplies the approved profile and application fields.
2. The account starts as pending and receives no member-only access.
3. An executive verifies the person and manages the website membership/access record in Supabase.
4. The executive generates an on-demand Excel export when the Google Drive master needs website-account or operational updates.
5. The executive manually reviews and copies approved values into the Google Drive master; the website does not bulk-import or silently overwrite the master.

### Member event participation

1. Member browses a calendar or list filtered by date, activity type, and difficulty.
2. Member opens an event and sees the description and location only when their membership and event policy allow it.
3. Member reviews the approved private waiver document and completes the approved waiver workflow if required.
4. Member RSVPs. A database transaction confirms the member or places them in the waitlist.
5. Member can cancel. The next eligible waitlisted member is promoted atomically.
6. Organizer records attendance after the event.

### Organizer event management

Organizers can draft, publish, edit, duplicate, cancel, and manage only events they host. The form supports explicit start/end times, timezone, public summary, member description, member-only location, difficulty, activity type, capacity, waitlist, hosts, and waiver status.

### Executive administration

Executives can review applications, update website membership years, assign roles, manage all events, edit external links, export the member directory, review and download signed waiver PDFs, inspect audit logs, and revoke access by expiry or suspension.

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
| `memberships` | Website membership year, lifecycle status, approval metadata, and safe payment verification metadata; it does not replace the Google Drive member master. |
| `user_roles` | Executive-assigned `member`, `organizer`, or `executive` role. |
| `event_series` | Bounded recurring-event definition and timezone. |
| `events` | Explicit event instance, public/member content, schedule, location policy, activity type, difficulty, capacity, status, waiver reference, and series reference. |
| `event_hosts` | Event-to-organizer many-to-many relation. |
| `event_registrations` | RSVP, waitlist, cancellation, promotion, attendance, and safe organizer notes. |
| `waivers` | Versioned waiver metadata, private document references, and event applicability. |
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

## 10. Google Drive master and operational export

Google Drive remains the authoritative member master. Supabase stores website accounts, website membership/access decisions, event operations, and waiver records; it is not a replacement master directory and it does not receive a bulk import from Google Drive.

### Operating sequence

1. The executive-owned Google Drive spreadsheet remains the canonical directory and is maintained through its existing controlled process.
2. A person creates a website account and supplies only the profile, contact, student, affiliation, and emergency-contact fields approved for the website.
3. An executive verifies the account and manages its website membership status, role, payment-verification metadata, and operational flags in Supabase.
4. An executive generates a filtered Excel workbook from Supabase on demand. The export is not stored in the website after download and every request is audited.
5. The executive manually reviews and copies approved website values into the Google Drive master. Student ID, email, and names are reconciliation aids, not automatic merge keys.
6. Corrections to the canonical directory happen in Google Drive; corrections to website access and event operations happen in Supabase through their authorized workflows.
7. Meetup remains a transition reference for event history and external discovery, not a membership database or synchronization target.

Do not scrape private Meetup content, copy private member media, add a Google Drive import, or create a background synchronization job without a new executive decision.

## 11. Implementation phases

### Phase 1 - Decisions and source inventory

- Confirm executive owner, operational contacts, approved public copy, branding assets, canonical Discord invite, and external forms.
- Approve membership lifecycle and the data retention/consent rules.
- Approve waiver wording and completion workflow before outdoor RSVP.
- Confirm that Google Drive remains the authoritative member master and define the manual export/reconciliation owner.

**Exit check:** written decisions exist for identity, directory authority, export/reconciliation ownership, waiver enforcement, and external links.

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

**Progress:** The membership, event authorization, private Storage, RSVP, attendance, recurring-generation, per-instance editing, event-status, waiver evidence, member-directory export, and signed-waiver migrations and pgTAP suites cover date-bounded membership states, executive-only metadata, trusted roles, public-safe event columns, private event details, bounded series, host-scoped organizer access, path-scoped profile/event media, audit records, grants, RLS, transactional capacity/waitlist behavior, concurrent final-slot protection, manager-scoped attendee rosters, audited attendance transitions, idempotent daily/weekly/monthly instance generation, local-time and DST preservation, max-instance bounds, safe template copying, manager-scoped atomic instance edits, local-time input conversion, immutable series links, host/executive publishing and moderation, direct status-update denial, valid status transitions, registration closure when events are cancelled, approved waiver assignment, private PDF references, signed document access, executive-only Excel and ZIP exports, active-membership boundaries, and export audit records. Local execution of the newest migration/test suite is pending because the Docker-backed Supabase database is unavailable. Generated database types, production artifact upload, and broader workflow/UI scenarios remain.

**Exit check:** local migrations and RLS tests pass, including anonymous, pending, active-member, organizer, and executive cases.

**Validation update (August 31, 2026):** The versioned waiver migration and focused pgTAP suite now pass with the existing coverage: 460 assertions across ten suites. Waiver metadata is versioned and auditable, event assignment is executive-controlled through the authorized RPC, member acknowledgement is available only for the approved built-in method, and external, organizer-recorded, legacy, unavailable, and revoked paths remain fail-closed for RSVP. The member event page receives only safe waiver status fields; the waiver foreign key is not exposed through direct authenticated table access or member-facing props. Ordinary event edits preserve unresolved legacy requirements, and direct authenticated writes to the legacy flag are denied.

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

**Waiver slice (August 30, 2026):** Approved waiver metadata, event assignment, acknowledgement status, member acknowledgement, and waiver-aware registration gating are implemented. The protected event editor includes an approved-waiver selector, and the standalone legacy waiver checkbox has been reconciled so ordinary event edits preserve unresolved legacy requirements. The member event page offers the built-in acknowledgement control without embedding legal wording and explains when an external or organizer-recorded workflow cannot be completed in the portal. The protected attendance roster records an opaque evidence reference for an approved assigned `organizer_recorded` waiver through a host/executive RPC. The newer member waiver centre supports an approved blank-PDF download, active-member signed-PDF submission, personal retrieval, and executive ZIP export; the supplied source remains unapproved until UCOA confirms the wording and workflow. Positive member, organizer, and executive browser workflows plus test-backed authorization boundaries are recorded in [phase-5-acceptance.md](phase-5-acceptance.md); Phase 5 remains in progress until the full authenticated responsive review, production object upload, and UCOA approval of the final wording and workflow are complete.

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

### Phase 6 - Directory reconciliation and executive exports

**Status:** implementation in progress (export and signed-waiver workflows added September 21, 2026)

**Progress:** Google Drive remains the canonical member master. The website now supports account/profile capture, executive-controlled website access, bounded filtered on-demand Excel export, audited export requests, approved waiver PDF download, structurally parsed active-member signed-PDF submission and replacement, executive review status transitions, bounded executive signed-PDF ZIP export, and explicit audited cleanup for unreferenced signed PDFs. No Google Drive import, account-claim batch, background synchronization, or authority cutover is planned.

- Confirm the exact Google Drive reconciliation owner and manual copy/paste procedure.
- Run the executive export and signed-waiver workflows with synthetic or approved operational data.
- Complete the focused pgTAP suite when the local Supabase database is available.
- Obtain UCOA approval for the final waiver document, upload, and status-review workflow.

**Exit check:** the manual reconciliation procedure is accepted, executive-only exports are audited, active/pending/expired/cross-user boundaries pass, and the waiver document workflow has an approved owner and retention decision.

### Phase 7 - Production launch and operations

- Configure Supabase and Vercel environments separately.
- Configure Auth redirects, email templates, backups, monitoring, and custom domain.
- Run the privacy/security deployment pass.
- Launch the website as the operational event portal while retaining Google Drive as the member master and Meetup only as the approved external transition/reference path.

**Exit check:** production acceptance checklist is signed by the executive owner.

## 12. Verification strategy

Every feature slice must run the narrowest relevant check before more work is added:

- ESLint, TypeScript, unit/integration tests, and production build.
- `supabase test db` for local migrations and pgTAP RLS tests.
- Playwright coverage for public, pending, active-member, organizer, and executive journeys.
- Database tests for concurrent final-slot RSVP, duplicate requests, cancellation/rejoin, waitlist promotion, and event cancellation.
- Executive export rehearsal with filtered row counts, audit records, no credentials or banking data, and a documented manual reconciliation check.
- Preview deployment test for guessed IDs, cache behavior, signed media URLs, service-key exposure, and safe error responses.
- Responsive checks at phone, tablet, and desktop widths, including long titles, multi-day events, DST transitions, and keyboard navigation.

## 13. Open decisions and risks

| Decision or risk | Owner/action before launch |
| --- | --- |
| Waiver legal text and signing method | Executive obtains approved wording and selects built-in, external, or organizer-recorded completion. |
| Google Drive ownership and reconciliation | Executive names the directory owner, export reviewer, and manual copy/paste procedure. |
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