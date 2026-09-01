begin;

select plan(100);

insert into auth.users (id, email)
values
  ('a0000000-0000-0000-0000-000000000001', 'waiver-member-a@example.test'),
  ('a0000000-0000-0000-0000-000000000002', 'waiver-member-b@example.test'),
  ('a0000000-0000-0000-0000-000000000003', 'waiver-pending@example.test'),
  ('a0000000-0000-0000-0000-000000000004', 'waiver-expired@example.test'),
  ('a0000000-0000-0000-0000-000000000005', 'waiver-organizer@example.test'),
  ('a0000000-0000-0000-0000-000000000006', 'waiver-other-organizer@example.test'),
  ('a0000000-0000-0000-0000-000000000007', 'waiver-executive@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    'a0000000-0000-0000-0000-000000000001',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    'a0000000-0000-0000-0000-000000000003',
    null,
    null,
    'pending',
    null
  ),
  (
    'a0000000-0000-0000-0000-000000000004',
    '2020-09-01',
    '2025-08-31',
    'expired',
    '2020-09-01 00:00:00+00'
  ),
  (
    'a0000000-0000-0000-0000-000000000005',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    'a0000000-0000-0000-0000-000000000006',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    'a0000000-0000-0000-0000-000000000007',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  );

insert into public.membership_admin (membership_id, approved_by)
select id, 'a0000000-0000-0000-0000-000000000007'
from public.memberships
where status in ('active', 'expired');

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    'a0000000-0000-0000-0000-000000000001',
    'member',
    'a0000000-0000-0000-0000-000000000007'
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    'member',
    'a0000000-0000-0000-0000-000000000007'
  ),
  (
    'a0000000-0000-0000-0000-000000000004',
    'organizer',
    'a0000000-0000-0000-0000-000000000007'
  ),
  (
    'a0000000-0000-0000-0000-000000000005',
    'organizer',
    'a0000000-0000-0000-0000-000000000007'
  ),
  (
    'a0000000-0000-0000-0000-000000000006',
    'organizer',
    'a0000000-0000-0000-0000-000000000007'
  ),
  (
    'a0000000-0000-0000-0000-000000000007',
    'executive',
    'a0000000-0000-0000-0000-000000000005'
  );

insert into public.waivers (
  id,
  version,
  acknowledgement_method,
  document_reference,
  status,
  approved_by,
  approved_at
)
values
  (
    'b0000000-0000-0000-0000-000000000001',
    'outdoor-v1',
    'built_in',
    'ucoa://waivers/outdoor-v1',
    'approved',
    'a0000000-0000-0000-0000-000000000007',
    '2026-08-30 00:00:00+00'
  ),
  (
    'b0000000-0000-0000-0000-000000000002',
    'external-v1',
    'external',
    'https://example.test/ucoa-outdoor-v1',
    'approved',
    'a0000000-0000-0000-0000-000000000007',
    '2026-08-30 00:00:00+00'
  ),
  (
    'b0000000-0000-0000-0000-000000000003',
    'organizer-recorded-v1',
    'organizer_recorded',
    'ucoa://waivers/organizer-recorded-v1',
    'approved',
    'a0000000-0000-0000-0000-000000000007',
    '2026-08-30 00:00:00+00'
  ),
  (
    'b0000000-0000-0000-0000-000000000004',
    'draft-v1',
    'built_in',
    'ucoa://waivers/draft-v1',
    'draft',
    null,
    null
  ),
  (
    'b0000000-0000-0000-0000-000000000005',
    'retired-v1',
    'built_in',
    'ucoa://waivers/retired-v1',
    'retired',
    'a0000000-0000-0000-0000-000000000007',
    '2026-08-30 00:00:00+00'
  ),
  (
    'b0000000-0000-0000-0000-000000000006',
    'unassigned-v1',
    'built_in',
    'ucoa://waivers/unassigned-v1',
    'approved',
    'a0000000-0000-0000-0000-000000000007',
    '2026-08-30 00:00:00+00'
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
    'c0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000005',
    'Built-in waiver event',
    'A published event using the approved built-in acknowledgement.',
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
    'c0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000005',
    'External waiver event',
    'A published event using an external waiver workflow.',
    '2026-10-02 14:00:00+00',
    '2026-10-02 16:00:00+00',
    'America/Edmonton',
    'scramble',
    'members_only',
    'published',
    0,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000003',
    'a0000000-0000-0000-0000-000000000005',
    'Organizer-recorded waiver event',
    'A published event using organizer-recorded completion.',
    '2026-10-03 14:00:00+00',
    '2026-10-03 16:00:00+00',
    'America/Edmonton',
    'camping',
    'members_only',
    'published',
    0,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000004',
    'a0000000-0000-0000-0000-000000000005',
    'Legacy waiver flag event',
    'A published event with the old waiver flag only.',
    '2026-10-04 14:00:00+00',
    '2026-10-04 16:00:00+00',
    'America/Edmonton',
    'climbing',
    'members_only',
    'published',
    0,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000005',
    'a0000000-0000-0000-0000-000000000005',
    'Mutable waiver event',
    'A published event used for assignment checks.',
    '2026-10-05 14:00:00+00',
    '2026-10-05 16:00:00+00',
    'America/Edmonton',
    'social',
    'members_only',
    'published',
    0,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000006',
    'a0000000-0000-0000-0000-000000000005',
    'Waitlist waiver event',
    'A one-slot event used to test waiver-aware promotion.',
    '2026-10-06 14:00:00+00',
    '2026-10-06 16:00:00+00',
    'America/Edmonton',
    'hike',
    'members_only',
    'published',
    1,
    true
  ),
  (
    'c0000000-0000-0000-0000-000000000007',
    'a0000000-0000-0000-0000-000000000005',
    'Draft waiver event',
    'A draft event for manager-only status checks.',
    '2026-10-07 14:00:00+00',
    '2026-10-07 16:00:00+00',
    'America/Edmonton',
    'course',
    'members_only',
    'draft',
    0,
    true
  );

