---
name: ucoa-feature-slice
description: 'Implement one focused UCOA feature slice in Next.js and Supabase, including route design, authorization, migrations, tests, and documentation. Use for membership, events, RSVP, organizer, executive, or public-portal work.'
argument-hint: 'Describe the single UCOA feature or failing behavior to implement.'
user-invocable: true
---
# UCOA Feature Slice

## When to use

Use this skill for one bounded change to the UCOA portal. Examples include a membership review action, public event list, member-only event detail, RSVP transition, organizer event form, executive setting, or related test/documentation update.

Read the relevant section of [the implementation plan](../../../docs/planning/PLAN.md) and [the security model](../../../docs/security/SECURITY.md) before changing code.

## Procedure

1. Identify the nearest route, component, server mutation, migration, test, or failing behavior.
2. Read only that surface and its direct dependencies. Do not map the whole repository.
3. Write one falsifiable local hypothesis and the cheapest check that could disconfirm it.
4. Define the audience and data boundary: anonymous, pending/expired, active member, organizer, or executive.
5. Implement the smallest coherent slice using the existing Next.js/Supabase patterns.
6. Validate protected server requests with Supabase claims and enforce authorization through RLS or a narrowly scoped database operation.
7. For mutations, validate input on the server and make related state changes transactional.
8. Add focused allow and deny tests. For RSVP, add concurrency and idempotency coverage.
9. Run the narrowest relevant validation immediately after the edit.
10. Update the owning documentation or timeline only when the behavior or decision changed.

## UCOA-specific checks

- Active membership is separate from role and date-bounded.
- Public event summaries never include member-only descriptions, exact locations, attendees, waivers, or private media.
- Organizer writes are limited to events they host.
- Executive-only changes are auditable.
- Recurring events have a bounded end date or instance count.
- Payment behavior contains no processor, bank login, card, or credential collection.
- Private media uses Storage policies and expiring signed URLs.
- External links are managed settings, not scattered constants.

## Output

Report changed files, the focused validation command and result, security/privacy impact, and any unresolved executive decision. Keep the next step to one small slice.
