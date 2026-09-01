# UCOA Website

The University of Calgary Outdoor Adventurers (UCOA) website will replace the club's core Meetup workflows with a private, responsive member portal. It will support public club discovery, approved membership, outdoor event publishing, RSVP and waitlists, organizer workflows, and executive administration.

The repository contains the planning source of truth plus the initial Next.js and Supabase implementation, including membership, event authorization, private Storage policy slices, RSVP transactions, a public event calendar, manager-scoped attendance recording, bounded recurring event generation, protected per-instance editing, organizer publishing with executive moderation, versioned waiver acknowledgement, private waiver PDF delivery, and organizer-recorded evidence references. The implementation source of truth is [docs/planning/PLAN.md](docs/planning/PLAN.md).

## Product goal

Give UCOA one controlled place to:

- Explain who can join and how the annual membership fee is paid.
- Manage member applications, membership years, and access status.
- Publish hikes, scrambles, climbing sessions, camping trips, courses, and social events over time.
- Keep event descriptions, exact locations, attendee information, and private media restricted to the right audience.
- Let active members RSVP, join a waitlist, cancel, and see their upcoming activities.
- Let organizers manage the events they host and let executives manage the club.

The first release is a core Meetup replacement. Courses, insurance documents, pro deals, Alpine Club Canada (ACC) information, gear checkout, photo galleries, and automated Discord provisioning are later increments rather than placeholder features in the MVP.

## MVP decisions

| Area | Decision |
| --- | --- |
| Frontend and server boundary | Next.js App Router using the official Supabase `with-supabase` starter |
| Database and auth | Supabase PostgreSQL, Auth, Row Level Security, and private Storage |
| Hosting | Vercel for the Next.js application; Supabase-hosted project for data and auth |
| Authentication | Supabase email/password authentication with email confirmation and password reset |
| Roles | Active member, organizer, and executive |
| Membership source of truth | Controlled one-time import from the legacy Google Sheet, then Supabase |
| Payments | No payment processor and no bank credentials; show approved e-transfer instructions and record verification metadata only |
| External integrations | Links and manual workflows for Discord, Instagram, forms, gear, and contact email at launch |
| Waivers | Store versioned metadata and private document references; keep the supplied 2025-2026 forms in draft until UCOA approves the wording and completion workflow |
| Mobile target | Responsive web and PWA-friendly behavior; no separate native application in the first release |
| Python | Deferred until a concrete integration or scheduled workload justifies a separate service |

## Core workflows

### Public discovery

Visitors can read the club mission, eligibility rules, membership-year information, public-safe event summaries, contact information, and approved external links. Public pages must never reveal private event details, exact locations, attendee identities, member profiles, waiver records, or private media.

### Membership

An applicant creates an account, confirms their email, supplies the minimum profile information required by UCOA, submits or completes the club's approved application workflow, receives e-transfer instructions, and waits for executive verification. An Auth account alone does not grant member access. Membership status and dates control event access.

The current public membership information says the fee is CAD 10 and the membership year runs September 1 through August 31. Confirm all wording and the payment instructions with the executive before launch.

### Events

Events support one-off and bounded recurring instances, explicit start and end times, the `America/Edmonton` timezone by default, activity type, difficulty, hosts, public summary, member-only description, member-only location, capacity, waitlist, cancellation, versioned waiver status, and attendance tracking. Executives can assign an approved waiver version to an event, active members can acknowledge the approved built-in method before RSVP, and authorized hosts or executives can record an opaque reference for an approved organizer-recorded method; external, unresolved legacy, and unavailable workflows remain fail-closed. Approved private waiver PDFs use event-scoped expiring signed URLs and are not publicly served. Recurring generation supports daily, weekly, and monthly local-time schedules with idempotent instance creation, hosted managers can edit one concrete event without changing its series link or publication status, and hosted organizers or executives can publish, cancel, and complete events through audited status transitions. RSVP changes must be decided atomically in the database.

### Administration

Executives approve members, assign organizer roles, manage all events and settings, review registrations and attendance, run a previewable legacy import, export safe reports, and review the audit log. Organizers can manage only events they host and cannot grant themselves privileges.

## Security and privacy