insert into public.event_private_details (
  event_id,
  member_description,
  exact_location,
  waiver_required,
  waiver_id
)
values
  (
    'c0000000-0000-0000-0000-000000000001',
    'Private built-in waiver details.',
    'Private built-in location.',
    true,
    'b0000000-0000-0000-0000-000000000001'
  ),
  (
    'c0000000-0000-0000-0000-000000000002',
    'Private external waiver details.',
    'Private external location.',
    true,
    'b0000000-0000-0000-0000-000000000002'
  ),
  (
    'c0000000-0000-0000-0000-000000000003',
    'Private organizer-recorded details.',
    'Private organizer-recorded location.',
    true,
    'b0000000-0000-0000-0000-000000000003'
  ),
  (
    'c0000000-0000-0000-0000-000000000004',
    'Private legacy waiver details.',
    'Private legacy location.',
    true,
    null
  ),
  (
    'c0000000-0000-0000-0000-000000000005',
    'Private mutable waiver details.',
    'Private mutable location.',
    false,
    null
  ),
  (
    'c0000000-0000-0000-0000-000000000006',
    'Private waitlist waiver details.',
    'Private waitlist location.',
    true,
    'b0000000-0000-0000-0000-000000000001'
  ),
  (
    'c0000000-0000-0000-0000-000000000007',
    'Private draft waiver details.',
    'Private draft location.',
    true,
    'b0000000-0000-0000-0000-000000000004'
  );

insert into public.event_hosts (event_id, user_id, assigned_by)
select event_ids.id, 'a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000007'
from (
  values
    ('c0000000-0000-0000-0000-000000000001'::uuid),
    ('c0000000-0000-0000-0000-000000000002'::uuid),
    ('c0000000-0000-0000-0000-000000000003'::uuid),
    ('c0000000-0000-0000-0000-000000000004'::uuid),
    ('c0000000-0000-0000-0000-000000000005'::uuid),
    ('c0000000-0000-0000-0000-000000000006'::uuid),
    ('c0000000-0000-0000-0000-000000000007'::uuid)
) as event_ids(id);

