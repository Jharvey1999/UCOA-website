begin;

select plan(73);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000001', 'pending-events@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'expired-events@example.test'),
  ('00000000-0000-0000-0000-000000000003', 'member-events@example.test'),
  ('00000000-0000-0000-0000-000000000004', 'organizer-events@example.test'),
  ('00000000-0000-0000-0000-000000000005', 'executive-events@example.test'),
  ('00000000-0000-0000-0000-000000000006', 'other-organizer-events@example.test'),
  ('00000000-0000-0000-0000-000000000007', 'suspended-organizer-events@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '00000000-0000-0000-0000-000000000001',
    null,
    null,
    'pending',
    null
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    '2020-09-01',
    '2025-08-31',
    'expired',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000004',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000006',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000007',
    '2020-09-01',
    '2099-08-31',
    'suspended',
    '2020-09-01 00:00:00+00'
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000005'
from public.memberships
where status in ('active', 'expired');

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '00000000-0000-0000-0000-000000000003',
    'member',
    '00000000-0000-0000-0000-000000000005'
  ),
  (
    '00000000-0000-0000-0000-000000000004',
    'organizer',
    '00000000-0000-0000-0000-000000000005'
  ),
  (
    '00000000-0000-0000-0000-000000000005',
    'executive',
    '00000000-0000-0000-0000-000000000004'
  ),
  (
    '00000000-0000-0000-0000-000000000006',
    'organizer',
    '00000000-0000-0000-0000-000000000005'
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'organizer',
    '00000000-0000-0000-0000-000000000005'
  ),
  (
    '00000000-0000-0000-0000-000000000007',
    'organizer',
    '00000000-0000-0000-0000-000000000005'
  );

insert into public.event_series (
  id,
  created_by,
  title,
  activity_type,
  timezone_name,
  recurrence_frequency,
  recurrence_weekdays,
  starts_on,
  ends_on
)
values (
  '10000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000004',
  'Weekly Climbing',
  'climbing',
  'America/Edmonton',
  'weekly',
  array[2, 4]::smallint[],
  '2026-09-01',
  '2026-12-15'
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
  difficulty,
  visibility,
  status
)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000004',
    'Public Climbing Session',
    'A public-safe climbing session summary.',
    '2026-09-10 01:00:00+00',
    '2026-09-10 03:00:00+00',
    'America/Edmonton',
    'climbing',
    'beginner',
    'public',
    'published'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    null,
    '00000000-0000-0000-0000-000000000004',
    'Private Mountain Trip',
    'A public-safe trip summary for members.',
    '2026-10-10 14:00:00+00',
    '2026-10-12 20:00:00+00',
    'America/Edmonton',
    'camping',
    'advanced',
    'members_only',
    'published'
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    null,
    '00000000-0000-0000-0000-000000000004',
    'Organizer Draft',
    'Draft event summary.',
    '2026-11-10 15:00:00+00',
    '2026-11-10 17:00:00+00',
    'America/Edmonton',
    'hike',
    'moderate',
    'public',
    'draft'
  ),
  (
    '20000000-0000-0000-0000-000000000004',
    null,
    '00000000-0000-0000-0000-000000000005',
    'Executive Draft',
    'Executive-only draft summary.',
    '2026-11-11 15:00:00+00',
    '2026-11-11 17:00:00+00',
    'America/Edmonton',
    'social',
    null,
    'members_only',
    'draft'
  ),
  (
    '20000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000006',
    'Other Organizer Draft',
    'Another organizer draft summary.',
    '2026-11-12 15:00:00+00',
    '2026-11-12 17:00:00+00',
    'America/Edmonton',
    'hike',
    'moderate',
    'public',
    'draft'
  );

insert into public.event_private_details (event_id, member_description, exact_location, waiver_required)
values
  (
    '20000000-0000-0000-0000-000000000001',
    'Member details for the climbing session.',
    'Private climbing gym location.',
    false
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'Member details for the mountain trip.',
    'Private trailhead location.',
    true
  );

insert into public.event_hosts (event_id, user_id, assigned_by)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000005'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000005'
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000005'
  ),
  (
    '20000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000005'
  );

