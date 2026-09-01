# UCOA Membership Data and Migration Plan

**Status:** Phase 6 rehearsal planning (started August 31, 2026)

**Last reviewed:** August 29, 2026

## Decision

The existing Google Sheet will be used as a controlled, one-time migration source. It will not remain the long-term source of truth and it must not be committed to this repository.

After the migration and verification period, Supabase will be authoritative for accounts, profiles, membership years, access status, approvals, and safe payment verification metadata.

The Phase 6 migration and pilot worklist is [docs/planning/phase-6-migration-pilot.md](../planning/phase-6-migration-pilot.md). This status records planning only; no real export or production import is authorized.

## Why this boundary matters

The legacy sheet may contain personal information with unclear ownership, duplicate rows, outdated status, or fields that are not needed by the new application. Treating it as a live database would make authorization, auditability, and deletion difficult. A reviewed import creates a clear boundary and a repeatable report.

## Current source and related forms

The current public membership form is a Jotform linked from Meetup. As observed on August 29, 2026, it requests or describes:

- First name and last name.
- UCID, with `N/A` for applicants without one.
- Email.
- Emergency contact name and phone number.
- Outdoor interests.
- A CAD 10 membership fee, payable by e-transfer or cash.
- Membership validity from September 1 through August 31.
- Meetup as the event schedule during the transition.

These fields are a source observation, not automatic approval for storage. UCID and emergency contact information require a purpose, access policy, retention period, and executive approval before they are imported or collected in the new app. See [docs/legacy/external-services.md](../legacy/external-services.md) for the source inventory.

## Membership lifecycle

Use explicit status and dates rather than treating a Supabase Auth account as an active member.

| Status | Meaning | Event access |
| --- | --- | --- |
| `account_created` | Auth account exists but profile/application is incomplete. | Public content only. |
| `pending` | Application is awaiting executive review or payment verification. | Public content only. |
| `needs_verification` | Imported or ambiguous record requires identity, eligibility, or date verification. | Public content only. |
| `active` | Executive approved the member for a defined membership year. | Member content and RSVP, subject to waiver rules. |
| `expired` | Membership year ended without renewal. | Account and renewal/contact access; no member event access or RSVP. |
| `rejected` | Application was not approved. | Account and public content only. |
| `suspended` | Executive temporarily removed access for an operational or conduct reason. | Public content only until reinstated. |

Every active row must have a membership-year start and end date. The application should derive access from `status = active` and the current date falling within that range. Do not grant access from a role alone if the membership is expired or suspended.

## Data minimization

Import only fields required for identity matching, membership administration, event safety, and approved communications. The initial target is:

- Auth-linked user ID, created only when an account is claimed.
- Normalized email, after executive verification of the person mapping.
- First name and last-name initial or approved display name.
- Profile photo path, collected or uploaded through the new app if required by UCOA.
- Affiliation category and safe eligibility notes.
- Membership-year dates and lifecycle status.
- Executive approval metadata.
- Safe payment verification metadata, never banking credentials.
- Legacy source reference and import batch ID.

Do not import passwords, bank details, card details, government identification, unnecessary free-text notes, or private information that has no approved purpose. Emergency contacts and UCIDs remain pending decisions; do not import them by default.

## Proposed migration mapping

The exact source columns must be confirmed during inventory. This mapping is a review template, not permission to import every column.

| Legacy source value | Destination | Rule |
| --- | --- | --- |
| Email | Import staging, then Auth/profile link | Normalize case and whitespace; report missing or duplicate values. Do not create a user silently. |
| First name | `profiles.first_name` | Preserve the user-provided value after validation. |
| Last name or initial | `profiles.last_name_initial` or approved display field | Store the minimum public identity required by UCOA. |
| Profile photo reference | Private Storage path | Re-collect or migrate only with permission; do not publish legacy URLs blindly. |
| UCID | Restricted field only if approved | Confirm Student Union purpose, access, and retention before import. |
| Affiliation/school | `profiles.affiliation_category` | Normalize to an approved enum; retain uncertain values for review. |
| Membership date/year | `memberships.starts_on`, `ends_on` | Validate date range and school-year interpretation. |
| Active/paid indicator | `memberships.status` and verification metadata | Never infer `active` from a vague truthy value without executive review. |
| Payment note | Safe verification metadata | Strip banking details and free-text secrets; record method/status only. |
| Emergency contact | Restricted safety field only if approved | Do not import by default; define retention and access first. |
| Legacy row ID | `memberships.legacy_reference` | Preserve for reconciliation without exposing it to members. |

## Import workflow

1. Executive names the data owner and confirms authority to use the export.
2. Data owner records the export date, source columns, row count, and intended purpose.
3. A sanitized sample is used to develop and test normalization without exposing real member data in Git or chat.
4. The executive-only import tool accepts a reviewed CSV and creates an import batch.
5. Validation reports missing email, duplicate email, duplicate person matches, invalid dates, unsupported status, suspicious values, and fields excluded by policy.
6. The preview shows inserts, updates, unchanged rows, and rejected rows before any write.
7. Executive approves the batch or cancels it.
8. The import writes only approved fields and creates an audit record with counts, not raw personal data.
9. Imported records are `needs_verification` unless the executive confirms identity, eligibility, membership year, and status.
10. Verified members receive account-claim or password-reset email. No passwords are imported.
11. The data owner reconciles source and destination counts and stores the report in the approved operational location, not in Git.

The import path must be server-only, idempotent for a batch, protected by executive authorization, and safe to retry. It must not accept arbitrary client-side bulk writes or expose a service key.

## Duplicate and identity rules

- Normalize email for comparison but preserve the user-facing form only after verification.
- Treat duplicate emails as a review queue, not an automatic merge.
- Do not merge people based only on matching names.
- Require executive confirmation for a legacy row-to-account mapping.
- Keep a legacy reference and import batch ID for every imported membership.
- Never overwrite a verified current profile with an unverified legacy value.
- Record rejected/ambiguous rows and the reason without placing raw source data in logs.

## Cutover

1. Rehearse on a sanitized export.
2. Import and verify a small pilot cohort.
3. Send account-claim emails only to verified mappings.
4. Run the new portal and Meetup in parallel for one agreed operating period.
5. Compare active members, upcoming events, RSVP counts, and organizer access.
6. Announce Supabase as the new source of truth.
7. Retain the spreadsheet as a restricted archive only for the approved retention period.
8. Record deletion or archival of unnecessary copies.

Meetup is not a live membership synchronization target. Historical records remain optional and are not required for the first cutover.

## Acceptance checks

- Source row count equals inserted, updated, rejected, or explicitly deferred rows.
- Duplicate and missing-email reports have an executive disposition.
- No passwords, bank credentials, card data, or unapproved sensitive fields are imported.
- All imported accounts start with the intended status.
- A pending or expired imported member cannot see member-only event data or RSVP.
- A verified active member can claim an account and use the portal.
- Every import batch is auditable without exposing raw personal data.
- A rollback or correction procedure exists before production import.

## Open decisions

- Name the data owner and backup owner.
- Confirm the Google Sheet columns and current row count.
- Approve UCID purpose, access, and retention.
- Approve emergency contact purpose, access, and retention.
- Confirm whether a member photo is collected in the new app or through the external form.
- Confirm whether membership can be active before payment verification or only after it.
- Define the retention/deletion date for the source export and rejected rows.