-- Two-session concurrent final-slot RSVP race.
-- dblink opens two real database sessions, so the fixtures must be committed
-- and are removed again at the end. The dblink connection uses the fixed
-- local-development credentials from the Supabase CLI runtime only; no
-- production secret is involved.

create extension if not exists dblink with schema extensions;

-- Idempotent cleanup of any leftovers from an aborted earlier run.
begin;
delete from public.audit_log
where entity_id in (
    select id from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000101'
  )
  or entity_id = '40000000-0000-0000-0000-000000000101'
  or entity_id in (
    select id from public.memberships
    where user_id in (
      '00000000-0000-0000-0000-000000000031',
      '00000000-0000-0000-0000-000000000032',
      '00000000-0000-0000-0000-000000000033'
    )
  )
  or actor_id in (
    '00000000-0000-0000-0000-000000000031',
    '00000000-0000-0000-0000-000000000032',
    '00000000-0000-0000-0000-000000000033'
  );
delete from public.event_registrations
where event_id = '40000000-0000-0000-0000-000000000101';
delete from public.event_private_details
where event_id = '40000000-0000-0000-0000-000000000101';
delete from public.event_hosts
where event_id = '40000000-0000-0000-0000-000000000101';
delete from public.events
where id = '40000000-0000-0000-0000-000000000101';
delete from public.user_roles
where user_id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
);
delete from public.membership_admin
where membership_id in (
  select id from public.memberships
  where user_id in (
    '00000000-0000-0000-0000-000000000031',
    '00000000-0000-0000-0000-000000000032',
    '00000000-0000-0000-0000-000000000033'
  )
);
delete from public.memberships
where user_id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
);
delete from auth.users
where id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
);
commit;

-- Committed fixtures visible to the two racing sessions.
begin;

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000031', 'race-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000032', 'race-member-a@example.test'),
  ('00000000-0000-0000-0000-000000000033', 'race-member-b@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '00000000-0000-0000-0000-000000000031',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000032',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000033',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000031'
from public.memberships
where user_id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
);

insert into public.user_roles (user_id, role, assigned_by)
values (
  '00000000-0000-0000-0000-000000000031',
  'organizer',
  '00000000-0000-0000-0000-000000000032'
);

insert into public.events (
  id,
  created_by,
  title,
  public_summary,
  starts_at,
  ends_at,
  timezone_name,
  activity_type,
  visibility,
  status,
  capacity,
  waitlist_enabled
)
values (
  '40000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000031',
  'Final Slot Race Event',
  'A one-slot event used for the concurrent registration race.',
  '2026-11-01 14:00:00+00',
  '2026-11-01 16:00:00+00',
  'America/Edmonton',
  'hike',
  'members_only',
  'published',
  1,
  true
);

insert into public.event_private_details (event_id, member_description, waiver_required)
values (
  '40000000-0000-0000-0000-000000000101',
  'Private race event details.',
  false
);

insert into public.event_hosts (event_id, user_id, assigned_by)
values (
  '40000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000031'
);

commit;

select plan(7);

-- Session A claims the final slot and keeps its transaction open,
-- holding the event row lock taken by register_for_event.
do $$
declare
  conninfo text := 'host=host.docker.internal port=54322 dbname=postgres user=postgres password=postgres';
begin
  perform extensions.dblink_connect('race_a', conninfo);
  perform extensions.dblink_connect('race_b', conninfo);
  perform extensions.dblink_exec('race_a', 'begin');
  perform extensions.dblink_exec('race_a', 'set local role authenticated');
  perform extensions.dblink_exec(
    'race_a',
    'set local "request.jwt.claim.sub" = ''00000000-0000-0000-0000-000000000032'''
  );
end
$$;

select is(
  (
    select registration_status
    from extensions.dblink(
      'race_a',
      'select registration_status::text from public.register_for_event(''40000000-0000-0000-0000-000000000101'')'
    ) as session_a(registration_status text)
  ),
  'confirmed',
  'session A confirms the final slot inside a still-open transaction'
);

