---
name: ucoa-rls-review
description: 'Review or design UCOA Supabase authorization, RLS policies, grants, Storage access, Auth claims, role checks, private event data, and security tests. Use before shipping schema or protected-route changes.'
argument-hint: 'Name the UCOA table, route, mutation, Storage bucket, or security slice to review.'
user-invocable: true
---
# UCOA RLS and Privacy Review

## When to use

Use this skill when a change touches Supabase SQL, database grants, RLS, Auth/session handling, Storage, roles, memberships, private event fields, imports, exports, or protected Next.js routes.

Read [the UCOA security model](../../../docs/security/SECURITY.md) and the relevant section of [the implementation plan](../../../docs/planning/PLAN.md).

## Procedure

1. List the rows, columns, operations, and audiences the change affects.
2. Trace identity validation from the request to the database.
3. Check that server code uses validated claims and that client checks are not treated as authorization.
4. Inspect table grants, RLS enablement, operation-specific policies, helper functions, indexes, and tests.
5. Check both active membership and trusted role where required. Check expiry and suspension behavior.
6. Check guessed IDs, cross-user access, public/member field separation, safe errors, logs, cache headers, and Storage paths.
7. Review any security-definer function for a fixed search path, schema-qualified names, restricted execute grants, and a narrow purpose.
8. For mutations, inspect transaction boundaries, retries, idempotency, and audit entries.
9. Run the narrowest available database, typecheck, lint, or security test without using real member data.
10. Add or request a regression test for each concrete finding.

## Required test cases

- Anonymous read and write denial.
- Pending and expired user denial for member-only data and RSVP.
- Active member access limited to approved rows and own mutations.
- Organizer scope limited to hosted events.
- Executive role assignment cannot be self-granted.
- Cross-user profile, membership, registration, waiver, and media denial.
- Guessed event ID cannot reveal private details or exact location.
- Storage path and signed URL expiration behavior.
- Concurrent RSVP capacity and waitlist transitions where relevant.

## Output

Findings come first, ordered by severity and linked to files/lines when available. Then report test gaps, residual risk, validation results, and a short scope summary. If no issues are found, say so plainly.