select is(
  (select relrowsecurity from pg_class where oid = 'public.waivers'::regclass),
  true,
  'waivers enforce row-level security'
);
select is(
  (select relrowsecurity from pg_class where oid = 'public.waiver_acknowledgements'::regclass),
  true,
  'waiver acknowledgements enforce row-level security'
);
select is(
  has_table_privilege('anon', 'public.waivers', 'SELECT'),
  false,
  'anonymous users have no waiver table privilege'
);
select is(
  has_table_privilege('authenticated', 'public.waivers', 'SELECT'),
  true,
  'authenticated users have the waiver select privilege needed by RLS'
);
select is(
  has_table_privilege('authenticated', 'public.waiver_acknowledgements', 'SELECT'),
  true,
  'authenticated users can read acknowledgements through policy'
);
select is(
  has_table_privilege('authenticated', 'public.waiver_acknowledgements', 'INSERT'),
  false,
  'authenticated users cannot insert acknowledgements directly'
);
select is(
  has_column_privilege('authenticated', 'public.event_private_details', 'waiver_id', 'SELECT'),
  false,
  'authenticated users cannot select the waiver foreign key directly'
);
select is(
  has_column_privilege('authenticated', 'public.event_private_details', 'waiver_required', 'UPDATE'),
  false,
  'authenticated users cannot update the legacy waiver flag directly'
);
select is(
  has_function_privilege(
    'anon',
    'public.get_event_waiver_status(uuid)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the waiver status function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.get_event_waiver_status(uuid)',
    'execute'
  ),
  true,
  'authenticated users can execute the waiver status function'
);
select is(
  has_function_privilege(
    'anon',
    'public.record_event_waiver_acknowledgement(uuid)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the acknowledgement function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.record_event_waiver_acknowledgement(uuid)',
    'execute'
  ),
  true,
  'authenticated users can execute the acknowledgement function'
);
select is(
  has_function_privilege(
    'anon',
    'public.set_event_waiver(uuid, uuid)',
    'execute'
  ),
  false,
  'anonymous users cannot execute the waiver assignment function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.set_event_waiver(uuid, uuid)',
    'execute'
  ),
  true,
  'authenticated users can execute the waiver assignment function'
);

