# UCOA Membership Data and Migration Plan

**Status:** Operational directory reconciliation (updated September 21, 2026)

**Last reviewed:** September 21, 2026

## Decision

The Google Drive member master spreadsheet remains the authoritative directory. It must not be committed to this repository, copied into application fixtures, or replaced by a Supabase import.

Supabase stores website accounts, profiles, website membership years, access status, approvals, safe payment verification metadata, events, and waiver records. It is the operational system for the website, but it is not the canonical member directory.

Executives use the on-demand Excel export to review website-account and operational fields, then manually copy approved changes into the Google Drive master. There is no Google Drive import, background synchronization, account-claim batch, or membership cutover workflow.

The retired Phase 6 migration notes are retained at [docs/planning/phase-6-migration-pilot.md](../planning/phase-6-migration-pilot.md) only to record the superseded decision and the current export/reconciliation boundary.

## Why this boundary matters

The member master contains personal information that must stay under the executive-approved Google Drive process. Treating Supabase as a second canonical directory would create conflicting edits, synchronization risk, and unclear retention. Keeping Supabase operational and exporting only on demand gives the executive a deliberate reconciliation point without an automatic overwrite path.

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

These fields are a source observation, not automatic approval for storage. Student identifiers and emergency-contact information require a purpose, access policy, retention period, and executive approval. See [docs/legacy/external-services.md](../legacy/external-services.md) for the source inventory.

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

Collect and retain only fields required for website identity, membership administration, event safety, and approved communications. The website operational record may include:

- Auth-linked user ID and account creation timestamp.
- Email, first name, last name, phone, student ID, and affiliation supplied through the website.
- Membership-year dates, lifecycle status, executive approval metadata, and safe payment-verification metadata.
- Executive directory flags and notes required for website operations.
- Emergency-contact fields only when the member has provided the approved consent and UCOA has confirmed the purpose and retention.

Do not store passwords, bank details, card details, government identification, or unnecessary free-text notes. Do not copy the Google Drive spreadsheet into Supabase as a bulk import.

## Export and reconciliation workflow

1. A member creates or updates their website account through the approved website workflow.
2. The account remains pending until an executive verifies the website record and grants the appropriate website membership status.
3. An executive selects optional status, role, search, and signed-waiver filters and confirms the operational purpose of the export.
4. Supabase generates an Excel workbook in memory with the approved directory headers and website-account fields. The workbook is downloaded immediately and is not retained by the website.
5. The executive manually reviews the workbook and copies approved values into the Google Drive master using human judgment. Matching by email, student ID, and name is a review aid, not an automatic merge.
6. Export requests create audit records containing filter context and row counts, not the member payload.
7. Corrections to the member master are made in Google Drive; website access corrections are made through executive-authorized Supabase workflows.

The export route is executive-only, claims-validated, filtered server-side, and protected by the database RPC. It must never accept client-side bulk writes, expose a service key, or become an import endpoint.

## Acceptance checks

- Google Drive ownership, export ownership, and the manual copy/paste procedure are recorded.
- No Google Drive spreadsheet or real member export appears in Git, chat, logs, or local fixtures.
- No passwords, bank credentials, card data, or unapproved sensitive fields enter the website.
- New website accounts begin pending and do not receive member-only access.
- Active membership and role checks are enforced for website operations; expired, suspended, and banned accounts lose active-member access.
- Executive export filters, row counts, and audit records are tested without exposing raw member payloads.
- Corrections have a named owner in both the Google Drive master process and the website access process.

## Open decisions

- Name the Google Drive directory owner, export reviewer, and backup owner.
- Confirm the exact Google Drive headers and the manual reconciliation procedure.
- Approve student-ID purpose, access, and retention.
- Approve emergency-contact purpose, access, consent, and retention.
- Confirm whether a member photo is collected in the new app or through the external form.
- Confirm whether website membership can be active before payment verification or only after it.
- Define retention and deletion rules for downloaded Excel workbooks and signed-waiver ZIP archives.