begin;

select plan(37);

insert into auth.users (id, email)
values
  ('90000000-0000-0000-0000-000000000091', 'status-owner@example.test'),
  ('90000000-0000-0000-0000-000000000092', 'status-executive@example.test'),
  ('90000000-0000-0000-0000-000000000093', 'status-other-organizer@example.test'),
  ('90000000-0000-0000-0000-000000000094', 'status-expired-organizer@example.test'),
  ('90000000-0000-0000-0000-000000000095', 'status-pending@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '90000000-0000-0000-0000-000000000091',
    '2020-01-01',
    '2099-12-31',
    'active',
    '2020-01-01 00:00:00+00'
  ),
  (
    '90000000-0000-0000-0000-000000000092',
    '2020-01-01',
    '2099-12-31',
    'active',
    '2020-01-01 00:00:00+00'
  ),
  (
    '90000000-0000-0000-0000-000000000093',
    '2020-01-01',
    '2099-12-31',
    'active',
    '2020-01-01 00:00:00+00'
  ),
  (
    '90000000-0000-0000-0000-000000000094',
    '2020-01-01',
    '2025-12-31',
    'expired',
    '2020-01-01 00:00:00+00'
  ),
  (
    '90000000-0000-0000-0000-000000000095',
    null,
    null,
    'pending',
    null
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '90000000-0000-0000-0000-000000000092'
from public.memberships
where user_id in (
  '90000000-0000-0000-0000-000000000091',
  '90000000-0000-0000-0000-000000000092',
  '90000000-0000-0000-0000-000000000093',
  '90000000-0000-0000-0000-000000000094'
);

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '90000000-0000-0000-0000-000000000091',
    'organizer',
    '90000000-0000-0000-0000-000000000092'
  ),
  (
    '90000000-0000-0000-0000-000000000092',
    'executive',
    '90000000-0000-0000-0000-000000000091'
  ),
  (
    '90000000-0000-0000-0000-000000000093',
    'organizer',
    '90000000-0000-0000-0000-000000000092'
  ),
  (
    '90000000-0000-0000-0000-000000000094',
    'organizer',
    '90000000-0000-0000-0000-000000000092'
  );

insert into public.events (
  id,
  created_by,
  title,
  public_summary,
  starts_at,
  ends_at,
  activity_type,
  visibility,
  status,
  capacity,
  waitlist_enabled
)
values
  (
    '90000000-0000-0000-0000-000000000101',
    '90000000-0000-0000-0000-000000000091',
    'Status Draft',
    'A draft event ready for publication.',
    timezone('utc', now()) + interval '2 days',
    timezone('utc', now()) + interval '2 days 2 hours',
    'hike',
    'public',
    'draft',
    0,
    true
  ),
  (
    '90000000-0000-0000-0000-000000000102',
    '90000000-0000-0000-0000-000000000091',
    'Status Published',
    'A published event ready for cancellation.',
    timezone('utc', now()) + interval '3 days',
    timezone('utc', now()) + interval '3 days 2 hours',
    'climbing',
    'public',
    'published',
    1,
    true
  ),
  (
    '90000000-0000-0000-0000-000000000103',
    '90000000-0000-0000-0000-000000000093',
    'Other Published',
    'Another organizer event for executive moderation.',
    timezone('utc', now()) + interval '4 days',
    timezone('utc', now()) + interval '4 days 2 hours',
    'social',
    'members_only',
    'published',
    0,
    true
  ),
  (
    '90000000-0000-0000-0000-000000000104',
    '90000000-0000-0000-0000-000000000091',
    'Past Published',
    'A completed event fixture.',
    timezone('utc', now()) - interval '3 hours',
    timezone('utc', now()) - interval '1 hour',
    'camping',
    'public',
    'published',
    0,
    true
  ),
  (
    '90000000-0000-0000-0000-000000000105',
    '90000000-0000-0000-0000-000000000093',
    'Executive Moderation Draft',
    'A draft without a host for executive moderation.',
    timezone('utc', now()) + interval '5 days',
    timezone('utc', now()) + interval '5 days 2 hours',
    'course',
    'public',
    'draft',
    0,
    true
  ),
  (
    '90000000-0000-0000-0000-000000000106',
    '90000000-0000-0000-0000-000000000091',
    'Missing Details Draft',
    'A draft that is not ready to publish.',
    timezone('utc', now()) + interval '6 days',
    timezone('utc', now()) + interval '6 days 2 hours',
    'scramble',
    'public',
    'draft',
    0,
    true
  );

