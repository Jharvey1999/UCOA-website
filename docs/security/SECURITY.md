# UCOA Security Model

**Status:** planning and pre-implementation gate

**Last reviewed:** August 29, 2026

**Security owner:** UCOA executive owner, with implementation review by the project maintainers

This document defines the minimum security and privacy behavior for the UCOA member portal. It applies to the Next.js application, Supabase Auth, Postgres, Storage, deployment configuration, migrations, imports, and operational workflows.

## 1. Security objectives

The system must:

1. Make private event and member information available only to the intended audience.
2. Make membership status and role changes executive-controlled and auditable.
3. Prevent an authenticated user from escalating their own privileges.
4. Protect event capacity and waitlist state under concurrent requests.
5. Keep profile photos and event media private unless UCOA explicitly approves a public asset.
6. Avoid collecting payment credentials and other unnecessary sensitive information.
7. Make migrations, exports, and destructive actions reviewable.
8. Provide enough audit and recovery information to investigate an incident without logging raw secrets or unnecessary personal data.

This is an implementation baseline, not a legal opinion. UCOA must approve retention, consent, waiver, emergency-contact, UCID, and insurance requirements before those features are enabled.

## 2. Trust boundaries

| Boundary | Rule |
| --- | --- |
| Browser to Next.js | Treat all browser input and client-side visibility checks as untrusted. Validate on the server. |
| Next.js to Supabase | Use request-scoped SSR clients for user requests. Use secret administrative credentials only in server-only code when strictly necessary. |
| Supabase Auth to application data | Link profiles and memberships to the Auth user ID. Verify claims before protecting server routes. |
| Application to Postgres | RLS and grants remain authoritative even if a route or Server Action is called directly. |
| Application to Storage | Buckets are private by default; use path policies and expiring signed URLs. |
| Import source to database | Accept only an executive-reviewed, validated CSV through a dry-run workflow. Never place the source export in Git or chat. |
| External services | Treat Meetup, Instagram, forms, Discord, Campsite.bio, and email as changeable external dependencies. Store links as managed configuration and verify them before launch. |
| Deployment platform | Keep environment-specific values in Vercel/Supabase secret configuration. Do not commit secrets or expose server keys to the client. |

## 3. Data classification

| Class | Examples | Default handling |
| --- | --- | --- |
| Public | Club mission, eligibility copy, fee and membership-period instructions, public-safe event summary, approved external links | May be served publicly after executive approval. |
| Member-restricted | Event descriptions, exact locations, event attendee information, member directory fields, waiver status, private resources | Require a valid active-member authorization decision and RLS. |
| Sensitive operational | Membership approval notes, payment verification metadata, UCID if approved, emergency contact, organizer notes, import reports, audit metadata | Executive-only or narrowly scoped access; minimize and define retention. |
| Secret | Supabase secret/service key, email provider credentials, webhook secrets, recovery credentials | Server/deployment secret store only; never log, commit, render, or send to the browser. |

The application should not store data merely because an external form currently asks for it. Every sensitive field needs an approved purpose, minimum access, retention period, and deletion procedure.

## 4. Roles and authorization matrix

Roles are stored in a trusted database table and assigned by an executive-controlled operation. Do not use `raw_user_meta_data` or any field the user can edit as the source of authorization. Role claims may be cached in a token, so database checks must still handle status changes and expiry correctly.

| Capability | Anonymous | Pending/expired | Active member | Organizer | Executive |
| --- | --- | --- | --- | --- | --- |
| Read public club content | Yes | Yes | Yes | Yes | Yes |
| Read public event summary | Yes | Yes | Yes | Yes | Yes |
| Read member event description/location | No | No | If event policy permits | If active and permitted | Yes |
| Read attendee identities | No | No | Only minimum approved view | Only operational view for hosted events | Yes |
| RSVP or cancel own registration | No | No | Yes, subject to waiver/event rules | Yes | Yes |
| Manage own profile | No | Limited account state | Yes | Yes | Yes |
| Apply for membership | Start flow | Continue own application | Renew/update as allowed | Renew/update as allowed | Review/manage |
| Create or edit an event | No | No | No | Hosted events only | All events |
| Assign roles | No | No | No | No | Yes |
| Approve membership | No | No | No | No | Yes |
| Read payment verification | No | Own status only | Own status only | No | Yes |
| Run import/export | No | No | No | No | Yes |
| Read audit log | No | No | No | No | Yes, with least-privilege review |

Active membership is a separate condition from role. A person with an organizer role but an expired or suspended membership must not receive active-member event privileges unless an explicitly approved operational exception is implemented and audited.

## 5. Authentication and session handling

Use the official Supabase Next.js SSR approach:

