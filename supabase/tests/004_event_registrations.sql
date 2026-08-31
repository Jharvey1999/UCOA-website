begin;

select plan(58);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000021', 'rsvp-member-a@example.test'),
  ('00000000-0000-0000-0000-000000000022', 'rsvp-member-b@example.test'),
  ('00000000-0000-0000-0000-000000000023', 'rsvp-pending@example.test'),
  ('00000000-0000-0000-0000-000000000024', 'rsvp-expired@example.test'),
  ('00000000-0000-0000-0000-000000000025', 'rsvp-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000026', 'rsvp-executive@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '00000000-0000-0000-0000-000000000021',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000022',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000023',
    null,
    null,
    'pending',
    null
  ),
  (
    '00000000-0000-0000-0000-000000000024',
    '2020-09-01',
    '2025-08-31',
    'expired',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000025',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000026',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000026'
from public.memberships
where status in ('active', 'expired');

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '00000000-0000-0000-0000-000000000021',
    'member',
    '00000000-0000-0000-0000-000000000026'
  ),
  (
    '00000000-0000-0000-0000-000000000022',
    'member',
    '00000000-0000-0000-0000-000000000026'
  ),
  (
    '00000000-0000-0000-0000-000000000024',
    'organizer',
    '00000000-0000-0000-0000-000000000026'
  ),
  (
    '00000000-0000-0000-0000-000000000025',
    'organizer',
    '00000000-0000-0000-0000-000000000026'
  ),
  (
    '00000000-0000-0000-0000-000000000026',
    'executive',
    '00000000-0000-0000-0000-000000000025'
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
values
  (
    '40000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Capacity Event',
    'A one-slot event with a waitlist.',
    '2026-10-01 14:00:00+00',
    '2026-10-01 16:00:00+00',
    'America/Edmonton',
    'hike',
    'members_only',
    'published',
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Closed Capacity Event',
    'A one-slot event without a waitlist.',
    '2026-10-02 14:00:00+00',
    '2026-10-02 16:00:00+00',
    'America/Edmonton',
    'hike',
    'members_only',
    'published',
    1,
    false
  ),
  (
    '40000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Waiver Event',
    'An event requiring the approved waiver workflow.',
    '2026-10-03 14:00:00+00',
    '2026-10-03 16:00:00+00',
    'America/Edmonton',
    'scramble',
    'members_only',
    'published',
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Cancelled Event',
    'A cancelled event.',
    '2026-10-04 14:00:00+00',
    '2026-10-04 16:00:00+00',
    'America/Edmonton',
    'social',
    'members_only',
    'cancelled',
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Completed Event',
    'A completed event.',
    '2026-10-05 14:00:00+00',
    '2026-10-05 16:00:00+00',
    'America/Edmonton',
    'social',
    'members_only',
    'completed',
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Shrink Protection Event',
    'An event used to protect confirmed capacity.',
    '2026-10-06 14:00:00+00',
    '2026-10-06 16:00:00+00',
    'America/Edmonton',
    'climbing',
    'members_only',
    'published',
    2,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000007',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Unlimited Event',
    'An event with unlimited capacity.',
    '2026-10-07 14:00:00+00',
    '2026-10-07 16:00:00+00',
    'America/Edmonton',
    'social',
    'members_only',
    'published',
    0,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000008',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Eligibility Reconciliation Event',
    'An event used to verify stale waitlist handling.',
    '2026-10-08 14:00:00+00',
    '2026-10-08 16:00:00+00',
    'America/Edmonton',
    'hike',
    'members_only',
    'published',
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000009',
    '00000000-0000-0000-0000-000000000025',
    'RSVP Hidden Draft Event',
    'A draft event whose existence must not be disclosed.',
    '2026-10-09 14:00:00+00',
    '2026-10-09 16:00:00+00',
    'America/Edmonton',
    'hike',
    'members_only',
    'draft',
    1,
    true
  );

insert into public.event_private_details (event_id, member_description, waiver_required)
values
  ('40000000-0000-0000-0000-000000000001', 'Private capacity event details.', false),
  ('40000000-0000-0000-0000-000000000002', 'Private closed-capacity event details.', false),
  ('40000000-0000-0000-0000-000000000003', 'Private waiver event details.', true),
  ('40000000-0000-0000-0000-000000000004', 'Private cancelled event details.', false),
  ('40000000-0000-0000-0000-000000000005', 'Private completed event details.', false),
  ('40000000-0000-0000-0000-000000000006', 'Private capacity-protection event details.', false),
  ('40000000-0000-0000-0000-000000000007', 'Private unlimited event details.', false),
  ('40000000-0000-0000-0000-000000000008', 'Private eligibility reconciliation event details.', false);

insert into public.event_hosts (event_id, user_id, assigned_by)
select event_ids.id, '00000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000026'
from (
  values
    ('40000000-0000-0000-0000-000000000001'::uuid),
    ('40000000-0000-0000-0000-000000000002'::uuid),
    ('40000000-0000-0000-0000-000000000003'::uuid),
    ('40000000-0000-0000-0000-000000000004'::uuid),
    ('40000000-0000-0000-0000-000000000005'::uuid),
    ('40000000-0000-0000-0000-000000000006'::uuid),
    ('40000000-0000-0000-0000-000000000007'::uuid),
    ('40000000-0000-0000-0000-000000000008'::uuid)
) as event_ids(id);

insert into public.event_registrations (
  event_id,
  user_id,
  status,
  waitlist_position,
  queued_at
)
values
  (
    '40000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000021',
    'confirmed',
    null,
    null
  ),
  (
    '40000000-0000-0000-0000-000000000008',
    '00000000-0000-0000-0000-000000000021',
    'confirmed',
    null,
    null
  ),
  (
    '40000000-0000-0000-0000-000000000008',
    '00000000-0000-0000-0000-000000000024',
    'waitlisted',
    1,
    '2026-09-01 00:00:00+00'
  ),
  (
    '40000000-0000-0000-0000-000000000008',
    '00000000-0000-0000-0000-000000000022',
    'waitlisted',
    2,
    '2026-09-01 00:00:01+00'
  );

set local role anon;
select throws_ok(
  $$select * from public.register_for_event('40000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'anonymous users cannot call the registration function'
);
select throws_ok(
  $$select count(*) from public.event_registrations$$,
  '42501',
  null,
  'anonymous users cannot read registrations'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000023';
select throws_ok(
  $$select * from public.register_for_event('40000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'pending users cannot register for events'
);
select is(
  (select count(*) from public.event_registrations),
  0::bigint,
  'pending registration attempts create no rows'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000024';
select throws_ok(
  $$select * from public.register_for_event('40000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'expired users cannot register for events'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000001')),
  'confirmed',
  'the first active member receives the last confirmed place'
);
select is(
  (select waitlist_position from public.register_for_event('40000000-0000-0000-0000-000000000001')),
  null::integer,
  'a confirmed registration has no waitlist position'
);
select is(
  (select count(*) from public.event_registrations where event_id = '40000000-0000-0000-0000-000000000001'),
  1::bigint,
  'the first registration creates one row'
);
select is(
  (select count(distinct registration_id)
   from (
     select registration_id from public.register_for_event('40000000-0000-0000-0000-000000000001')
     union all
     select registration_id from public.register_for_event('40000000-0000-0000-0000-000000000001')
   ) as retry_results),
  1::bigint,
  'repeated registration requests are idempotent'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000001')),
  'waitlisted',
  'the next active member joins the waitlist when capacity is full'
);
select is(
  (select waitlist_position from public.register_for_event('40000000-0000-0000-0000-000000000001')),
  1,
  'the first waitlisted member receives position one'
);
select is(
  (select count(distinct registration_id)
   from (
     select registration_id from public.register_for_event('40000000-0000-0000-0000-000000000001')
     union all
     select registration_id from public.register_for_event('40000000-0000-0000-0000-000000000001')
   ) as retry_results),
  1::bigint,
  'repeated waitlist requests are idempotent'
);
select is(
  (select count(*) from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000022'),
  1::bigint,
  'a waitlisted member has one registration row'
);
select is(
  (select count(*) from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000021'),
  0::bigint,
  'members cannot read another member registration'
);
select throws_ok(
  $$insert into public.event_registrations (event_id, user_id)
    values ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000022')$$,
  '42501',
  null,
  'members cannot insert registrations directly'
);
select throws_ok(
  $$update public.event_registrations
    set status = 'cancelled'
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000022'$$,
  '42501',
  null,
  'members cannot update registrations directly at the privilege layer'
);
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000022'),
  'waitlisted',
  'a denied direct update leaves the waitlist row unchanged'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000024';
select is(
  (select count(*) from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000008'),
  0::bigint,
  'expired members cannot read their historical registrations'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select throws_ok(
  $$delete from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000022'$$,
  '42501',
  null,
  'members cannot delete registrations directly at the privilege layer'
);
select is(
  (select count(*) from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'),
  1::bigint,
  'after a denied delete a member still reads exactly their own registration row'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000002')),
  'confirmed',
  'an active member can claim capacity on an event without a waitlist'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select throws_ok(
  $$select * from public.register_for_event('40000000-0000-0000-0000-000000000002')$$,
  'P0001',
  null,
  'a full event without a waitlist rejects registration'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select throws_ok(
  $$select * from public.register_for_event('40000000-0000-0000-0000-000000000003')$$,
  'P0001',
  null,
  'an event requiring a waiver rejects registration until the workflow exists'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select is(
  (select registration_status::text from public.cancel_event_registration('40000000-0000-0000-0000-000000000001')),
  'cancelled',
  'a waitlisted member can cancel their registration'
);
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000022'),
  'cancelled',
  'cancellation records the cancelled state'
);
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000001')),
  'waitlisted',
  'a cancelled member can rejoin the waitlist'
);
select is(
  (select waitlist_position from public.register_for_event('40000000-0000-0000-0000-000000000001')),
  1,
  'a rejoining member is placed at the end of the current waitlist'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select is(
  (select promoted_registration_id is not null
   from public.cancel_event_registration('40000000-0000-0000-0000-000000000001')),
  true,
  'cancelling a confirmed member promotes the next waitlisted member'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000025';
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000021'),
  'cancelled',
  'the cancelling member becomes cancelled'
);
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000022'),
  'confirmed',
  'the promoted member becomes confirmed'
);
select is(
  (select waitlist_position from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000022'),
  null::integer,
  'a promoted member has no waitlist position'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000001')),
  'waitlisted',
  'a cancelled member can rejoin a full event'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select is(
  (select promoted_registration_id is not null
   from public.cancel_event_registration('40000000-0000-0000-0000-000000000001')),
  true,
  'a second confirmed cancellation promotes the rejoining member'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000025';
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000001'
      and user_id = '00000000-0000-0000-0000-000000000021'),
  'confirmed',
  'the rejoining member is confirmed after promotion'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select is(
  (select registration_status::text from public.cancel_event_registration('40000000-0000-0000-0000-000000000001')),
  'cancelled',
  'repeating cancellation is idempotent for an already cancelled registration'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select throws_ok(
  $$select * from public.register_for_event('40000000-0000-0000-0000-000000000004')$$,
  'P0001',
  null,
  'cancelled events reject registration'
);
select throws_ok(
  $$select * from public.register_for_event('40000000-0000-0000-0000-000000000005')$$,
  'P0001',
  null,
  'completed events reject registration'
);
select throws_ok(
  $$select * from public.cancel_event_registration('40000000-0000-0000-0000-000000000004')$$,
  'P0001',
  null,
  'closed events reject cancellation of an active registration'
);
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000004'
      and user_id = '00000000-0000-0000-0000-000000000021'),
  'confirmed',
  'closed-event cancellation leaves the registration unchanged'
);
select throws_ok(
  $$select * from public.cancel_event_registration('40000000-0000-0000-0000-0000000000aa')$$,
  'P0001',
  'event registration unavailable',
  'cancelling an unknown event id returns a generic unavailable error'
);
select throws_ok(
  $$select * from public.cancel_event_registration('40000000-0000-0000-0000-000000000009')$$,
  'P0001',
  'event registration unavailable',
  'cancelling an inaccessible draft event returns the identical generic error'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000025';
select is(
  (select count(*) from public.event_registrations where event_id = '40000000-0000-0000-0000-000000000001'),
  2::bigint,
  'a hosted organizer can read registrations for their event'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000006')),
  'confirmed',
  'the first member can claim one capacity-protection place'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000006')),
  'confirmed',
  'the second member can claim the final capacity-protection place'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000025';
select throws_ok(
  $$update public.events set capacity = 1 where id = '40000000-0000-0000-0000-000000000006'$$,
  '23514',
  null,
  'event capacity cannot be reduced below confirmed registrations'
);
set local role postgres;
select is(
  (select capacity from public.events where id = '40000000-0000-0000-0000-000000000006'),
  2,
  'a rejected capacity reduction leaves the event unchanged'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000025';
select lives_ok(
  $$update public.events set capacity = 2 where id = '40000000-0000-0000-0000-000000000008'$$,
  'increasing event capacity reconciles the existing waitlist'
);
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000008'
      and user_id = '00000000-0000-0000-0000-000000000022'),
  'confirmed',
  'capacity increase promotes the next eligible active member'
);
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000008'
      and user_id = '00000000-0000-0000-0000-000000000024'),
  'waitlisted',
  'capacity increase skips an expired waitlisted member'
);
select is(
  (select waitlist_position from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000008'
      and user_id = '00000000-0000-0000-0000-000000000024'),
  1,
  'the skipped expired member keeps the first waitlist position'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select is(
  (select promoted_registration_id is null
   from public.cancel_event_registration('40000000-0000-0000-0000-000000000008')),
  true,
  'cancellation does not promote an expired waitlisted member'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000025';
select is(
  (select status::text from public.event_registrations
    where event_id = '40000000-0000-0000-0000-000000000008'
      and user_id = '00000000-0000-0000-0000-000000000024'),
  'waitlisted',
  'an ineligible waitlisted member remains queued without promotion'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000021';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000007')),
  'confirmed',
  'zero capacity represents unlimited capacity for the first member'
);
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000022';
select is(
  (select registration_status::text from public.register_for_event('40000000-0000-0000-0000-000000000007')),
  'confirmed',
  'zero capacity represents unlimited capacity for the second member'
);

set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000026';
select is(
  (select count(*) from public.event_registrations where event_id = '40000000-0000-0000-0000-000000000001'),
  2::bigint,
  'executives can read all registrations for an event'
);
select is(
  (select count(*) from public.audit_log
    where entity_type = 'event_registration'
      and entity_id in (
        select id from public.event_registrations
        where event_id = '40000000-0000-0000-0000-000000000001'
      )
      and action = 'event_registration.created'),
  2::bigint,
  'registration creation writes safe audit records'
);
select is(
  (select count(*) from public.audit_log
    where entity_type = 'event_registration'
      and entity_id in (
        select id from public.event_registrations
        where event_id = '40000000-0000-0000-0000-000000000001'
      )
      and action = 'event_registration.cancelled'),
  3::bigint,
  'registration cancellation writes safe audit records'
);
select is(
  (select count(*) from public.audit_log
    where entity_type = 'event_registration'
      and entity_id in (
        select id from public.event_registrations
        where event_id = '40000000-0000-0000-0000-000000000001'
      )
      and action = 'event_registration.promoted'),
  2::bigint,
  'waitlist promotion writes safe audit records'
);

select * from finish();

rollback;