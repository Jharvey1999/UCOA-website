---
name: UCOA Next.js and Supabase
description: "Use when implementing UCOA Next.js App Router, Supabase Auth, PostgreSQL, Storage, events, memberships, or server mutations."
applyTo: ["app/**", "components/**", "lib/**", "supabase/**"]
---
# UCOA Next.js and Supabase Guidelines

- Follow the official `with-supabase` starter structure and preserve the request-scoped SSR client pattern.
- Use `lib/supabase/client.ts` only for browser code and `lib/supabase/server.ts` for Server Components, Server Actions, and Route Handlers.
- Protect server routes and data with validated Supabase claims. The UI is not an authorization boundary.
- Put schema, grants, RLS policies, constraints, indexes, and transaction functions in reproducible Supabase migrations.
- Keep database types generated from the reviewed schema; do not hand-maintain broad duplicate types.
- Treat active membership and role as separate authorization conditions. Expired, rejected, and suspended members cannot use active-member event capabilities.
- Keep public event summaries separate from member-only descriptions, exact locations, attendees, waivers, and media.
- Perform RSVP, capacity, waitlist, cancellation, and promotion changes transactionally in the database or a tightly scoped server operation.
- Bound recurring event generation by an end date or instance count and allow per-instance edits.
- Use private Storage buckets and expiring signed URLs for member media.
- Do not add a Python API or payment processor to the MVP. Record only safe e-transfer verification metadata.
- Add a focused test for every new authorization rule and mutation failure state before widening the implementation.