- `@supabase/ssr` and `@supabase/supabase-js`.
- Browser client for browser components.
- Request-scoped server client for Server Components, Server Actions, and Route Handlers.
- Next.js proxy/session refresh path for cookie updates.
- `supabase.auth.getClaims()` to validate identity when protecting pages and data.
- `getUser()` only when the current Auth user record is needed and the network lookup is appropriate.
- Never rely on `getSession()` alone for authorization decisions in server code.

Required Auth behavior:

- Confirm email addresses before account use.
- Provide password reset and account-claim flows.
- Configure exact local, preview, and production redirect URLs.
- Use an approved sender and avoid revealing whether an email belongs to a member in public error messages.
- Rate-limit or otherwise protect repeated sign-in, reset, import, and mutation attempts using platform and application controls.
- Offer sign-out and safe session invalidation.

Reference: [Supabase SSR Auth for Next.js](https://supabase.com/docs/guides/auth/server-side/nextjs).

## 6. Database security and RLS

Every table exposed through the Supabase Data API must be reviewed as a security boundary.

For each exposed table:

1. Enable RLS.
2. Revoke default `anon` and `authenticated` privileges.
3. Grant only the operations the application needs.
4. Write separate `select`, `insert`, `update`, and `delete` policies.
5. Name the database role in every policy.
6. Use `(select auth.uid())` where appropriate for stable policy evaluation.
7. Add indexes for columns used by policy filters.
8. Add pgTAP tests for anonymous, pending, active-member, organizer, executive, cross-user, and denied cases.
9. Review views separately; do not assume a view automatically inherits the underlying table's protection.
10. Keep private authorization helpers in a non-exposed schema when possible.

A security-definer function must:

- Have a narrow purpose.
- Set a fixed `search_path`.
- Schema-qualify names.
- Have execution revoked from public roles unless explicitly required.
- Be covered by allow and deny tests.

Use a security-definer helper only to solve a concrete policy-recursion or trusted role-lookup problem. Do not use it as a shortcut around RLS.

Reference: [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).

### Required policy outcomes

- Anonymous visitors can read only deliberately public content.
- Pending and expired users can read their own account/application state but not member event data or RSVP.
- Active members can read only the member content permitted by event policy and can mutate only their own registration/profile data.
- Organizers can mutate event records only when they are an assigned host, except for explicitly executive-only fields.
- Executives can manage operational records without bypassing audit requirements.
- No user can insert or update a role row that grants them or another user executive access.
- Guessed event, profile, registration, membership, waiver, or media IDs reveal no unauthorized data.

## 7. Storage and media

Use separate private buckets for profile photos and event media. Store a path/reference in Postgres, not a permanent public URL.

- Enforce path ownership and audience policies in Storage.
- Issue short-lived signed URLs only after the caller passes the relevant authorization check.
- Validate content type, size, and image dimensions.
- Generate safe file names; do not use user-provided paths directly.
- Do not make profile photos public by default.
- Do not copy Meetup or Instagram media without UCOA permission and an appropriate license.
- Define deletion behavior for a deleted profile, expired account, event archive, or revoked consent.
- Do not include private media URLs in public metadata or long-lived caches.

## 8. Server-side mutation rules

All mutations must be authorized at the point of execution, validated against a schema, and safe to retry where practical.

High-risk mutations include:

- Membership approval, rejection, suspension, and expiry changes.
- Role assignment and removal.
- Event publication, cancellation, and location changes.
- RSVP, waitlist promotion, attendance overrides, and bulk changes.
- Waiver status changes.
- Imports, exports, and deletion.
- Site-setting changes for external links and payment instructions.

A mutation should:

1. Validate the authenticated claims.
2. Load current role and active-membership state from trusted data.
3. Validate all user input on the server.
4. Rely on RLS or a narrowly scoped stored procedure for the final data boundary.
5. Use a transaction for related updates.
6. Record an audit event for privilege or operational changes.
7. Return safe, non-sensitive errors.

For RSVP, capacity and waitlist state must be decided in one database transaction. Client-side counts are never authoritative.

## 9. Sensitive workflows

### Membership import

- Executive-only access.
- Dry-run and preview before writes.
- Sanitized development data only.
- No passwords or bank data.
- Duplicate and missing-identity review.
- Idempotent batch reference.
- Reconciliation report with counts rather than raw personal data.
- Audit entry for batch approval, execution, and rollback/correction.

### Payment verification

The website displays approved e-transfer/cash instructions but does not process money. Store only safe membership verification metadata. Do not accept bank credentials, card details, security codes, screenshots containing unnecessary financial data, or user self-approval.

### Waivers

Do not invent legal language. Store version, event applicability, completion/status, timestamp, and evidence reference only after UCOA approves the workflow. Enforce the approved requirement before outdoor RSVP.

### Exports

- Executive-only and purpose-limited.
- Explicit confirmation before generation.
- Exclude secrets and unnecessary sensitive fields.
- Prefer expiring downloads or a controlled operational destination.
- Audit actor, purpose, scope, and count.
- Delete temporary files after the approved retention period.

## 10. Secrets and deployment

- Commit `.env.example` with public Supabase URL and publishable key only.
- Keep secret keys in local secret storage and Vercel/Supabase environment configuration.
- Never expose a secret/service key in browser bundles, `NEXT_PUBLIC_*` variables, logs, screenshots, or error messages.
- Use separate development, preview, and production projects or clearly separated environments.
- Rotate credentials after suspected exposure and document the incident.
- Review build output for accidental secret inclusion before production.
- Restrict access to Vercel, Supabase, email, and domain administration to the minimum executive/maintainer group.

## 11. Logging, audit, and privacy

Application logs must not include passwords, access tokens, reset links, bank data, full waiver text, raw import rows, or unnecessary emergency-contact information.

Audit records should include:

- Actor user ID.
- Action name.
- Entity type and ID.
- Timestamp.
- Safe status transition or count metadata.
- Request or correlation ID when available.
- Reason or note only when approved and minimized.

Audit logging does not replace Postgres authorization. It provides accountability after an authorized or attempted sensitive operation.

Define before launch:

- Retention for profiles, memberships, waivers, emergency contacts, UCIDs, registrations, media, audit entries, and import reports.
- Member access and correction process.
- Account deletion and membership-history behavior.
- Incident notification responsibility.
- Backup and restore ownership.

## 12. Threat scenarios and controls

| Scenario | Required control |
| --- | --- |
| Anonymous user guesses an event ID | Public-safe query or RLS prevents private columns/rows from being returned. |
| Pending user calls RSVP endpoint directly | Server claim check, active-membership check, transaction authorization, and RLS deny the mutation. |
| Organizer changes their own role | Role table policy and executive-only mutation deny it. |
| User modifies another member's profile | Owner-scoped update policy and server validation deny it. |
| Two members take the final event slot | Transactional capacity claim gives one confirmed result and one waitlist result. |
| Cancelled member tries to retain a slot | Registration state transition and uniqueness rules release/promote correctly. |
| Private Storage URL is shared | Short expiry, private bucket, and reauthorization limit exposure. |
| Legacy CSV contains a password or bank value | Import schema rejects/omits it; review and logs never retain the raw row. |
| Stale CDN response reveals another user's dashboard | Protected responses use appropriate cache controls and are not publicly cached. |
| External Discord link is stale or hijacked | Executive-managed setting, link verification, and change audit before publishing. |

## 13. Required security tests

Before production:

- Test RLS grants and policies for every exposed table.
- Test anonymous, pending, expired, active-member, organizer, executive, and cross-user cases.
- Test role escalation and direct API/Server Action invocation.
- Test event location/detail privacy by guessed ID.
- Test private Storage access, path traversal attempts, invalid uploads, and signed URL expiry.
- Test RSVP concurrency, duplicate requests, waitlist promotion, cancellation/rejoin, and event cancellation.
- Test import dry-run, duplicate handling, rejected fields, idempotent retry, and audit counts.
- Confirm no secret key or sensitive source data appears in client bundles or logs.
- Confirm protected pages and dashboard responses are not publicly cached.
- Exercise password reset, email confirmation, sign-out, and account-claim flows.
- Run dependency and production build checks before deployment.

Recommended commands once the application exists:

```text
npm run lint
npm run typecheck
npm test
npm run build
supabase test db
```

Use the repository's actual scripts if the scaffold names differ.

## 14. Incident response

When a security or privacy incident is suspected:

1. Record the time, reporter, affected environment, and observed symptom without copying secrets into the report.
2. Restrict or disable the affected route, account, token, link, import batch, or Storage object as appropriate.
3. Rotate exposed credentials and invalidate affected sessions.
4. Preserve safe audit and platform logs for investigation.
5. Determine what data was accessible and for how long.
6. Notify the executive security owner and follow the club's approved notification obligations.
7. Correct the policy or code, add a regression test, and document the resolution.
8. Review whether retention, access, or operational procedures need to change.

## 15. Production gate

Production outdoor RSVP and member migration are blocked until:

- The executive approves this role and privacy model.
- The waiver workflow and wording are approved.
- Membership import ownership and retention are approved.
- RLS and Storage tests pass.
- Secret handling and deployment environments are reviewed.
- The canonical external links are verified.
- Backup, restore, and incident contacts are documented.
- A small-member pilot completes without unresolved high-risk findings.
