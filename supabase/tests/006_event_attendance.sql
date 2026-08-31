begin;

select plan(35);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000041', 'attendance-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000042', 'attendance-executive@example.test'),
  ('00000000-0000-0000-0000-000000000043', 'attendance-member@example.test'),
  ('00000000-0000-0000-0000-000000000044', 'attendance-pending@example.test'),
  ('00000000-0000-0000-0000-000000000045', 'attendance-expired@example.test'),
  ('00000000-0000-0000-0000-000000000046', 'attendance-other-organizer@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '00000000-0000-0000-0000-000000000041',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000042',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000043',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000044',
    null,
    null,
    'pending',
    null
  ),
  (
    '00000000-0000-0000-0000-000000000045',
    '2020-09-01',
    '2025-08-31',
    'expired',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000046',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  );

insert into public.profiles (id, first_name, last_name_initial)
values (
  '00000000-0000-0000-0000-000000000043',
  'Avery',
  'M'
);

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000042'
from public.memberships
where status in ('active', 'expired');

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '00000000-0000-0000-0000-000000000041',
    'organizer',
    '00000000-0000-0000-0000-000000000042'
  ),
  (
    '00000000-0000-0000-0000-000000000042',
    'executive',
    '00000000-0000-0000-0000-000000000041'
  ),
  (
    '00000000-0000-0000-0000-000000000045',
    'organizer',
    '00000000-0000-0000-0000-000000000042'
  ),
  (
    '00000000-0000-0000-0000-000000000046',
    'organizer',
    '00000000-0000-0000-0000-000000000042'
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
  status
)
values
  (
    '60000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000041',
    'Attendance Published Event',
    'A published event used for attendance checks.',
    '2026-10-01 14:00:00+00',
    '2026-10-01 16:00:00+00',
    'America/Edmonton',
    'hike',
    'members_only',
    'published'
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000041',
    'Attendance Completed Event',
    'A completed event used for attendance checks.',
    '2026-10-02 14:00:00+00',
    '2026-10-02 16:00:00+00',
    'America/Edmonton',
    'hike',
    'members_only',
    'completed'
  ),
  (
    '60000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000041',
    'Attendance Cancelled Event',
    'A cancelled event used for attendance checks.',
    '2026-10-03 14:00:00+00',
    '2026-10-03 16:00:00+00',
    'America/Edmonton',
    'social',
    'members_only',
    'cancelled'
  );

insert into public.event_private_details (event_id, member_description)
values
  ('60000000-0000-0000-0000-000000000001', 'Private published attendance details.'),
  ('60000000-0000-0000-0000-000000000002', 'Private completed attendance details.'),
  ('60000000-0000-0000-0000-000000000003', 'Private cancelled attendance details.');

insert into public.event_hosts (event_id, user_id, assigned_by)
values
  (
    '60000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000041',
    '00000000-0000-0000-0000-000000000042'
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000041',
    '00000000-0000-0000-0000-000000000042'
  ),
  (
    '60000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000041',
    '00000000-0000-0000-0000-000000000042'
  );

insert into public.event_registrations (
  event_id,
  user_id,
  status,
  waitlist_position,
  queued_at,
  cancelled_at
)
values
  (
    '60000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000043',
    'confirmed',
    null,
    null,
    null
  ),
  (
    '60000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000044',
    'waitlisted',
    1,
    '2026-09-01 00:00:00+00',
    null
  ),
  (
    '60000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000045',
    'confirmed',
    null,
    null,
    null
  ),
  (
    '60000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000046',
    'cancelled',
    null,
    null,
    '2026-09-01 00:00:00+00'
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000043',
    'confirmed',
    null,
    null,
    null
  ),
  (
    '60000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000043',
    'confirmed',
    null,
    null,
    null
  );

select is(
  has_function_privilege(
    'anon',
    'public.record_event_attendance(uuid, uuid, public.event_registration_status)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the attendance function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.record_event_attendance(uuid, uuid, public.event_registration_status)',
    'execute'
  ),
  true,
  'authenticated users can execute the attendance function'
);
select is(
  has_function_privilege(
    'anon',
    'public.list_event_attendance(uuid)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the attendance roster function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.list_event_attendance(uuid)',
    'execute'
  ),
  true,
  'authenticated users can execute the attendance roster function'
);

