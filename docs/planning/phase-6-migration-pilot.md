# Directory Reconciliation and Executive Export

**Status:** implementation complete; operational acceptance pending

**Updated:** September 21, 2026

**Owner:** UCOA executive directory owner (to be named)

The earlier Google Drive-to-Supabase migration and cutover plan is retired. Google Drive remains the authoritative member master. This document records the replacement operating model: Supabase manages website accounts and operational access, and executives generate an on-demand export for manual reconciliation with the Google Drive master.

No Google Drive import, account-claim batch, background synchronization, or membership authority cutover is part of this scope. Meetup remains an external event-history and discovery reference, not a membership source.

## Phase 5 dependency

Phase 5 is not closed. The export and waiver workflows must not bypass these outstanding requirements:

- Complete the authenticated event-detail, waiver, RSVP, cancellation, and error-state review at phone, tablet, and desktop widths.
- Record UCOA approval of the final waiver wording, completion method, evidence owner, retention, acceptance date, and unresolved risks.
- Keep unsupported external, organizer-recorded, and unresolved legacy waiver paths fail-closed until the approved completion path is available.

See [phase-5-acceptance.md](phase-5-acceptance.md) for the controlling checklist.

## Workstream 1: Google Drive master

Before downloading or reconciling an export, record:

- The executive directory owner and backup owner.
- The permitted export purpose and the retention/deletion rule for downloaded workbooks.
- The exact Google Drive headers and the manual copy/paste procedure.
- The people authorized to review emergency-contact and signed-waiver fields.

No real member export belongs in Git, chat, logs, or local fixtures. Use synthetic data for automated tests and keep operational downloads in the approved executive workspace.

## Workstream 2: Website account and access record

Supabase is the website operational record. It is not a copy of the Google Drive master and it does not grant access merely because a person appears in Drive.

| Website value | Operational use | Rule |
| --- | --- | --- |
| Account email and name | Website identity and executive reconciliation | Capture through Auth/signup and validate before granting access. |
| Student ID and affiliation | Website profile and export fields | Collect only for the approved purpose and retention period. |
| Membership year and status | Website event authorization | Active access requires an in-range active membership, not a Drive row alone. |
| Payment verification | Safe executive metadata | Store verification state only; never store banking credentials. |
| Emergency contact | Restricted website safety field | Require approved purpose, consent, access, and retention. |

Passwords, banking data, card data, and unapproved free-text notes are excluded. Additional fields require an approved purpose, access policy, and retention rule.

## Workstream 3: On-demand Excel export

The executive export route and database RPC:

- Require validated Supabase claims and an executive role.
- Require an explicit confirmation parameter in addition to the UI checkbox.
- Apply status, role, search, and signed-waiver filters in the database.
- Generate the approved directory headers plus website-account and operational fields in memory.
- Return the workbook directly without storing it in Supabase or the application.
- Write an audit record containing filter context and row count, never the exported member payload.

The executive reviews the workbook and manually copies approved values into Google Drive. Email, student ID, and names are reconciliation aids and do not trigger an automatic merge or overwrite.

## Workstream 4: Signed-waiver document operations

The separate waiver workflow:

- Executives approve a waiver version and make its blank PDF member-downloadable.
- Active members download the blank PDF and upload a signed PDF through the private `signed-waivers` bucket.
- The database records one current submission per member and waiver version, resets review state on replacement, and audits changes.
- Members can retrieve their own recorded signed PDF while authorized; executives can review submissions through approved, rejected, and revoked states, list them, and bulk-download recorded PDFs as a ZIP.
- Review mutations record the executive actor and timestamp; member Storage updates are denied, and member deletion is limited to an unreferenced upload left by a failed submission.
- Uploads require PDF MIME metadata, the `%PDF-` file signature, and successful structural parsing; ZIP exports are bounded by file count and aggregate bytes and are audited only after archive generation succeeds.
- Direct signed-waiver Storage reads are owner-only. Executive binary access goes through claims-validated routes, and export auditing is service-role-only and tied to the listed submission IDs.
- Executives can explicitly clean up route-owned, unreferenced PDFs older than an approved cutoff through a bounded, audited service-side workflow; this covers replacement leftovers and objects surviving account deletion.
- The final waiver wording, approval actor, status-review owner, and retention policy remain UCOA decisions.

## Acceptance checklist

- [x] Google Drive remains the authoritative member master.
- [x] Supabase stores website accounts and operational membership/access records without a bulk directory import.
- [x] Executive-only filtered Excel export is claims-validated, database-authorized, audited, and generated on demand.
- [x] Signed-waiver upload and executive ZIP export use separate private Storage and metadata authorization.
- [x] Executive signed-waiver downloads are bounded, route-controlled, and cannot bypass the export audit through direct Storage reads.
- [x] Replaced or deleted-account orphan PDFs have an explicit bounded cleanup workflow without a hard-coded retention period.
- [x] Signup captures the approved website profile and emergency-contact fields with explicit consent metadata.
- [ ] Directory owner, export reviewer, backup owner, and downloaded-file retention are recorded.
- [ ] Executive export and manual copy/paste reconciliation are accepted using approved operational data.
- [ ] Focused pgTAP coverage runs successfully after the local Docker-backed Supabase database is available.
- [ ] UCOA approves the final waiver wording, signed-document review workflow, and retention period.

## Current blockers and decisions

- The Google Drive directory owner, export reviewer, backup owner, and downloaded-file retention period are not recorded.
- Student-ID and emergency-contact purpose, access, consent, and retention require executive confirmation.
- The membership-year convention and payment-verification rule require executive confirmation.
- Phase 5 waiver approval and final responsive acceptance remain prerequisites for production waiver use.
- The focused Supabase suite cannot run until Docker Desktop's Linux engine and the local PostgreSQL service are available.

## Exit criteria

This operating-model work can close when the directory owner accepts the manual reconciliation procedure, executive export audit and authorization tests pass, downloaded-file retention is documented, the focused database suite runs successfully, and UCOA approves the signed-waiver document workflow.

## Related documents

- [Implementation plan](PLAN.md)
- [Phase 5 acceptance](phase-5-acceptance.md)
- [Membership migration plan](../membership/members-list-plan.md)
- [Security model](../security/SECURITY.md)
- [Meetup findings](../legacy/oldwebsite-meetup.md)
- [External service inventory](../legacy/external-services.md)
