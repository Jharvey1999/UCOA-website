begin;

select plan(34);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000051', 'series-owner@example.test'),
  ('00000000-0000-0000-0000-000000000052', 'series-executive@example.test'),
  ('00000000-0000-0000-0000-000000000053', 'series-other-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000054', 'series-expired-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000055', 'series-pending@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '00000000-0000-0000-0000-000000000051',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000052',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000053',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000054',
    '2020-09-01',
    '2025-08-31',
    'expired',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000055',
    null,
    null,
    'pending',
    null
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000052'
from public.memberships
where status in ('active', 'expired');

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '00000000-0000-0000-0000-000000000051',
    'organizer',
    '00000000-0000-0000-0000-000000000052'
  ),
  (
    '00000000-0000-0000-0000-000000000052',
    'executive',
    '00000000-0000-0000-0000-000000000051'
  ),
  (
    '00000000-0000-0000-0000-000000000053',
    'organizer',
    '00000000-0000-0000-0000-000000000052'
  ),
  (
    '00000000-0000-0000-0000-000000000054',
    'organizer',
    '00000000-0000-0000-0000-000000000052'
  );

insert into public.event_series (
  id,
  created_by,
  title,
  activity_type,
  timezone_name,
  recurrence_frequency,
  recurrence_interval,
  recurrence_weekdays,
  starts_on,
  ends_on,
  max_instances
)
values
  (
    '70000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000051',
    'Weekly Series',
    'hike',
    'America/Edmonton',
    'weekly',
    1,
    array[2, 4]::smallint[],
    '2026-09-01',
    '2026-09-10',
    4
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000051',
    'DST Daily Series',
    'hike',
    'America/Edmonton',
    'daily',
    1,
    '{}'::smallint[],
    '2026-10-31',
    '2026-11-02',
    3
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000051',
    'Monthly Series',
    'social',
    'America/Edmonton',
    'monthly',
    2,
    '{}'::smallint[],
    '2027-01-31',
    '2027-05-31',
    3
  ),
  (
    '70000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000051',
    'Empty Series',
    'other',
    'America/Edmonton',
    'daily',
    1,
    '{}'::smallint[],
    '2026-09-01',
    '2026-09-02',
    2
  ),
  (
    '70000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000051',
    'Capped Series',
    'camping',
    'America/Edmonton',
    'daily',
    1,
    '{}'::smallint[],
    '2026-12-15',
    '2026-12-20',
    2
  ),
  (
    '70000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000051',
    'Executive Managed Series',
    'social',
    'America/Edmonton',
    'daily',
    1,
    '{}'::smallint[],
    '2026-12-21',
    '2026-12-22',
    2
  );

insert into public.events (
  id,
  series_id,
  created_by,
  title,
  public_summary,
  starts_at,
  ends_at,
  timezone_name,
  activity_type,
  visibility,
  status
)
values
  (
    '70000000-0000-0000-0000-000000000101',
    '70000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000051',
    'Weekly Template',
    'A recurring weekly event template.',
    '2026-09-03 16:00:00+00',
    '2026-09-03 18:00:00+00',
    'America/Edmonton',
    'hike',
    'public',
    'published'
  ),
  (
    '70000000-0000-0000-0000-000000000102',
    '70000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000051',
    'DST Daily Template',
    'A recurring daily event around the DST transition.',
    '2026-10-31 16:00:00+00',
    '2026-10-31 17:00:00+00',
    'America/Edmonton',
    'hike',
    'public',
    'published'
  ),
  (
    '70000000-0000-0000-0000-000000000103',
    '70000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000051',
    'Monthly Template',
    'A recurring monthly event template.',
    '2027-01-31 17:00:00+00',
    '2027-01-31 19:00:00+00',
    'America/Edmonton',
    'social',
    'public',
    'published'
  ),
  (
    '70000000-0000-0000-0000-000000000105',
    '70000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000051',
    'Capped Template',
    'A bounded recurring event template.',
    '2026-12-15 17:00:00+00',
    '2026-12-15 19:00:00+00',
    'America/Edmonton',
    'camping',
    'public',
    'published'
  ),
  (
    '70000000-0000-0000-0000-000000000106',
    '70000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000051',
    'Executive Template',
    'An executive-managed recurring event template.',
    '2026-12-21 17:00:00+00',
    '2026-12-21 19:00:00+00',
    'America/Edmonton',
    'social',
    'public',
    'published'
  );

