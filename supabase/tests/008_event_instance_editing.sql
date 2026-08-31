begin;

select plan(30);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000061', 'instance-owner@example.test'),
  ('00000000-0000-0000-0000-000000000062', 'instance-executive@example.test'),
  ('00000000-0000-0000-0000-000000000063', 'instance-other-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000064', 'instance-expired-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000065', 'instance-pending@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '00000000-0000-0000-0000-000000000061',
    '2020-01-01',
    '2099-12-31',
    'active',
    '2020-01-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000062',
    '2020-01-01',
    '2099-12-31',
    'active',
    '2020-01-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000063',
    '2020-01-01',
    '2099-12-31',
    'active',
    '2020-01-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000064',
    '2020-01-01',
    '2025-12-31',
    'expired',
    '2020-01-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000065',
    null,
    null,
    'pending',
    null
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000062'
from public.memberships
where user_id in (
  '00000000-0000-0000-0000-000000000061',
  '00000000-0000-0000-0000-000000000062',
  '00000000-0000-0000-0000-000000000063',
  '00000000-0000-0000-0000-000000000064'
);

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '00000000-0000-0000-0000-000000000061',
    'organizer',
    '00000000-0000-0000-0000-000000000062'
  ),
  (
    '00000000-0000-0000-0000-000000000062',
    'executive',
    '00000000-0000-0000-0000-000000000061'
  ),
  (
    '00000000-0000-0000-0000-000000000063',
    'organizer',
    '00000000-0000-0000-0000-000000000062'
  ),
  (
    '00000000-0000-0000-0000-000000000064',
    'organizer',
    '00000000-0000-0000-0000-000000000062'
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
    '80000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000061',
    'Owner Series',
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
    '80000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000063',
    'Other Organizer Series',
    'hike',
    'America/Edmonton',
    'daily',
    1,
    '{}'::smallint[],
    '2026-10-31',
    '2026-11-02',
    3
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
    '80000000-0000-0000-0000-000000000101',
    '80000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000061',
    'Original Instance',
    'Original public summary.',
    '2026-10-31 16:00:00+00',
    '2026-10-31 17:00:00+00',
    'America/Edmonton',
    'hike',
    'public',
    'published'
  ),
  (
    '80000000-0000-0000-0000-000000000102',
    '80000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000063',
    'Other Organizer Instance',
    'Other organizer public summary.',
    '2026-10-31 16:00:00+00',
    '2026-10-31 17:00:00+00',
    'America/Edmonton',
    'hike',
    'public',
    'published'
  );

insert into public.event_private_details (
  event_id,
  member_description,
  exact_location,
  waiver_required
)
values
  (
    '80000000-0000-0000-0000-000000000101',
    'Original private description.',
    'Original private location.',
    false
  ),
  (
    '80000000-0000-0000-0000-000000000102',
    'Other organizer private description.',
    'Other organizer private location.',
    false
  );

insert into public.event_hosts (event_id, user_id, assigned_by)
values
  (
    '80000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000061',
    '00000000-0000-0000-0000-000000000062'
  ),
  (
    '80000000-0000-0000-0000-000000000102',
    '00000000-0000-0000-0000-000000000063',
    '00000000-0000-0000-0000-000000000062'
  );

select is(
  has_function_privilege(
    'anon',
    'public.update_event_instance(uuid, text, text, text, text, text, public.event_activity_type, text, public.event_visibility, text, text, boolean)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the event instance update function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.update_event_instance(uuid, text, text, text, text, text, public.event_activity_type, text, public.event_visibility, text, text, boolean)',
    'execute'
  ),
  true,
  'authenticated users can execute the event instance update function'
);

set local role anon;
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      'Anonymous edit',
      'Anonymous summary',
      '2026-11-01T10:00',
      '2026-11-01T11:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Anonymous details',
      null,
      false
    )$$,
  '42501',
  null,
  'anonymous users cannot edit event instances'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000065';
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      'Pending edit',
      'Pending summary',
      '2026-11-01T10:00',
      '2026-11-01T11:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Pending details',
      null,
      false
    )$$,
  '42501',
  'event unavailable',
  'pending users cannot edit event instances'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000064';
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      'Expired edit',
      'Expired summary',
      '2026-11-01T10:00',
      '2026-11-01T11:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Expired details',
      null,
      false
    )$$,
  '42501',
  'event unavailable',
  'expired organizers cannot edit event instances'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000063';
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      'Cross organizer edit',
      'Cross organizer summary',
      '2026-11-01T10:00',
      '2026-11-01T11:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Cross organizer details',
      null,
      false
    )$$,
  '42501',
  'event unavailable',
  'organizers cannot edit an instance they do not host'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000061';