-- Session B races for the same slot and must block on the event lock.
do $$
begin
  perform extensions.dblink_exec('race_b', 'begin');
  perform extensions.dblink_exec('race_b', 'set local statement_timeout = ''15s''');
  perform extensions.dblink_exec('race_b', 'set local role authenticated');
  perform extensions.dblink_exec(
    'race_b',
    'set local "request.jwt.claim.sub" = ''00000000-0000-0000-0000-000000000033'''
  );
  perform extensions.dblink_send_query(
    'race_b',
    'select registration_status::text, waitlist_position from public.register_for_event(''40000000-0000-0000-0000-000000000101'')'
  );
  perform pg_sleep(0.25);
end
$$;

select is(
  extensions.dblink_is_busy('race_b'),
  1,
  'session B blocks on the event lock while session A holds it'
);

-- Releasing session A lets session B finish as waitlisted, not confirmed.
do $$
begin
  perform extensions.dblink_exec('race_a', 'commit');
end
$$;

create temp table race_b_result as
select *
from extensions.dblink_get_result('race_b')
  as session_b(registration_status text, waitlist_position integer);

do $$
begin
  -- Drain the empty terminating result set and close session B.
  perform 1
  from extensions.dblink_get_result('race_b')
    as session_b(registration_status text, waitlist_position integer);
  perform extensions.dblink_exec('race_b', 'commit');
  perform extensions.dblink_disconnect('race_a');
  perform extensions.dblink_disconnect('race_b');
end
$$;

select is(
  (select registration_status from race_b_result),
  'waitlisted',
  'session B is waitlisted after losing the final-slot race'
);
select is(
  (select waitlist_position from race_b_result),
  1,
  'session B receives deterministic waitlist position one'
);

select is(
  (
    select count(*) from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000101'
      and status = 'confirmed'
      and user_id = '00000000-0000-0000-0000-000000000032'
  ),
  1::bigint,
  'exactly one confirmed registration exists and belongs to session A'
);
select is(
  (
    select count(*) from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000101'
      and status = 'waitlisted'
      and user_id = '00000000-0000-0000-0000-000000000033'
      and waitlist_position = 1
  ),
  1::bigint,
  'exactly one waitlisted registration exists and belongs to session B'
);
select is(
  (
    select count(*) from public.audit_log
    where entity_type = 'event_registration'
      and action = 'event_registration.created'
      and entity_id in (
        select id from public.event_registrations
        where event_id = '40000000-0000-0000-0000-000000000101'
      )
  ),
  2::bigint,
  'both racing registrations write safe audit records'
);

select * from finish();

-- Remove the committed fixtures and their audit trail.
begin;
create temp table race_cleanup_entity_ids as
select id from public.event_registrations
where event_id = '40000000-0000-0000-0000-000000000101'
union all
select id from public.memberships
where user_id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
)
union all
select '40000000-0000-0000-0000-000000000101'::uuid;

delete from public.event_registrations
where event_id = '40000000-0000-0000-0000-000000000101';
delete from public.event_private_details
where event_id = '40000000-0000-0000-0000-000000000101';
delete from public.event_hosts
where event_id = '40000000-0000-0000-0000-000000000101';
delete from public.events
where id = '40000000-0000-0000-0000-000000000101';
delete from public.user_roles
where user_id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
);
delete from public.membership_admin
where membership_id in (
  select id from public.memberships
  where user_id in (
    '00000000-0000-0000-0000-000000000031',
    '00000000-0000-0000-0000-000000000032',
    '00000000-0000-0000-0000-000000000033'
  )
);
delete from public.memberships
where user_id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
);
delete from auth.users
where id in (
  '00000000-0000-0000-0000-000000000031',
  '00000000-0000-0000-0000-000000000032',
  '00000000-0000-0000-0000-000000000033'
);
delete from public.audit_log
where entity_id in (select id from race_cleanup_entity_ids)
  or actor_id in (
    '00000000-0000-0000-0000-000000000031',
    '00000000-0000-0000-0000-000000000032',
    '00000000-0000-0000-0000-000000000033'
  );
drop table race_cleanup_entity_ids;
commit;