set local role anon;
select throws_ok(
  $$select count(*) from public.waivers$$,
  '42501',
  null,
  'anonymous users cannot read waiver metadata'
);
select throws_ok(
  $$select count(*) from public.waiver_acknowledgements$$,
  '42501',
  null,
  'anonymous users cannot read waiver acknowledgements'
);
select throws_ok(
  $$select * from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'anonymous users cannot read waiver status'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'anonymous users cannot acknowledge a waiver'
);
select throws_ok(
  $$select * from public.set_event_waiver(
      'c0000000-0000-0000-0000-000000000005',
      'b0000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  null,
  'anonymous users cannot assign a waiver to an event'
);

set local role authenticated;
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000003';
select is(
  (select count(*) from public.waivers),
  0::bigint,
  'pending users cannot read waiver metadata'
);
set local role authenticated;
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000003';
select is(
  (select count(event_id) from public.event_private_details),
  0::bigint,
  'pending users cannot read private event details'
);
select is(
  (select count(*) from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  0::bigint,
  'pending users receive no waiver status row'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'pending users cannot acknowledge waivers'
);
select throws_ok(
  $$select * from public.register_for_event('c0000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'pending users cannot register for waiver events'
);

set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000004';
select is(
  (select count(*) from public.waivers),
  0::bigint,
  'expired users cannot read waiver metadata'
);
select is(
  (select count(*) from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  0::bigint,
  'expired users receive no waiver status row'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'expired users cannot acknowledge waivers'
);
select throws_ok(
  $$select * from public.register_for_event('c0000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'expired users cannot register for waiver events'
);

set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from public.waivers),
  3::bigint,
  'active members see only approved waivers assigned to readable events'
);
select is(
  (select count(*) from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  1::bigint,
  'active members can read the built-in waiver status for a published event'
);
select is(
  (select version from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  'outdoor-v1',
  'waiver status reports the assigned version'
);
select is(
  (select acknowledgement_method::text
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000099')),
  null::text,
  'a guessed unknown event id returns no waiver status'
);
select is(
  (select acknowledgement_method::text
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  'built_in',
  'waiver status reports the approved acknowledgement method'
);
select is(
  (select document_reference
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  'ucoa://waivers/outdoor-v1',
  'waiver status exposes only the approved document reference'
);
select is(
  (select acknowledgement_status::text
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  null::text,
  'an active member starts without an acknowledgement'
);
select is(
  (select count(*)
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'),
  0::bigint,
  'the built-in event has no acknowledgement before the member acts'
);
select throws_ok(
  $$insert into public.waiver_acknowledgements (
      event_id,
      waiver_id,
      user_id,
      evidence_reference
    ) values (
      'c0000000-0000-0000-0000-000000000001',
      'b0000000-0000-0000-0000-000000000001',
      'a0000000-0000-0000-0000-000000000001',
      'ucoa://waivers/outdoor-v1'
    )$$,
  '42501',
  null,
  'active members cannot insert acknowledgements directly'
);
select throws_ok(
  $$update public.event_private_details
    set waiver_id = 'b0000000-0000-0000-0000-000000000006'
    where event_id = 'c0000000-0000-0000-0000-000000000005'$$,
  '42501',
  null,
  'active members cannot set the waiver foreign key directly'
);
select throws_ok(
  $$update public.event_private_details
    set waiver_required = false
    where event_id = 'c0000000-0000-0000-0000-000000000004'$$,
  '42501',
  null,
  'active members cannot clear a legacy waiver flag directly'
);
set local role postgres;
select is(
  (select waiver_id from public.event_private_details
   where event_id = 'c0000000-0000-0000-0000-000000000005'),
  null::uuid,
  'a denied direct waiver assignment leaves the event unchanged'
);
select is(
  (select waiver_required from public.event_private_details
   where event_id = 'c0000000-0000-0000-0000-000000000004'),
  true,
  'a denied direct legacy waiver update leaves the requirement unchanged'
);
set local role authenticated;
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select version
   from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000001')),
  'outdoor-v1',
  'an active member can acknowledge an approved built-in waiver'
);
select is(
  (select count(*)
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and waiver_id = 'b0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000001'
     and status = 'acknowledged'),
  1::bigint,
  'acknowledgement records the exact event and waiver version'
);
select is(
  (select evidence_reference
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000001'),
  'ucoa://waivers/outdoor-v1',
  'acknowledgement evidence uses the approved document reference'
);
set local role postgres;
select is(
  (select count(*)
   from public.audit_log
   where entity_type = 'waiver_acknowledgement'
     and entity_id in (
       select id
       from public.waiver_acknowledgements
       where event_id = 'c0000000-0000-0000-0000-000000000001'
         and user_id = 'a0000000-0000-0000-0000-000000000001'
     )
     and action = 'waiver_acknowledgement.created'),
  1::bigint,
  'acknowledgement creation writes a safe audit record'
);
set local role authenticated;
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select acknowledgement_status::text
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000001')),
  'acknowledged',
  'waiver status reflects the member acknowledgement'
);
select is(
  (select version
   from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000001')),
  'outdoor-v1',
  'repeating acknowledgement is idempotent'
);
select is(
  (select count(*)
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000001'),
  1::bigint,
  'repeating acknowledgement does not create a duplicate row'
);
select is(
  (select registration_status::text
   from public.register_for_event('c0000000-0000-0000-0000-000000000001')),
  'confirmed',
  'a member can register after acknowledging the built-in waiver'
);

set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000002';
select throws_ok(
  $$select * from public.register_for_event('c0000000-0000-0000-0000-000000000001')$$,
  'P0001',
  'approved waiver completion is required before registration',
  'a member without acknowledgement cannot register'
);
select is(
  (select count(*) from public.event_registrations
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000002'),
  0::bigint,
  'a blocked waiver registration creates no row'
);
select is(
  (select version
   from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000001')),
  'outdoor-v1',
  'the second active member can acknowledge the same waiver version'
);
select is(
  (select registration_status::text
   from public.register_for_event('c0000000-0000-0000-0000-000000000001')),
  'waitlisted',
  'an acknowledged member joins the waitlist when capacity is full'
);
select is(
  (select waitlist_position
   from public.event_registrations
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000002'),
  1,
  'the acknowledged member receives the first waitlist position'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select promoted_registration_id is not null
   from public.cancel_event_registration('c0000000-0000-0000-0000-000000000001')),
  true,
  'cancelling the confirmed member promotes an acknowledged waitlisted member'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000002';
select is(
  (select status::text
   from public.event_registrations
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000002'),
  'confirmed',
  'waiver-complete waitlist promotion produces a confirmed registration'
);

set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select acknowledgement_method::text
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000002')),
  'external',
  'external waiver status remains visible as an unsupported method'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000002')$$,
  'P0001',
  'approved waiver workflow is external',
  'external waiver events cannot use the built-in acknowledgement function'
);
select throws_ok(
  $$select * from public.register_for_event('c0000000-0000-0000-0000-000000000002')$$,
  'P0001',
  'approved waiver completion is required before registration',
  'external waiver events remain fail-closed for registration'
);
select is(
  (select acknowledgement_method::text
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000003')),
  'organizer_recorded',
  'organizer-recorded waiver status remains visible as an unsupported method'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000003')$$,
  'P0001',
  'approved waiver workflow is external',
  'organizer-recorded waiver events cannot use the built-in acknowledgement function'
);
select is(
  (select count(*)
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000004')),
  1::bigint,
  'legacy waiver-required events expose a status row without an invented waiver'
);
select is(
  (select waiver_id
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000004')),
  null::uuid,
  'legacy waiver-required events have no guessed waiver id'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000004')$$,
  'P0001',
  'approved waiver unavailable',
  'legacy waiver flags remain fail-closed without an approved record'
);
select throws_ok(
  $$select * from public.register_for_event('c0000000-0000-0000-0000-000000000004')$$,
  'P0001',
  'approved waiver completion is required before registration',
  'legacy waiver flags continue to block registration'
);

select throws_ok(
  $$update public.waiver_acknowledgements
    set status = 'revoked'
    where event_id = 'c0000000-0000-0000-0000-000000000001'
      and user_id = 'a0000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'members cannot update acknowledgement status directly'
);
select throws_ok(
  $$delete from public.waiver_acknowledgements
    where event_id = 'c0000000-0000-0000-0000-000000000001'
      and user_id = 'a0000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'members cannot delete acknowledgement evidence directly'
);
select is(
  (select count(*)
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000001'),
  1::bigint,
  'denied acknowledgement writes leave the evidence unchanged'
);
set local role authenticated;
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select count(*)
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000001'),
  1::bigint,
  'a member can read only their own acknowledgement row'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000006';
select is(
  (select count(*)
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'
     and user_id = 'a0000000-0000-0000-0000-000000000001'),
  0::bigint,
  'a non-host organizer cannot read another member acknowledgement'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000005';
select is(
  (select count(*)
   from public.waiver_acknowledgements
   where event_id = 'c0000000-0000-0000-0000-000000000001'),
  2::bigint,
  'the hosting organizer can read acknowledgements for the hosted event'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000007';
select is(
  (select count(*) from public.waiver_acknowledgements),
  2::bigint,
  'executives can read acknowledgement records'
);

set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000005';
select throws_ok(
  $$select * from public.set_event_waiver(
      'c0000000-0000-0000-0000-000000000005',
      'b0000000-0000-0000-0000-000000000004'
    )$$,
  'P0001',
  'approved waiver unavailable',
  'organizers cannot assign a draft waiver'
);
select is(
  (select waiver_required
   from public.set_event_waiver(
     'c0000000-0000-0000-0000-000000000005',
     'b0000000-0000-0000-0000-000000000006'
   )),
  true,
  'a hosting organizer can assign an approved waiver'
);
select is(
  (select waiver_required
   from public.event_private_details
   where event_id = 'c0000000-0000-0000-0000-000000000005'),
  true,
  'waiver assignment enables the event requirement'
);
select is(
  (select waiver_id
   from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000005')),
  'b0000000-0000-0000-0000-000000000006'::uuid,
  'waiver status reads the newly assigned approved waiver'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000006';
select throws_ok(
  $$select * from public.set_event_waiver(
      'c0000000-0000-0000-0000-000000000005',
      'b0000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  'event unavailable',
  'another organizer cannot assign a waiver to an unhosted event'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000004';
select throws_ok(
  $$select * from public.set_event_waiver(
      'c0000000-0000-0000-0000-000000000005',
      'b0000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  'event unavailable',
  'expired organizers cannot assign event waivers'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000003';
select throws_ok(
  $$select * from public.set_event_waiver(
      'c0000000-0000-0000-0000-000000000005',
      'b0000000-0000-0000-0000-000000000001'
    )$$,
  '42501',
  'event unavailable',
  'pending users cannot assign event waivers'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000005';
select is(
  (select waiver_required
   from public.set_event_waiver(
     'c0000000-0000-0000-0000-000000000005',
     null
   )),
  false,
  'the hosting organizer can clear an event waiver requirement'
);
select is(
  (select registration_status::text
   from public.register_for_event('c0000000-0000-0000-0000-000000000005')),
  'confirmed',
  'clearing the waiver requirement restores normal registration'
);
set local role postgres;
select is(
  (select count(*)
   from public.audit_log
   where entity_type = 'event'
     and entity_id = 'c0000000-0000-0000-0000-000000000005'
     and action = 'event.waiver_updated'),
  2::bigint,
  'waiver assignment and clearing are audited without legal text'
);

set local role authenticated;
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select throws_ok(
  $$insert into public.waivers (
      id,
      version,
      acknowledgement_method,
      document_reference
    ) values (
      'b0000000-0000-0000-0000-000000000008',
      'member-created-v1',
      'built_in',
      'ucoa://waivers/member-created-v1'
    )$$,
  '42501',
  null,
  'active members cannot create waiver metadata'
);
select lives_ok(
  $$update public.waivers
    set version = 'blocked-v1'
    where id = 'b0000000-0000-0000-0000-000000000001'$$,
  'active members cannot update waiver metadata'
);
select lives_ok(
  $$delete from public.waivers where id = 'b0000000-0000-0000-0000-000000000001'$$,
  'active members cannot delete waiver metadata'
);
select is(
  (select count(*) from public.waivers where id = 'b0000000-0000-0000-0000-000000000001'),
  1::bigint,
  'denied waiver writes leave approved metadata unchanged'
);

set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000005';
select is(
  (select count(*) from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000007')),
  1::bigint,
  'the host can inspect draft waiver metadata for a hosted draft'
);
select is(
  (select version from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000007')),
  'draft-v1',
  'manager-only waiver status preserves the draft version'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from public.get_event_waiver_status('c0000000-0000-0000-0000-000000000007')),
  0::bigint,
  'active members cannot inspect waiver metadata on a draft event'
);

set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000007';
select lives_ok(
  $$insert into public.waivers (
      id,
      version,
      acknowledgement_method,
      document_reference
    ) values (
      'b0000000-0000-0000-0000-000000000007',
      'executive-draft-v1',
      'built_in',
      'ucoa://waivers/executive-draft-v1'
    )$$,
  'executives can create draft waiver metadata'
);
select lives_ok(
  $$update public.waivers
    set status = 'approved',
        approved_by = 'a0000000-0000-0000-0000-000000000007',
        approved_at = '2026-08-30 00:00:00+00'
    where id = 'b0000000-0000-0000-0000-000000000007'$$,
  'executives can approve their own waiver metadata'
);
select is(
  (select count(*) from public.waivers where id = 'b0000000-0000-0000-0000-000000000007'),
  1::bigint,
  'executives can read all waiver metadata'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from public.waivers where id = 'b0000000-0000-0000-0000-000000000007'),
  0::bigint,
  'approved but unassigned waivers remain hidden from ordinary members'
);

set local role postgres;
insert into public.event_registrations (
  event_id,
  user_id,
  status,
  waitlist_position,
  queued_at
)
values (
  'c0000000-0000-0000-0000-000000000006',
  'a0000000-0000-0000-0000-000000000002',
  'waitlisted',
  1,
  '2026-09-01 00:00:00+00'
);
set local role authenticated;
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000001';
select is(
  (select version
   from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000006')),
  'outdoor-v1',
  'the first member acknowledges before claiming the waitlist test place'
);
select is(
  (select registration_status::text
   from public.register_for_event('c0000000-0000-0000-0000-000000000006')),
  'confirmed',
  'the first member claims the waitlist test event place'
);
select is(
  (select promoted_registration_id is null
   from public.cancel_event_registration('c0000000-0000-0000-0000-000000000006')),
  true,
  'an unacknowledged waitlisted member is not promoted'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000005';
select is(
  (select status::text
   from public.event_registrations
   where event_id = 'c0000000-0000-0000-0000-000000000006'
     and user_id = 'a0000000-0000-0000-0000-000000000002'),
  'waitlisted',
  'the unacknowledged waitlisted member remains queued'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000002';
select lives_ok(
  $$select * from public.record_event_waiver_acknowledgement('c0000000-0000-0000-0000-000000000006')$$,
  'a waitlisted member can acknowledge before promotion'
);
set local "request.jwt.claim.sub" = 'a0000000-0000-0000-0000-000000000005';
select lives_ok(
  $$update public.events set capacity = 2 where id = 'c0000000-0000-0000-0000-000000000006'$$,
  'capacity reconciliation reevaluates waiver-complete waitlist members'
);
select is(
  (select status::text
   from public.event_registrations
   where event_id = 'c0000000-0000-0000-0000-000000000006'
     and user_id = 'a0000000-0000-0000-0000-000000000002'),
  'confirmed',
  'waiver acknowledgement allows waitlist promotion after reconciliation'
);

select * from finish();

rollback;