insert into public.event_private_details (
  event_id,
  member_description,
  exact_location
)
values
  (
    '70000000-0000-0000-0000-000000000101',
    'Private weekly details.',
    'Weekly private location.'
  ),
  (
    '70000000-0000-0000-0000-000000000102',
    'Private DST details.',
    'DST private location.'
  ),
  (
    '70000000-0000-0000-0000-000000000103',
    'Private monthly details.',
    'Monthly private location.'
  ),
  (
    '70000000-0000-0000-0000-000000000105',
    'Private capped details.',
    'Capped private location.'
  ),
  (
    '70000000-0000-0000-0000-000000000106',
    'Private executive details.',
    'Executive private location.'
  );

insert into public.event_hosts (event_id, user_id, assigned_by)
values
  (
    '70000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000051',
    '00000000-0000-0000-0000-000000000052'
  ),
  (
    '70000000-0000-0000-0000-000000000102',
    '00000000-0000-0000-0000-000000000051',
    '00000000-0000-0000-0000-000000000052'
  ),
  (
    '70000000-0000-0000-0000-000000000103',
    '00000000-0000-0000-0000-000000000051',
    '00000000-0000-0000-0000-000000000052'
  ),
  (
    '70000000-0000-0000-0000-000000000105',
    '00000000-0000-0000-0000-000000000051',
    '00000000-0000-0000-0000-000000000052'
  ),
  (
    '70000000-0000-0000-0000-000000000106',
    '00000000-0000-0000-0000-000000000051',
    '00000000-0000-0000-0000-000000000052'
  );

select is(
  has_function_privilege(
    'anon',
    'public.generate_event_series_instances(uuid)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the series generator'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.generate_event_series_instances(uuid)',
    'execute'
  ),
  true,
  'authenticated users can execute the series generator'
);