insert into public.event_private_details (
  event_id,
  member_description,
  exact_location,
  waiver_required
)
values
  (
    '90000000-0000-0000-0000-000000000101',
    'Private details for the draft.',
    'Draft location.',
    false
  ),
  (
    '90000000-0000-0000-0000-000000000102',
    'Private details for the published event.',
    'Published location.',
    false
  ),
  (
    '90000000-0000-0000-0000-000000000103',
    'Private details for the other event.',
    'Other event location.',
    false
  ),
  (
    '90000000-0000-0000-0000-000000000104',
    'Private details for the past event.',
    'Past event location.',
    false
  ),
  (
    '90000000-0000-0000-0000-000000000105',
    'Private details for executive moderation.',
    'Moderation location.',
    false
  );

insert into public.event_hosts (event_id, user_id, assigned_by)
values
  (
    '90000000-0000-0000-0000-000000000101',
    '90000000-0000-0000-0000-000000000091',
    '90000000-0000-0000-0000-000000000092'
  ),
  (
    '90000000-0000-0000-0000-000000000102',
    '90000000-0000-0000-0000-000000000091',
    '90000000-0000-0000-0000-000000000092'
  ),
  (
    '90000000-0000-0000-0000-000000000103',
    '90000000-0000-0000-0000-000000000093',
    '90000000-0000-0000-0000-000000000092'
  ),
  (
    '90000000-0000-0000-0000-000000000104',
    '90000000-0000-0000-0000-000000000091',
    '90000000-0000-0000-0000-000000000092'
  ),
  (
    '90000000-0000-0000-0000-000000000106',
    '90000000-0000-0000-0000-000000000091',
    '90000000-0000-0000-0000-000000000092'
  );

insert into public.event_registrations (
  event_id,
  user_id,
  status,
  waitlist_position,
  queued_at
)
values
  (
    '90000000-0000-0000-0000-000000000102',
    '90000000-0000-0000-0000-000000000091',
    'confirmed',
    null,
    null
  ),
  (
    '90000000-0000-0000-0000-000000000102',
    '90000000-0000-0000-0000-000000000092',
    'waitlisted',
    1,
    timezone('utc', now())
  );

select is(
  has_function_privilege(
    'anon',
    'public.set_event_status(uuid, public.event_status)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the event status function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.set_event_status(uuid, public.event_status)',
    'execute'
  ),
  true,
  'authenticated users can execute the event status function'
);
select is(
  has_column_privilege('authenticated', 'public.events', 'status', 'UPDATE'),
  false,
  'authenticated users cannot update event status directly'
);
select is(
  has_column_privilege('authenticated', 'public.events', 'title', 'UPDATE'),
  true,
  'authenticated managers retain direct edit-column access'
);

set local role anon;
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000101',
      'published'
    )$$,
  '42501',
  null,
  'anonymous users cannot change event status'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000095';
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000101',
      'published'
    )$$,
  '42501',
  'event unavailable',
  'pending users cannot change event status'
);

set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000094';
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000101',
      'published'
    )$$,
  '42501',
  'event unavailable',
  'expired organizers cannot change event status'
);

set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000093';
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000101',
      'published'
    )$$,
  '42501',
  'event unavailable',
  'organizers cannot moderate another organizer event'
);