Security is a product requirement, not a later hardening task. The complete model is documented in [docs/security/SECURITY.md](docs/security/SECURITY.md). Key rules are:

- Verify identity with Supabase server-side claims before protecting routes or data.
- Enforce membership and role authorization in Postgres RLS and server-side mutations, not only in UI code.
- Keep authorization data out of user-editable metadata.
- Enable RLS and set explicit grants for every exposed table.
- Keep service credentials server-only and never commit them.
- Use private Storage buckets, path-scoped policies, and expiring signed URLs for member media.
- Audit membership approvals, role changes, imports, exports, RSVP overrides, and destructive actions.
- Do not copy private Meetup content or member media without authorization.

## Migration boundary

Meetup remains a transition reference and optional archive, not a live synchronization dependency. The migration will use an executive-reviewed export of the legacy Google Sheet and manually recreate or import only authorized upcoming events. Legacy rows without a verified mapping or reliable membership dates remain `needs_verification`; they do not automatically receive access.

Phase 6 migration and pilot planning is in progress, with sanitized rehearsal as the only current scope. See [docs/planning/phase-6-migration-pilot.md](docs/planning/phase-6-migration-pilot.md), [docs/membership/members-list-plan.md](docs/membership/members-list-plan.md), and [docs/legacy/oldwebsite-meetup.md](docs/legacy/oldwebsite-meetup.md) for the migration rules and observed source behavior.

## External sources

The public source inventory is dated August 29, 2026 and is descriptive rather than a promise that every link or count is still current:

- [Meetup group](docs/legacy/oldwebsite-meetup.md)
- [Instagram](docs/legacy/instagram.md)
- [External services and links](docs/legacy/external-services.md)

The current public Meetup and Campsite.bio pages showed the Discord invite `https://discord.gg/7XrWTcBCpW`, while the original README contained a different invite. The executive must verify the canonical invite before it is published in the new site. External links will be stored in executive-managed settings so stale links can be corrected without a code release.

## Implementation sequence

1. Confirm ownership, approved public copy, branding assets, external links, waiver workflow, and the membership data owner.
2. Scaffold the Next.js application with the Supabase starter while preserving this documentation.
3. Add reproducible Supabase migrations, typed database definitions, seed fixtures, and RLS tests.
4. Build authentication, profile/application onboarding, membership status, and public discovery.
5. Build events, recurring instances, member-only detail visibility, RSVP, waitlists, cancellation, and attendance.
6. Build organizer and executive workflows, audit logging, safe settings, and import preview.
7. Rehearse the sanitized membership migration and upcoming-event cutover.
8. Pilot with executives and a small member group, run the security and acceptance checks, then make the new calendar primary.

## Definition of done for the MVP

- A visitor can understand the club and apply without exposing private member data.
- An approved active member can sign in, view authorized event details, RSVP, cancel, and be promoted from a waitlist.
- A pending or expired account cannot RSVP or read member-only event details.
- An organizer can manage only their hosted events.
- An executive can approve membership, assign roles, manage content, run a dry-run import, and inspect audit entries.
- Database-level tests cover grants, RLS isolation, role escalation denial, Storage access, and RSVP concurrency.
- The app passes lint, typecheck, tests, and production build checks and works at phone, tablet, and desktop widths.

## Documentation map

- [Implementation plan](docs/planning/PLAN.md)
- [Membership migration](docs/membership/members-list-plan.md)
- [Finance and e-transfer boundary](docs/finance/finance-plan.md)
- [Security model](docs/security/SECURITY.md)
- [Meetup findings](docs/legacy/oldwebsite-meetup.md)
- [Instagram findings](docs/legacy/instagram.md)
- [External service inventory](docs/legacy/external-services.md)
- [Construction timeline](docs/HISTORY/project-construction-timeline.md)
- [Waiver source inventory](docs/security/waivers/README.md)
- [Project Copilot guidance](.github/copilot-instructions.md)

## Working with Copilot

Project-wide rules are in [.github/copilot-instructions.md](.github/copilot-instructions.md). Focused file instructions, custom agents, and reusable skills live under [.github](.github). They are intentionally small and point back to the detailed docs so implementation work can proceed with less repeated prompting.