set local role anon;
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000001'),
  1::bigint,
  'anonymous users can read a public published event'
);
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000002'),
  0::bigint,
  'anonymous users cannot read a members-only event'
);
select throws_ok(
  $$select count(*) from public.event_private_details$$,
  '42501',
  null,
  'anonymous users cannot read private event details'
);
select throws_ok(
  $$select count(*) from public.event_series$$,
  '42501',
  null,
  'anonymous users cannot read event series'
);
select throws_ok(
  $$select count(*) from public.event_hosts$$,
  '42501',
  null,
  'anonymous users cannot read event hosts'
);
select throws_ok(
  $$select count(*) from public.event_management$$,
  '42501',
  null,
  'anonymous users cannot read the event management projection'
);
select throws_ok(
  $$insert into public.events (created_by, title, public_summary, starts_at, ends_at, activity_type)
    values ('00000000-0000-0000-0000-000000000004', 'Blocked', 'Blocked', now(), now() + interval '1 hour', 'hike')$$,
  '42501',
  null,
  'anonymous users cannot create events'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000001';
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000001'),
  1::bigint,
  'pending users can read public event summaries'
);
select throws_ok(
  $$select created_by from public.events where id = '20000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'pending users cannot select internal event columns'
);
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000002'),
  0::bigint,
  'pending users cannot read members-only event rows'
);
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000003'),
  0::bigint,
  'pending users cannot read draft events'
);
select is(
  (select count(*) from public.event_private_details),
  0::bigint,
  'pending users cannot read private event details'
);
select is(
  (select count(event_id) from public.event_hosts),
  0::bigint,
  'pending users cannot read event hosts'
);
select throws_ok(
  $$insert into public.events (created_by, title, public_summary, starts_at, ends_at, activity_type)
    values ('00000000-0000-0000-0000-000000000001', 'Blocked', 'Blocked', now(), now() + interval '1 hour', 'hike')$$,
  '42501',
  null,
  'pending users cannot create events'
);
select is(
  (select count(*) from public.event_series),
  0::bigint,
  'pending users cannot read organizer event series'
);
select is(
  (select count(*) from public.event_management),
  0::bigint,
  'pending users cannot read the event management projection'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000003';
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000002'),
  1::bigint,
  'active members can read members-only event rows'
);
select is(
  (select count(*) from public.event_private_details where event_id = '20000000-0000-0000-0000-000000000002'),
  1::bigint,
  'active members can read private details for published events'
);
select is(
  (select count(event_id) from public.event_hosts where event_id = '20000000-0000-0000-0000-000000000002'),
  1::bigint,
  'active members can read the public event host identity'
);
select throws_ok(
  $$select assigned_by from public.event_hosts where event_id = '20000000-0000-0000-0000-000000000002'$$,
  '42501',
  null,
  'active members cannot read host assignment metadata'
);
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000003'),
  0::bigint,
  'active members cannot read draft event rows'
);
select is(
  (select count(*) from public.event_management),
  0::bigint,
  'active members cannot read the event management projection'
);
select lives_ok(
  $$update public.events set title = 'Blocked Member Edit' where id = '20000000-0000-0000-0000-000000000001'$$,
  'active members cannot update organizer events'
);
set local role postgres;
select is(
  (select title from public.events where id = '20000000-0000-0000-0000-000000000001'),
  'Public Climbing Session',
  'member update leaves organizer event unchanged'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from public.event_private_details where event_id = '20000000-0000-0000-0000-000000000002'),
  0::bigint,
  'expired organizers cannot read private event details'
);
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000003'),
  0::bigint,
  'expired organizers cannot read draft events'
);
select throws_ok(
  $$insert into public.events (created_by, title, public_summary, starts_at, ends_at, activity_type, status)
    values ('00000000-0000-0000-0000-000000000002', 'Expired Draft', 'Expired draft summary', now(), now() + interval '1 hour', 'hike', 'draft')$$,
  '42501',
  null,
  'expired organizers cannot create events'
);
select throws_ok(
  $$insert into public.event_hosts (event_id, user_id, assigned_by)
    values ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002')$$,
  '42501',
  null,
  'expired organizers cannot assign event hosts'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000007';
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000002'),
  0::bigint,
  'suspended organizers cannot read members-only event rows'
);
select is(
  (select count(*) from public.event_private_details where event_id = '20000000-0000-0000-0000-000000000002'),
  0::bigint,
  'suspended organizers cannot read private event details'
);
select is(
  (select count(*) from public.event_management),
  0::bigint,
  'suspended organizers cannot read the event management projection'
);
select throws_ok(
  $$insert into public.events (created_by, title, public_summary, starts_at, ends_at, activity_type, status)
    values ('00000000-0000-0000-0000-000000000007', 'Suspended Draft', 'Suspended draft summary', now(), now() + interval '1 hour', 'hike', 'draft')$$,
  '42501',
  null,
  'suspended organizers cannot create events'
);
select throws_ok(
  $$insert into public.event_hosts (event_id, user_id, assigned_by)
    values ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000007')$$,
  '42501',
  null,
  'suspended organizers cannot assign event hosts'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000004';
select is(
  (select count(*) from public.event_series where id = '10000000-0000-0000-0000-000000000001'),
  1::bigint,
  'organizers can read their own event series'
);
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000003'),
  1::bigint,
  'organizers can read their hosted draft events'
);
select lives_ok(
  $$insert into public.events (id, created_by, title, public_summary, starts_at, ends_at, activity_type, status)
    values ('20000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000004', 'New Draft', 'New draft summary', now(), now() + interval '1 hour', 'hike', 'draft')$$,
  'active organizers can create draft events'
);
select is(
  (select count(*) from public.event_management),
  3::bigint,
  'organizers cannot manage an unhosted draft they created'
);
select is(
  (select private.can_current_user_bootstrap_event_host('20000000-0000-0000-0000-000000000005')),
  true,
  'organizers can pass the self-host bootstrap check for their draft'
);
select throws_ok(
  $$insert into public.event_private_details (event_id, member_description)
    values ('20000000-0000-0000-0000-000000000005', 'Blocked private details')$$,
  '42501',
  null,
  'organizers cannot add private details before hosting an event'
);
select lives_ok(
  $$insert into public.event_hosts (event_id, user_id, assigned_by)
    values ('20000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004')$$,
  'organizers can assign themselves as a draft event host'
);
select lives_ok(
  $$insert into public.event_private_details (event_id, member_description, exact_location)
    values ('20000000-0000-0000-0000-000000000005', 'New private details', 'New private location')$$,
  'organizers can add private details to hosted drafts'
);
select lives_ok(
  $$select * from public.set_event_status('20000000-0000-0000-0000-000000000005', 'published')$$,
  'organizers can publish hosted events with private details'
);
select is(
  (select count(*) from public.event_management),
  4::bigint,
  'organizers can read their newly published event through the private projection'
);
select is(
  (select count(*) from public.event_management where id = '20000000-0000-0000-0000-000000000006'),
  0::bigint,
  'organizers cannot read another organizer event through the management projection'
);
select throws_ok(
  $$delete from public.event_series where id = '10000000-0000-0000-0000-000000000001'$$,
  '23503',
  null,
  'a series with linked events cannot be deleted'
);
select is(
  (select count(*) from public.event_series where id = '10000000-0000-0000-0000-000000000001'),
  1::bigint,
  'failed series deletion leaves the series and event links intact'
);
set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000006';
select is(
  (select count(*) from public.event_management where id = '20000000-0000-0000-0000-000000000006'),
  1::bigint,
  'the other organizer can read their hosted draft through the management projection'
);
select is(
  (select count(*) from public.event_management where id = '20000000-0000-0000-0000-000000000005'),
  0::bigint,
  'the other organizer cannot read the first organizer event through the management projection'
);
select is(
  (select count(*) from public.event_series where id = '10000000-0000-0000-0000-000000000001'),
  0::bigint,
  'the other organizer cannot read the first organizer event series'
);
select is(
  (select private.can_current_user_manage_event('20000000-0000-0000-0000-000000000005')),
  false,
  'the event management helper denies a cross-user event'
);
select throws_ok(
  $$insert into public.events (created_by, series_id, title, public_summary, starts_at, ends_at, activity_type, status)
    values ('00000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000001', 'Wrong Series', 'Wrong series summary', now(), now() + interval '1 hour', 'hike', 'draft')$$,
  '42501',
  null,
  'organizers cannot attach an event to another organizer series'
);
set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000004';
select throws_ok(
  $$insert into public.event_hosts (event_id, user_id, assigned_by)
    values ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004')$$,
  '42501',
  null,
  'organizers cannot assign another user as a host'
);
select is(
  (select count(id) from public.events where id = '20000000-0000-0000-0000-000000000004'),
  0::bigint,
  'organizers cannot read an unhosted executive draft'
);
select lives_ok(
  $$update public.events set title = 'Blocked Unhosted Edit' where id = '20000000-0000-0000-0000-000000000004'$$,
  'organizers cannot update an unhosted executive event'
);
set local role postgres;
select is(
  (select title from public.events where id = '20000000-0000-0000-0000-000000000004'),
  'Executive Draft',
  'unhosted executive event remains unchanged'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000005';
select is(
  (select count(id) from public.events),
  6::bigint,
  'executives can read all event rows'
);
select is(
  (select count(*) from public.event_private_details),
  3::bigint,
  'executives can read all private event details'
);
select is(
  (select count(*) from public.event_series),
  1::bigint,
  'executives can read all event series'
);
set constraints events_publication_check, event_private_details_publication_check immediate;
select throws_ok(
  $$select * from public.set_event_status('20000000-0000-0000-0000-000000000004', 'published')$$,
  'P0001',
  'event cannot be published',
  'events cannot be published without private details'
);
select is(
  (select status from public.events where id = '20000000-0000-0000-0000-000000000004'),
  'draft'::public.event_status,
  'failed publication leaves the event as a draft'
);
select throws_ok(
  $$delete from public.event_private_details where event_id = '20000000-0000-0000-0000-000000000001'$$,
  '23514',
  null,
  'published events cannot lose their private details'
);
select is(
  (select count(*) from public.event_private_details where event_id = '20000000-0000-0000-0000-000000000001'),
  1::bigint,
  'failed private detail deletion leaves the details intact'
);
select throws_ok(
  $$update public.event_series
    set created_by = '00000000-0000-0000-0000-000000000006'
    where id = '10000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'event series ownership cannot be changed'
);
select is(
  (select count(*) from public.audit_log
    where entity_type = 'event_series'
      and entity_id = '10000000-0000-0000-0000-000000000001'
      and action = 'event_series.created'),
  1::bigint,
  'event series creation creates a safe audit record'
);
select is(
  (select metadata->>'actor_type' from public.audit_log
    where entity_type = 'event_series'
      and entity_id = '10000000-0000-0000-0000-000000000001'
      and action = 'event_series.created'),
  'system',
  'system-created event series audits identify their actor type'
);
select lives_ok(
  $$insert into public.event_hosts (event_id, user_id, assigned_by)
    values ('20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000005')$$,
  'executives can assign an eligible organizer as a host'
);
select throws_ok(
  $$insert into public.event_hosts (event_id, user_id, assigned_by)
    values ('20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005')$$,
  '42501',
  null,
  'executives cannot assign an expired organizer as a host'
);
select is(
  (select count(*) from public.audit_log where entity_type = 'event' and entity_id = '20000000-0000-0000-0000-000000000005'),
  2::bigint,
  'event creation and publication create safe audit records'
);
select is(
  (select actor_id from public.audit_log
    where entity_type = 'event'
      and entity_id = '20000000-0000-0000-0000-000000000005'
      and action = 'event.created'),
  '00000000-0000-0000-0000-000000000004'::uuid,
  'event audits retain the authenticated organizer actor'
);
select is(
  (select metadata->>'actor_type' from public.audit_log
    where entity_type = 'event'
      and entity_id = '20000000-0000-0000-0000-000000000005'
      and action = 'event.created'),
  'user',
  'event audits identify authenticated user actors'
);
select is(
  (select count(*) from public.audit_log
    where entity_type = 'event_host'
      and entity_id = '20000000-0000-0000-0000-000000000005'),
  1::bigint,
  'host assignment creates a safe audit record'
);
select is(
  (select count(*) from public.audit_log where entity_type = 'event_private_details' and entity_id = '20000000-0000-0000-0000-000000000005'),
  1::bigint,
  'private detail creation creates a safe audit record'
);
select throws_ok(
  $$insert into public.event_series (
      created_by,
      title,
      activity_type,
      timezone_name,
      recurrence_frequency,
      recurrence_weekdays,
      starts_on,
      ends_on
    ) values (
      '00000000-0000-0000-0000-000000000005',
      'Invalid timezone',
      'hike',
      'Not/An-IANA-Timezone',
      'weekly',
      array[2]::smallint[],
      '2026-09-01',
      '2026-09-02'
    )$$,
  '23514',
  null,
  'invalid event timezones are rejected'
);

select * from finish();

rollback;