set local role anon;
select throws_ok(
  $$select * from public.generate_event_series_instances(
      '70000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  null,
  'anonymous users cannot generate event instances'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000055';
select throws_ok(
  $$select * from public.generate_event_series_instances(
      '70000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  null,
  'pending users cannot generate event instances'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000053';
select throws_ok(
  $$select * from public.generate_event_series_instances(
      '70000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  null,
  'non-owner organizers cannot generate another organizer series'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000054';
select throws_ok(
  $$select * from public.generate_event_series_instances(
      '70000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  null,
  'expired organizers cannot generate event instances'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000051';
select is(
  (select count(*)
   from public.generate_event_series_instances(
     '70000000-0000-0000-0000-000000000001'
   )),
  3::bigint,
  'the owner generates missing weekly instances within the date bound'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'),
  4::bigint,
  'weekly generation includes the existing template and three new instances'
);
select is(
  (select count(*) from public.event_private_details
   where event_id in (
     select id from public.event_management
     where series_id = '70000000-0000-0000-0000-000000000001'
   )),
  4::bigint,
  'weekly generation copies private details to every instance'
);
select is(
  (select count(*) from public.event_hosts
   where event_id in (
     select id from public.event_management
     where series_id = '70000000-0000-0000-0000-000000000001'
   )),
  4::bigint,
  'weekly generation copies the host assignment to every instance'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'
     and status = 'published'),
  4::bigint,
  'generated weekly instances preserve the template publication state'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'
     and title = 'Weekly Template'
     and public_summary = 'A recurring weekly event template.'),
  4::bigint,
  'generated weekly instances preserve template content'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'
     and (starts_at at time zone 'America/Edmonton')::date in (
       '2026-09-01',
       '2026-09-03',
       '2026-09-08',
       '2026-09-10'
     )),
  4::bigint,
  'weekly instances use the configured local weekdays'
);
select is(
  (select count(distinct (starts_at at time zone 'America/Edmonton')::time)
  from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'),
  1::bigint,
  'weekly instances preserve the template local start time'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'
     and ends_at - starts_at = interval '2 hours'),
  4::bigint,
  'weekly instances preserve the template duration'
);
select is(
  (select count(*)
   from public.generate_event_series_instances(
     '70000000-0000-0000-0000-000000000001'
   )),
  0::bigint,
  'repeating weekly generation is idempotent'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'),
  4::bigint,
  'an idempotent generation run creates no extra weekly rows'
);
select is(
  (select count(distinct starts_at) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'),
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000001'),
  'weekly instances have unique start timestamps'
);
select throws_ok(
  $$select * from public.generate_event_series_instances(
      '70000000-0000-0000-0000-000000000004'
    )$$,
  'P0001',
  'event series template unavailable',
  'a series without a usable template returns a generic template error'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000052';
select is(
  (select count(*)
   from public.generate_event_series_instances(
     '70000000-0000-0000-0000-000000000006'
   )),
  1::bigint,
  'an executive can generate instances for an organizer-owned series'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000006'),
  2::bigint,
  'executive generation creates the bounded instance count'
);
select throws_ok(
  $$select * from public.generate_event_series_instances(
      '70000000-0000-0000-0000-0000000000aa'
    )$$,
  'P0001',
  'event series unavailable',
  'unknown series ids return a generic authorization error'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000051';
select is(
  (select count(*)
   from public.generate_event_series_instances(
     '70000000-0000-0000-0000-000000000002'
   )),
  2::bigint,
  'daily generation creates the two missing DST-bound instances'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000002'),
  3::bigint,
  'daily generation respects max_instances'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000002'
     and (starts_at at time zone 'America/Edmonton')::date in (
       '2026-10-31',
       '2026-11-01',
       '2026-11-02'
     )),
  3::bigint,
  'daily generation stays within both recurrence date bounds'
);
select is(
  (select count(distinct (starts_at at time zone 'America/Edmonton')::time)
  from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000002'),
  1::bigint,
  'daily generation preserves local time across the DST transition'
);
select is(
  (select starts_at from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000002'
     and (starts_at at time zone 'America/Edmonton')::date = '2026-11-01'),
  '2026-11-01 17:00:00+00'::timestamptz,
  'daily generation applies the post-DST UTC offset'
);

select is(
  (select count(*)
   from public.generate_event_series_instances(
     '70000000-0000-0000-0000-000000000003'
   )),
  2::bigint,
  'monthly generation creates only valid matching day instances'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000003'),
  3::bigint,
  'monthly generation remains bounded by max_instances'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000003'
     and (starts_at at time zone 'America/Edmonton')::date in (
       '2027-01-31',
       '2027-03-31',
       '2027-05-31'
     )),
  3::bigint,
  'monthly generation preserves the configured day of month'
);

select is(
  (select count(*)
   from public.generate_event_series_instances(
     '70000000-0000-0000-0000-000000000005'
   )),
  1::bigint,
  'a capped series generates only the remaining allowed instance'
);
select is(
  (select count(*) from public.event_management
   where series_id = '70000000-0000-0000-0000-000000000005'),
  2::bigint,
  'a capped series never exceeds max_instances'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000052';
select is(
  (select count(*) from public.audit_log
   where action = 'event.created'
     and entity_id in (
       select id from public.event_management
       where series_id in (
         '70000000-0000-0000-0000-000000000001',
         '70000000-0000-0000-0000-000000000002',
         '70000000-0000-0000-0000-000000000003',
         '70000000-0000-0000-0000-000000000005',
         '70000000-0000-0000-0000-000000000006'
       )
     )),
  14::bigint,
  'all generated and template event rows retain event creation audits'
);
select is(
  (select count(*) from public.audit_log
   where action = 'event.created'
     and actor_id = '00000000-0000-0000-0000-000000000051'
     and entity_id in (
       select id from public.event_management
       where series_id in (
         '70000000-0000-0000-0000-000000000001',
         '70000000-0000-0000-0000-000000000002',
         '70000000-0000-0000-0000-000000000003',
         '70000000-0000-0000-0000-000000000005',
         '70000000-0000-0000-0000-000000000006'
       )
     )),
  8::bigint,
  'organizer generation audits retain the organizer actor'
);

select * from finish();

rollback;