select is(
  (select title
   from public.update_event_instance(
     '80000000-0000-0000-0000-000000000101',
     'Edited Instance',
     'Edited public summary.',
     '2026-11-01T10:00',
     '2026-11-01T12:30',
     'America/Edmonton',
     'scramble',
     'moderate',
     'members_only',
     'Edited member description.',
     'Edited private location.',
     true
   )),
  'Edited Instance',
  'the hosted organizer can update one event instance'
);
select is(
  (select public_summary from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  'Edited public summary.',
  'the instance public summary is updated'
);
select is(
  (select activity_type::text || '|' || coalesce(difficulty, '') || '|' || visibility::text
   from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  'scramble|moderate|members_only',
  'the instance activity, difficulty, and visibility are updated'
);
select is(
  (select starts_at from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  '2026-11-01 17:00:00+00'::timestamptz,
  'local instance start time uses the post-DST timezone offset'
);
select is(
  (select ends_at - starts_at from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  interval '2 hours 30 minutes',
  'the instance stores the submitted local end time and duration'
);
select is(
  (select member_description from public.event_private_details
   where event_id = '80000000-0000-0000-0000-000000000101'),
  'Edited member description.',
  'the member description is updated in the same operation'
);
select is(
  (select exact_location from public.event_private_details
   where event_id = '80000000-0000-0000-0000-000000000101'),
  'Edited private location.',
  'the exact location is updated in the same operation'
);
select is(
  (select waiver_required from public.event_private_details
   where event_id = '80000000-0000-0000-0000-000000000101'),
  true,
  'the per-instance waiver flag is updated with private details'
);
select is(
  (select series_id from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  '80000000-0000-0000-0000-000000000001'::uuid,
  'per-instance editing preserves the series link'
);
select is(
  (select created_by from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  '00000000-0000-0000-0000-000000000061'::uuid,
  'per-instance editing preserves the original creator'
);
select is(
  (select status::text from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  'published',
  'per-instance editing does not change publication status'
);

select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      repeat('x', 161),
      'Valid summary',
      '2026-11-01T10:00',
      '2026-11-01T11:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Valid details',
      null,
      false
    )$$,
  '22023',
  'event input is invalid',
  'oversized instance titles are rejected'
);
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      'Invalid time edit',
      'Valid summary',
      '2026-11-01T13:00',
      '2026-11-01T12:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Valid details',
      null,
      false
    )$$,
  '22023',
  'event input is invalid',
  'an instance ending before it starts is rejected'
);
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      'Invalid timezone edit',
      'Valid summary',
      '2026-11-01T10:00',
      '2026-11-01T11:00',
      'Not/An-IANA-Timezone',
      'hike',
      null,
      'public',
      'Valid details',
      null,
      false
    )$$,
  '22023',
  'event input is invalid',
  'invalid instance timezones are rejected'
);
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-000000000101',
      'Null time edit',
      'Valid summary',
      null,
      '2026-11-01T11:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Valid details',
      null,
      false
    )$$,
  '22023',
  'event input is invalid',
  'null instance timestamps are rejected'
);
select is(
  (select title from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  'Edited Instance',
  'failed instance validation leaves the event unchanged'
);

select throws_ok(
  $$update public.events
    set series_id = null
    where id = '80000000-0000-0000-0000-000000000101'$$,
  '42501',
  'event series link cannot be changed',
  'direct event updates cannot detach a recurring instance'
);
select is(
  (select series_id from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  '80000000-0000-0000-0000-000000000001'::uuid,
  'a denied series-link update leaves the instance linked'
);
select throws_ok(
  $$select * from public.update_event_instance(
      '80000000-0000-0000-0000-0000000000aa',
      'Unknown edit',
      'Unknown summary',
      '2026-11-01T10:00',
      '2026-11-01T11:00',
      'America/Edmonton',
      'hike',
      null,
      'public',
      'Unknown details',
      null,
      false
    )$$,
  '42501',
  'event unavailable',
  'unknown event ids return a generic unavailable error'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000062';
select is(
  (select count(*) from public.audit_log
   where entity_type = 'event'
     and entity_id = '80000000-0000-0000-0000-000000000101'
     and action = 'event.updated'),
  1::bigint,
  'instance edits create one event update audit record'
);
select is(
  (select actor_id from public.audit_log
   where entity_type = 'event'
     and entity_id = '80000000-0000-0000-0000-000000000101'
     and action = 'event.updated'),
  '00000000-0000-0000-0000-000000000061'::uuid,
  'event update audits retain the hosting organizer actor'
);
select is(
  (select count(*) from public.audit_log
   where entity_type = 'event_private_details'
     and entity_id = '80000000-0000-0000-0000-000000000101'
     and action = 'event_private_details.updated'),
  1::bigint,
  'instance edits create one private-detail update audit record'
);

select is(
  (select title
   from public.update_event_instance(
     '80000000-0000-0000-0000-000000000101',
     'Executive Edited Instance',
     'Executive public summary.',
     '2026-11-01T10:00',
     '2026-11-01T11:00',
     'America/Edmonton',
     'hike',
     null,
     'public',
     'Executive member description.',
     'Executive private location.',
     false
   )),
  'Executive Edited Instance',
  'executives can edit an organizer-owned event instance'
);
select is(
  (select series_id from public.event_management
   where id = '80000000-0000-0000-0000-000000000101'),
  '80000000-0000-0000-0000-000000000001'::uuid,
  'executive instance edits preserve the series link'
);

select * from finish();

rollback;