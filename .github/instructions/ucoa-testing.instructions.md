---
name: UCOA Testing
description: "Use when adding or reviewing UCOA tests for RLS, memberships, events, RSVP concurrency, migrations, responsive workflows, or production readiness."
applyTo: ["**/*.test.ts", "**/*.test.tsx", "supabase/tests/**/*.sql"]
---
# UCOA Testing Guidelines

- Run the narrowest relevant check immediately after each focused change.
- For every exposed table, test grants and allow/deny behavior for anonymous, pending, expired, active-member, organizer, executive, and cross-user cases.
- Prove allowed writes with returned data and prove denied writes leave the target row unchanged.
- Test direct server-action or API invocation, not only the happy-path UI.
- Test event capacity with two simultaneous final-slot attempts, duplicate requests, cancellation/rejoin, waitlist promotion, and event cancellation.
- Test recurring event bounds, timezone/DST transitions, long titles, and per-instance cancellation.
- Test imports with sanitized fixtures for duplicate emails, missing identifiers, invalid dates, rejected fields, dry-run preview, idempotent retry, and audit counts.
- Test private event details, exact locations, profiles, waivers, and Storage URLs by guessed ID/path.
- Verify no secrets or raw member/payment data appear in fixtures, snapshots, logs, or client bundles.
- Use the actual repository scripts once the application is scaffolded; do not claim a check passed when it was unavailable.