set local role anon;
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000043',
      'attended'
    )$$,
  '42501',
  null,
  'anonymous users cannot record attendance'
);
select throws_ok(
  $$select * from public.list_event_attendance(
      '60000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  null,
  'anonymous users cannot read the attendance roster'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000044';
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000043',
      'attended'
    )$$,
  '42501',
  null,
  'pending users cannot record attendance'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000045';
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000043',
      'attended'
    )$$,
  '42501',
  null,
  'expired organizers cannot record attendance'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000043';
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000043',
      'attended'
    )$$,
  '42501',
  null,
  'active members cannot record attendance'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000046';
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000043',
      'attended'
    )$$,
  '42501',
  null,
  'organizers cannot record attendance for an event they do not host'
);
select is(
  (select count(*)
   from public.list_event_attendance('60000000-0000-0000-0000-000000000001')),
  0::bigint,
  'organizers cannot read attendance for an event they do not host'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000041';
select is(
  (select count(*)
   from public.list_event_attendance('60000000-0000-0000-0000-000000000001')),
  4::bigint,
  'the event host can read the event attendance roster'
);
select is(
  (select first_name
   from public.list_event_attendance('60000000-0000-0000-0000-000000000001')
   where first_name is not null
   limit 1),
  'Avery',
  'the attendance roster exposes only the approved member name fields'
);
select is(
  (select count(*) from public.profiles),
  0::bigint,
  'organizers cannot read profiles directly'
);
select is(
  (select registration_status::text
   from public.record_event_attendance(
     '60000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000043',
     'attended'
   )),
  'attended',
  'the event host can mark a confirmed member attended'
);
select is(
  (select attended_at is not null
   from public.event_registrations
   where event_id = '60000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-000000000043'),
  true,
  'attendance records a timestamp'
);
select is(
  (select registration_status::text
   from public.record_event_attendance(
     '60000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000043',
     'no_show'
   )),
  'no_show',
  'the event host can correct attendance to no show'
);
select is(
  (select status::text
   from public.event_registrations
   where event_id = '60000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-000000000043'),
  'no_show',
  'the attendance correction persists the no show state'
);
select is(
  (select attended_at is not null
   from public.event_registrations
   where event_id = '60000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-000000000043'),
  true,
  'a no show correction retains an attendance timestamp'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000042';
select is(
  (select registration_status::text
   from public.record_event_attendance(
     '60000000-0000-0000-0000-000000000002',
     '00000000-0000-0000-0000-000000000043',
     'no_show'
   )),
  'no_show',
  'an executive can record attendance on a completed event'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000041';
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000003',
      '00000000-0000-0000-0000-000000000043',
      'attended'
    )$$,
  'P0001',
  null,
  'cancelled events reject attendance recording'
);
select is(
  (select status::text
   from public.event_registrations
   where event_id = '60000000-0000-0000-0000-000000000003'
     and user_id = '00000000-0000-0000-0000-000000000043'),
  'confirmed',
  'a cancelled event attendance attempt leaves the registration unchanged'
);
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000044',
      'attended'
    )$$,
  'P0001',
  null,
  'waitlisted members cannot be marked attended'
);
select is(
  (select status::text
   from public.event_registrations
   where event_id = '60000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-000000000044'),
  'waitlisted',
  'a waitlisted attendance attempt leaves the status unchanged'
);
select is(
  (select waitlist_position
   from public.event_registrations
   where event_id = '60000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-000000000044'),
  1,
  'a waitlisted attendance attempt leaves the position unchanged'
);
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000046',
      'attended'
    )$$,
  'P0001',
  null,
  'cancelled registrations cannot be marked attended'
);
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-0000000000aa',
      '00000000-0000-0000-0000-000000000043',
      'attended'
    )$$,
  '42501',
  'event attendance unavailable',
  'unknown event ids return a generic attendance error'
);
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000043',
      'confirmed'
    )$$,
  '22023',
  'attendance status is invalid',
  'confirmed is not an attendance status'
);
select throws_ok(
  $$select * from public.record_event_attendance(
      '60000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000043',
      null::public.event_registration_status
    )$$,
  '22023',
  'attendance status is invalid',
  'a null attendance status is rejected'
);

select is(
  (select registration_status::text
   from public.record_event_attendance(
     '60000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000045',
     'no_show'
   )),
  'no_show',
  'a host can record attendance for an existing historical registration'
);
select throws_ok(
  $$update public.event_registrations
    set status = 'attended'
    where event_id = '60000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000043'$$,
  '42501',
  null,
  'event hosts cannot update attendance directly'
);
select is(
  (select status::text
   from public.event_registrations
   where event_id = '60000000-0000-0000-0000-000000000001'
     and user_id = '00000000-0000-0000-0000-000000000043'),
  'no_show',
  'a denied direct attendance update leaves the registration unchanged'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000042';
select is(
  (select count(*)
   from public.audit_log
   where action = 'event_registration.attendance_recorded'
     and entity_type = 'event_registration'),
  4::bigint,
  'attendance transitions create one audit record each'
);
select is(
  (select count(*)
   from public.audit_log
   where action = 'event_registration.attendance_recorded'
     and actor_id = '00000000-0000-0000-0000-000000000041'),
  3::bigint,
  'host attendance audits retain the host actor'
);
select is(
  (select count(*)
   from public.audit_log
   where action = 'event_registration.attendance_recorded'
     and actor_id = '00000000-0000-0000-0000-000000000042'),
  1::bigint,
  'executive attendance audits retain the executive actor'
);

select * from finish();

rollback;