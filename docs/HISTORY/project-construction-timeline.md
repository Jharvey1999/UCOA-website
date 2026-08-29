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

## Planned milestones

### 1. Decisions and ownership

**Status:** not started

- Name the executive product owner, data owner, and backup owner.
- Approve public mission, eligibility, membership-year, fee, and contact copy.
- Verify canonical Discord, Instagram, forms, gear, and membership links.
- Approve the waiver workflow and outdoor RSVP gate.
- Define data retention, emergency-contact handling, UCID handling, and attendee visibility.

### 2. Application foundation

**Status:** not started

- Scaffold from `with-supabase`.
- Configure local environment examples and Auth redirects.
- Add lint, typecheck, test, and production-build commands.
- Preserve the documentation and add typed database generation conventions.

### 3. Database and security

**Status:** not started

- Add schema migrations for profiles, memberships, roles, events, series, hosts, registrations, waivers, settings, and audit logs.
- Add grants, RLS policies, Storage policies, indexes, constraints, and pgTAP tests.
- Verify anonymous, pending, expired, member, organizer, and executive access.

### 4. Public and membership workflows

**Status:** not started

- Build public discovery pages and approved external links.
- Build Auth, profile/application onboarding, e-transfer instructions, and membership status.
- Build executive application review and private profile-photo handling.

### 5. Event workflows

**Status:** not started

- Build event list/calendar and public/member detail views.
- Build bounded recurring series and per-instance editing.
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