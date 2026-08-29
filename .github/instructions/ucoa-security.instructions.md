---
name: UCOA Security
description: "Use when changing Supabase SQL, RLS policies, Auth/session handling, Storage policies, imports, roles, or private UCOA event and membership data."
applyTo: ["supabase/**/*.sql", "lib/supabase/**/*.ts", "app/**/actions.ts", "app/**/route.ts"]
---
# UCOA Security Guidelines

- Validate identity with `supabase.auth.getClaims()` in protected server code; never authorize from an unvalidated session object.
- Enable RLS on every exposed table, revoke default grants, and add only the required `anon` and `authenticated` privileges.
- Write separate, named policies for `select`, `insert`, `update`, and `delete`, including the intended Postgres role.
- Keep authorization data in trusted database tables, never in user-editable metadata.
- Check both role and active membership status for member-only operations.
- Do not expose member descriptions, exact locations, attendee identities, profiles, waivers, or private media to anonymous users.
- Treat service/secret keys as server-only. Never put them in `NEXT_PUBLIC_*`, browser code, logs, tests, or documentation.
- Use security-definer functions only for a narrow need, with a fixed `search_path`, schema-qualified names, restricted execute grants, and tests.
- Add indexes for policy filter columns and test cross-user denial, role escalation denial, and guessed-ID access.
- Keep Storage private and authorize signed URLs before issuing them.
- Use transactions for capacity and waitlist state. Client-side counts and disabled buttons are not security controls.
- Add an audit record for membership, role, import, export, RSVP override, external-setting, and destructive changes without logging sensitive payloads.
