# UCOA Project Guidelines

## Mission

Build a private, responsive UCOA member portal that replaces the club's core Meetup workflows. The repository is currently documentation-first; treat [docs/planning/PLAN.md](../docs/planning/PLAN.md) as the implementation source of truth.

## Read before changing code

Use the smallest relevant document for the task:

- [Implementation plan](../docs/planning/PLAN.md) for scope, architecture, data model, phases, and verification.
- [Security model](../docs/security/SECURITY.md) for Auth, RLS, Storage, roles, secrets, and privacy.
- [Membership migration](../docs/membership/members-list-plan.md) for imports and legacy data.
- [Finance boundary](../docs/finance/finance-plan.md) for e-transfer and payment handling.
- [Legacy source inventory](../docs/legacy/external-services.md) for Meetup, Instagram, forms, Discord, and external links.

Do not reread every document for a narrow task. Start at the named file, symbol, failing test, or route, then take one nearby read if needed.

## Architecture

- Use Next.js App Router with TypeScript and the official Supabase `with-supabase` starter.
- Use Supabase Auth, PostgreSQL, Row Level Security, and private Storage.
- Use Server Components for reads and Server Actions or Route Handlers for mutations when appropriate.
- Use `lib/supabase/client.ts` in browser code and `lib/supabase/server.ts` for request-scoped server work.
- Validate protected server requests with `supabase.auth.getClaims()`; never authorize from an unvalidated session object.
- Keep the MVP on Next.js and Supabase. Do not add a Python service unless a concrete requirement justifies it.
- Keep schema, grants, RLS policies, and seed/test fixtures in reproducible Supabase files.

## Non-negotiable security rules

- Enforce authorization in the database and server mutations, not only in UI code.
- Enable RLS and explicit grants for every exposed table; test allow and deny cases.
- Keep roles in trusted database data. Never use user-editable metadata for authorization.
- Active membership and role are separate checks; expired or suspended members lose active event privileges.
- Keep service/secret keys server-only and out of Git, logs, client bundles, and `NEXT_PUBLIC_*` variables.
- Use private Storage buckets and expiring signed URLs for member media.
- Do not expose private event descriptions, exact locations, attendee identities, profiles, waivers, or media to anonymous users.
- Never collect bank credentials, card data, payment secrets, or passwords from the legacy source.

## Working loop

1. State one local hypothesis and the cheapest check that could disconfirm it.
2. Make the smallest focused change that tests the hypothesis.
3. Run the narrowest relevant validation immediately.
4. Preserve unrelated user changes and avoid broad refactors.
5. Report changed files, validation, and any unresolved decision.

Do not commit or create branches unless explicitly requested. Do not invent legal waiver wording or silently choose between conflicting external links.

## Documentation and external sources

Keep public research time-stamped and distinguish observed facts from assumptions. External links are executive-managed settings, not hard-coded secrets. Do not copy private Meetup data or social media assets without authorization. Update [docs/HISTORY/project-construction-timeline.md](../docs/HISTORY/project-construction-timeline.md) when a milestone or architectural decision is completed.

## Validation

Use the repository's actual scripts once the application is scaffolded. The expected checks are:

```text
npm run lint
npm run typecheck
npm test
npm run build
supabase test db
```

For every feature, add focused tests for the relevant roles, private/public boundary, failure state, and concurrent mutation behavior.