set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000091';
select is(
  (select status::text
   from public.set_event_status(
     '90000000-0000-0000-0000-000000000101',
     'published'
   )),
  'published',
  'the hosting organizer can publish a draft event'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000101'),
  'published',
  'publishing changes the event status'
);
select throws_ok(
  $$update public.events
    set status = 'cancelled'
    where id = '90000000-0000-0000-0000-000000000101'$$,
  '42501',
  null,
  'direct event status updates are denied'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000101'),
  'published',
  'a denied direct status update leaves the event unchanged'
);
select is(
  (select status::text
   from public.set_event_status(
     '90000000-0000-0000-0000-000000000101',
     'published'
   )),
  'published',
  'repeating the current status is idempotent'
);
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000101',
      null
    )$$,
  '22023',
  'event status is invalid',
  'null status values are rejected'
);
set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000092';
select is(
  (select count(*)
   from public.audit_log
   where entity_type = 'event'
     and entity_id = '90000000-0000-0000-0000-000000000101'
     and action = 'event.updated'),
  1::bigint,
  'publishing creates one event update audit record'
);
set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000091';
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000106',
      'published'
    )$$,
  'P0001',
  'event cannot be published',
  'events without private details cannot be published'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000106'),
  'draft',
  'failed publication leaves an event in draft status'
);
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000101',
      'completed'
    )$$,
  'P0001',
  'event cannot be completed',
  'future events cannot be marked completed'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000101'),
  'published',
  'failed completion leaves the event published'
);
select is(
  (select previous_status::text
   from public.set_event_status(
     '90000000-0000-0000-0000-000000000102',
     'cancelled'
   )),
  'published',
  'the cancellation result reports the previous status'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000102'),
  'cancelled',
  'the hosting organizer can cancel a published event'
);
select is(
  (select count(*)
   from public.event_registrations
   where event_id = '90000000-0000-0000-0000-000000000102'
     and status in ('confirmed', 'waitlisted')),
  0::bigint,
  'event cancellation closes confirmed and waitlisted registrations'
);
select is(
  (select count(*)
   from public.event_registrations
   where event_id = '90000000-0000-0000-0000-000000000102'
     and status = 'cancelled'
     and waitlist_position is null
     and queued_at is null),
  2::bigint,
  'event cancellation clears registration queue state'
);
set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000092';
select is(
  (select count(*)
   from public.audit_log
   where entity_type = 'event_registration'
     and entity_id in (
       select id
       from public.event_registrations
       where event_id = '90000000-0000-0000-0000-000000000102'
     )
     and action = 'event_registration.cancelled'),
  2::bigint,
  'event cancellation audits each registration closure'
);

set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000092';
select is(
  (select status::text
   from public.set_event_status(
     '90000000-0000-0000-0000-000000000105',
     'published'
   )),
  'published',
  'executives can publish an unhosted draft'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000105'),
  'published',
  'executive publication updates an unrelated event'
);
select is(
  (select status::text
   from public.set_event_status(
     '90000000-0000-0000-0000-000000000103',
     'cancelled'
   )),
  'cancelled',
  'executives can cancel another organizer event'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000103'),
  'cancelled',
  'executive moderation changes the event status'
);

set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000091';
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000106',
      'completed'
    )$$,
  'P0001',
  'event status transition is invalid',
  'draft events cannot skip publication and become completed'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000106'),
  'draft',
  'an invalid status transition leaves the draft unchanged'
);
select is(
  (select status::text
   from public.set_event_status(
     '90000000-0000-0000-0000-000000000104',
     'completed'
   )),
  'completed',
  'a hosting organizer can complete an ended event'
);
select is(
  (select status::text from public.events where id = '90000000-0000-0000-0000-000000000104'),
  'completed',
  'completion changes the ended event status'
);
select is(
  (select status::text
   from public.set_event_status(
     '90000000-0000-0000-0000-000000000104',
     'completed'
   )),
  'completed',
  'repeating completion is idempotent'
);
select throws_ok(
  $$select * from public.set_event_status(
      '90000000-0000-0000-0000-000000000104',
      'cancelled'
    )$$,
  'P0001',
  'event status transition is invalid',
  'completed events cannot be cancelled'
);
set local "request.jwt.claim.sub" = '90000000-0000-0000-0000-000000000092';
select is(
  (select metadata->>'from_status'
   from public.audit_log
   where entity_type = 'event'
     and entity_id = '90000000-0000-0000-0000-000000000101'
     and action = 'event.updated'),
  'draft',
  'status audits record the previous status'
);
select is(
  (select metadata->>'to_status'
   from public.audit_log
   where entity_type = 'event'
     and entity_id = '90000000-0000-0000-0000-000000000101'
     and action = 'event.updated'),
  'published',
  'status audits record the target status'
);
select is(
  (select actor_id
   from public.audit_log
   where entity_type = 'event'
     and entity_id = '90000000-0000-0000-0000-000000000101'
     and action = 'event.updated'),
  '90000000-0000-0000-0000-000000000091'::uuid,
  'status audits retain the hosting organizer actor'
);

select * from finish();

rollback;
