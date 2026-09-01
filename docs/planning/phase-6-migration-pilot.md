# Phase 6 Migration and Pilot

**Status:** in progress - planning and sanitized rehearsal only

**Started:** August 31, 2026

**Owner:** UCOA executive data owner (to be named)

This phase covers the controlled membership migration rehearsal, authorized upcoming-event recreation, executive acceptance, and a small member pilot. It does not authorize a production import or cutover. The Google Sheet and Meetup remain external sources until UCOA approves the transition.

## Phase 5 dependency

Phase 5 is not closed. Phase 6 technical rehearsal may use synthetic or sanitized fixtures, but it must not bypass these outstanding requirements:

- Complete the authenticated event-detail, waiver, RSVP, cancellation, and error-state review at phone, tablet, and desktop widths.
- Record UCOA approval of the final waiver wording, completion method, evidence owner, retention, acceptance date, and unresolved risks.
- Keep unsupported external, organizer-recorded, and unresolved legacy waiver paths fail-closed until the approved completion path is available.

See [phase-5-acceptance.md](phase-5-acceptance.md) for the controlling checklist.

## Workstream 1: Source authority

Before requesting or handling an export, record:

- The executive authority and data owner, including a backup owner.
- The source owner, permitted purpose, export date, and expected row count.
- The source columns that are in scope and the retention/deletion date.
- Whether the export may be used for rehearsal, pilot, and production cutover.

No real member export belongs in Git, chat, logs, or local fixtures. Use synthetic data or an approved sanitized sample until these decisions are recorded.

## Workstream 2: Reviewed mapping

The mapping must be approved before import code or writes are enabled.

| Source value | Rehearsal destination | Rule |
| --- | --- | --- |
| Email | Normalized staging identity key | Normalize case and whitespace; missing or duplicate values go to review. |
| First name | `profiles.first_name` | Validate and preserve only the approved identity field. |
| Last name or initial | `profiles.last_name_initial` | Store the minimum display identity required by UCOA. |
| Membership year | `memberships.membership_year_start` and `membership_year_end` | Validate the September-to-August convention selected by the executive. |
| Membership status or payment indicator | Membership status plus safe verification metadata | Never infer `active` from an unreviewed value. |
| Legacy row reference | Restricted membership/import audit reference | Preserve for reconciliation; do not expose it to members. |

UCID, emergency-contact details, passwords, banking data, card data, and unapproved free-text notes are excluded by default. Affiliation, profile photos, payment verification metadata, import-batch tracking, and any additional fields require an approved purpose, access policy, and retention rule before use.

## Workstream 3: Dry run and reconciliation

The rehearsal must produce a report without writing member access or sending claim mail. The report must separate:

- Inserts, updates, unchanged rows, rejected rows, deferred rows, duplicates, and missing identifiers.
- Invalid dates, unsupported statuses, ambiguous identity matches, and prohibited fields.
- Source count, destination count, and every difference with a reason.
- A deterministic batch/reference identifier and safe audit counts without raw personal data.

The import design must be server-only, executive-authorized, idempotent, safe to retry, and protected by database authorization. Imported memberships begin as `needs_verification` unless the executive confirms identity, eligibility, dates, and status. No passwords are imported.

## Workstream 4: Upcoming-event rehearsal

Recreate only upcoming events that UCOA authorizes. For each event, verify the public summary, local timezone, start/end time, host, capacity, private description, exact location, waiver state, and registration behavior. Do not scrape or copy private Meetup details, attendee data, profiles, media, or images without authorization.

During the rehearsal, Meetup remains a transition reference. Run both calendars in parallel for the approved period and record discrepancies in event ownership, dates, locations, hosts, RSVP counts, and attendance. Do not make UCOA authoritative until the executive approves the cutover decision.

## Workstream 5: Executive acceptance and member pilot

The pilot cohort must be small, explicitly approved, and limited to people whose identity mapping and participation are authorized. Validate:

- Account claim or signup, email confirmation, membership status, and access denial for pending or expired accounts.
- Member-only event details, waiver gating, RSVP, cancellation, waitlist promotion, and attendance visibility.
- Organizer scope for hosted events and executive review of audit records.
- Reconciliation of membership, upcoming events, registrations, and attendance against the approved source snapshot.
- Feedback, incidents, corrections, rollback needs, and unresolved risks with named owners.

## Acceptance checklist

- [x] Phase 6 planning and sanitized-rehearsal boundary is recorded.
- [ ] Executive authority, data owner, and backup owner are named.
- [ ] Source export authority, date, row count, purpose, and retention are recorded.
- [ ] Mapping and field minimization are approved.
- [ ] Sanitized rehearsal input passes validation without prohibited fields.
- [ ] Duplicate, missing-email, ambiguous-match, invalid-date, and unsupported-status queues have dispositions.
- [ ] Dry-run report reconciles all source rows without raw personal data.
- [ ] Import batch identity, audit counts, retry behavior, correction, and rollback procedures are defined.
- [ ] Account claims are limited to verified identity mappings and no passwords are imported.
- [ ] Authorized upcoming events are recreated and private locations are manually verified.
- [ ] Executive acceptance and a small member pilot pass the access, RSVP, waiver, and attendance checks.
- [ ] Parallel-calendar results and cutover risks are recorded.
- [ ] Executive approves Supabase as the authoritative source of truth.

## Current blockers and decisions

- No sanitized Google Sheet sample or source row count has been supplied for rehearsal.
- The data owner, backup owner, export authority, and retention/deletion period are not recorded.
- UCID and emergency-contact purpose, access, consent, and retention remain unapproved.
- The membership-year convention and payment-verification rule require executive confirmation.
- Phase 5 waiver approval and final responsive acceptance remain prerequisites for a real member pilot.
- Canonical external links and the Meetup parallel-period owner still require executive confirmation.

## Exit criteria

Phase 6 can close when the approved dry-run report reconciles, duplicate and exception queues have dispositions, the sanitized pilot passes, upcoming-event data is verified, rollback/correction steps are documented, parallel-calendar results are accepted, and the executive records the cutover decision and unresolved-risk owners.

## Related documents

- [Implementation plan](PLAN.md)
- [Phase 5 acceptance](phase-5-acceptance.md)
- [Membership migration plan](../membership/members-list-plan.md)
- [Security model](../security/SECURITY.md)
- [Meetup findings](../legacy/oldwebsite-meetup.md)
- [External service inventory](../legacy/external-services.md)
