---
name: ucoa-membership-import
description: 'Plan, validate, or rehearse the UCOA Google Sheet to Supabase membership migration, including CSV mapping, identity verification, lifecycle status, duplicate handling, dry runs, reconciliation, and cutover.'
argument-hint: 'Describe the sanitized import, source inventory, mapping, or UCOA cutover task.'
user-invocable: true
---
# UCOA Membership Import

## When to use

Use this skill for Google Sheet inventory, sanitized CSV import, legacy member account claims, membership status reconciliation, or Meetup-to-UCOA cutover.

Read [the membership migration plan](../../../docs/membership/members-list-plan.md), [the security model](../../../docs/security/SECURITY.md), and [the Meetup findings](../../../docs/legacy/oldwebsite-meetup.md).

## Hard boundaries

- Use sanitized fixtures only. Never request, print, or commit a real member export.
- Do not import passwords, bank credentials, card data, unapproved UCIDs, emergency contacts, or raw free-text notes.
- Do not grant access merely because a legacy row exists.
- Do not merge people from matching names alone.
- Do not scrape private Meetup content or copy member media.
- Do not run a production import without explicit executive approval and a dry-run report.

## Procedure

1. Identify the source owner, export date, intended fields, destination entities, and retention decision.
2. Inventory columns and define a reviewed mapping before writing import code.
3. Normalize email and names without destroying the source reference.
4. Detect missing identifiers, duplicate emails, ambiguous person matches, invalid dates, unsupported statuses, and prohibited fields.
5. Create a dry-run report with inserts, updates, unchanged rows, rejected rows, and reasons.
6. Require executive approval before writes.
7. Keep imported memberships `needs_verification` unless identity, eligibility, dates, and status are confirmed.
8. Send account-claim or password-reset mail only after verified email/person mapping; never import passwords.
9. Make the batch idempotent, auditable, and safe to retry. Keep raw data out of logs.
10. Reconcile source counts with inserted, updated, rejected, deferred, and duplicate results.
11. Test pending/expired denial and active-member access after import.
12. For cutover, recreate only authorized upcoming events and run a short parallel period before Supabase becomes authoritative.

## Acceptance checklist

- Data owner and executive authority are recorded.
- Mapping and field minimization are approved.
- Sanitized rehearsal passes.
- Duplicate and missing-email queues have dispositions.
- No secrets, credentials, banking information, or unapproved sensitive fields enter the database.
- Every imported row has a batch/reference and intended status.
- Account claims require verified mapping.
- Reconciliation and correction/rollback procedures exist.
- Source-export retention and deletion are defined.
- Cutover decision and unresolved risks are recorded in the construction timeline.

## Output

Return findings or blockers first, then the proposed mapping/workflow, required executive decisions, validation results, and a concise acceptance status.
