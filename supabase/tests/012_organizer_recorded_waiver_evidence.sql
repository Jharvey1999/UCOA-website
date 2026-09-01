begin;

select plan(28);

insert into auth.users (id, email)
values
  ('f0000000-0000-0000-0000-000000000001', 'evidence-host@example.test'),
  ('f0000000-0000-0000-0000-000000000002', 'evidence-executive@example.test'),
  ('f0000000-0000-0000-0000-000000000003', 'evidence-member@example.test'),
  ('f0000000-0000-0000-0000-000000000004', 'evidence-other-organizer@example.test'),
  ('f0000000-0000-0000-0000-000000000005', 'evidence-pending@example.test'),
  ('f0000000-0000-0000-0000-000000000006', 'evidence-expired@example.test'),
  ('f0000000-0000-0000-0000-000000000007', 'evidence-second-member@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  ('f0000000-0000-0000-0000-000000000001', '2020-09-01', '2099-08-31', 'active', '2020-09-01 00:00:00+00'),
  ('f0000000-0000-0000-0000-000000000002', '2020-09-01', '2099-08-31', 'active', '2020-09-01 00:00:00+00'),
  ('f0000000-0000-0000-0000-000000000003', '2020-09-01', '2099-08-31', 'active', '2020-09-01 00:00:00+00'),
  ('f0000000-0000-0000-0000-000000000004', '2020-09-01', '2099-08-31', 'active', '2020-09-01 00:00:00+00'),
  ('f0000000-0000-0000-0000-000000000005', null, null, 'pending', null),
  ('f0000000-0000-0000-0000-000000000006', '2020-09-01', '2025-08-31', 'expired', '2020-09-01 00:00:00+00'),
  ('f0000000-0000-0000-0000-000000000007', '2020-09-01', '2099-08-31', 'active', '2020-09-01 00:00:00+00');

insert into public.membership_admin (membership_id, approved_by)
select id, 'f0000000-0000-0000-0000-000000000002'
from public.memberships
where user_id in (
  'f0000000-0000-0000-0000-000000000001',
  'f0000000-0000-0000-0000-000000000002',
  'f0000000-0000-0000-0000-000000000003',
  'f0000000-0000-0000-0000-000000000004',
  'f0000000-0000-0000-0000-000000000006',
  'f0000000-0000-0000-0000-000000000007'
);

insert into public.user_roles (user_id, role, assigned_by)
values
  ('f0000000-0000-0000-0000-000000000001', 'organizer', 'f0000000-0000-0000-0000-000000000002'),
  ('f0000000-0000-0000-0000-000000000002', 'executive', 'f0000000-0000-0000-0000-000000000001'),
  ('f0000000-0000-0000-0000-000000000004', 'organizer', 'f0000000-0000-0000-0000-000000000002'),
  ('f0000000-0000-0000-0000-000000000005', 'organizer', 'f0000000-0000-0000-0000-000000000002'),
  ('f0000000-0000-0000-0000-000000000006', 'organizer', 'f0000000-0000-0000-0000-000000000002');

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
    'f1000000-0000-0000-0000-000000000001',
    'organizer-evidence-test-v1',
    'organizer_recorded',
    'ucoa://waivers/organizer-evidence-test-v1',
    'approved',
    'f0000000-0000-0000-0000-000000000002',
    '2026-08-31 00:00:00+00'
  ),
  (
    'f1000000-0000-0000-0000-000000000002',
    'built-in-evidence-test-v1',
    'built_in',
    'ucoa://waivers/built-in-evidence-test-v1',
    'approved',
    'f0000000-0000-0000-0000-000000000002',
    '2026-08-31 00:00:00+00'
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
  ('f2000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'Organizer evidence event', 'Evidence workflow test event.', '2026-10-01 14:00:00+00', '2026-10-01 16:00:00+00', 'America/Edmonton', 'hike', 'members_only', 'published'),
  ('f2000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000001', 'Second evidence event', 'Second evidence workflow test event.', '2026-10-02 14:00:00+00', '2026-10-02 16:00:00+00', 'America/Edmonton', 'hike', 'members_only', 'published'),
  ('f2000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000001', 'Built-in evidence event', 'Built-in workflow mismatch test event.', '2026-10-03 14:00:00+00', '2026-10-03 16:00:00+00', 'America/Edmonton', 'social', 'members_only', 'published'),
  ('f2000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000001', 'Cancelled evidence event', 'Cancelled workflow test event.', '2026-10-04 14:00:00+00', '2026-10-04 16:00:00+00', 'America/Edmonton', 'social', 'members_only', 'cancelled');

insert into public.event_private_details (event_id, member_description, waiver_required, waiver_id)
values
  ('f2000000-0000-0000-0000-000000000001', 'Private evidence event details.', true, 'f1000000-0000-0000-0000-000000000001'),
  ('f2000000-0000-0000-0000-000000000002', 'Private second event details.', true, 'f1000000-0000-0000-0000-000000000001'),
  ('f2000000-0000-0000-0000-000000000003', 'Private built-in event details.', true, 'f1000000-0000-0000-0000-000000000002'),
  ('f2000000-0000-0000-0000-000000000004', 'Private cancelled event details.', true, 'f1000000-0000-0000-0000-000000000001');

insert into public.event_hosts (event_id, user_id, assigned_by)
values
  ('f2000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002'),
  ('f2000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002'),
  ('f2000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002'),
  ('f2000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000002');

insert into public.event_registrations (
  id,
  event_id,
  user_id,
  status,
  waitlist_position,
  queued_at
)
values
  ('f3000000-0000-0000-0000-000000000001', 'f2000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000003', 'confirmed', null, null),
  ('f3000000-0000-0000-0000-000000000002', 'f2000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000007', 'waitlisted', 1, '2026-09-01 00:00:00+00'),
  ('f3000000-0000-0000-0000-000000000003', 'f2000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003', 'confirmed', null, null),
  ('f3000000-0000-0000-0000-000000000004', 'f2000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000007', 'confirmed', null, null),
  ('f3000000-0000-0000-0000-000000000005', 'f2000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000003', 'confirmed', null, null),
  ('f3000000-0000-0000-0000-000000000006', 'f2000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000003', 'confirmed', null, null);

select is(
  has_function_privilege('anon', 'public.record_event_waiver_evidence(uuid, uuid, text)', 'execute'),
  false,
  'anonymous users cannot execute organizer-recorded evidence'
);
select is(
  has_function_privilege('authenticated', 'public.record_event_waiver_evidence(uuid, uuid, text)', 'execute'),
  true,
  'authenticated users can execute organizer-recorded evidence'
);

set local role anon;
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000001',
      'paper-form-001'
    )$$,
  '42501',
  null,
  'anonymous users cannot record organizer evidence'
);

set local role authenticated;
set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000005';
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000001',
      'paper-form-001'
    )$$,
  '42501',
  null,
  'pending organizers cannot record organizer evidence'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000006';
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000001',
      'paper-form-001'
    )$$,
  '42501',
  null,
  'expired organizers cannot record organizer evidence'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000003';
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000001',
      'paper-form-001'
    )$$,
  '42501',
  null,
  'members cannot record organizer evidence'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000004';
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000001',
      'paper-form-001'
    )$$,
  '42501',
  null,
  'non-host organizers cannot record organizer evidence'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000001';
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000003',
      'paper-form-001'
    )$$,
  'P0001',
  'waiver evidence unavailable',
  'a registration from another event cannot be targeted'
);
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000002',
      'paper-form-001'
    )$$,
  'P0001',
  'waiver evidence unavailable',
  'waitlisted members cannot receive organizer evidence'
);
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000001',
      'f3000000-0000-0000-0000-000000000001',
      '   '
    )$$,
  '22023',
  'waiver evidence reference is invalid',
  'blank evidence references are rejected'
);
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000003',
      'f3000000-0000-0000-0000-000000000005',
      'paper-form-001'
    )$$,
  'P0001',
  'approved waiver workflow is not organizer-recorded',
  'built-in waivers cannot use organizer evidence'
);
select throws_ok(
  $$select * from public.record_event_waiver_evidence(
      'f2000000-0000-0000-0000-000000000004',
      'f3000000-0000-0000-0000-000000000006',
      'paper-form-001'
    )$$,
  'P0001',
  'event waiver unavailable',
  'cancelled events cannot receive organizer evidence'
);
select throws_ok(
  $$insert into public.waiver_acknowledgements (
      event_id,
      waiver_id,
      user_id,
      evidence_reference
    ) values (
      'f2000000-0000-0000-0000-000000000001',
      'f1000000-0000-0000-0000-000000000001',
      'f0000000-0000-0000-0000-000000000003',
      'paper-form-001'
    )$$,
  '42501',
  null,
  'hosts cannot bypass the organizer evidence RPC with a direct insert'
);

select is(
  (select registration_id from public.record_event_waiver_evidence(
    'f2000000-0000-0000-0000-000000000001',
    'f3000000-0000-0000-0000-000000000001',
    'paper-form-001'
  )),
  'f3000000-0000-0000-0000-000000000001',
  'the event host receives the targeted registration ID'
);
select is(
  (select status::text from public.waiver_acknowledgements
   where event_id = 'f2000000-0000-0000-0000-000000000001'
     and user_id = 'f0000000-0000-0000-0000-000000000003'),
  'acknowledged',
  'organizer evidence creates an acknowledged record'
);
select is(
  (select evidence_reference from public.waiver_acknowledgements
   where event_id = 'f2000000-0000-0000-0000-000000000001'
     and user_id = 'f0000000-0000-0000-0000-000000000003'),
  'paper-form-001',
  'organizer evidence stores the supplied reference'
);
select is(
  (select waiver_acknowledgement_method::text
   from public.list_event_attendance('f2000000-0000-0000-0000-000000000001')
   where registration_id = 'f3000000-0000-0000-0000-000000000001'),
  'organizer_recorded',
  'the manager roster reports the assigned organizer-recorded method'
);
select is(
  (select waiver_acknowledgement_status::text
   from public.list_event_attendance('f2000000-0000-0000-0000-000000000001')
   where registration_id = 'f3000000-0000-0000-0000-000000000001'),
  'acknowledged',
  'the manager roster reports recorded organizer evidence'
);
select is(
  (select count(*) from public.waiver_acknowledgements
   where event_id = 'f2000000-0000-0000-0000-000000000001'
     and user_id = 'f0000000-0000-0000-0000-000000000003'),
  1::bigint,
  'recording organizer evidence creates one versioned acknowledgement'
);

set local role postgres;
select is(
  (select count(*) from public.audit_log
   where entity_type = 'waiver_acknowledgement'
     and action = 'waiver_acknowledgement.created'
     and entity_id in (
       select id from public.waiver_acknowledgements
       where event_id = 'f2000000-0000-0000-0000-000000000001'
         and user_id = 'f0000000-0000-0000-0000-000000000003'
     )),
  1::bigint,
  'organizer evidence writes a safe acknowledgement audit record'
);

set local role authenticated;
set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000001';
select is(
  (select version from public.record_event_waiver_evidence(
    'f2000000-0000-0000-0000-000000000001',
    'f3000000-0000-0000-0000-000000000001',
    'paper-form-001-corrected'
  )),
  'organizer-evidence-test-v1',
  'recording evidence again is idempotent for the assigned version'
);
select is(
  (select count(*) from public.waiver_acknowledgements
   where event_id = 'f2000000-0000-0000-0000-000000000001'
     and user_id = 'f0000000-0000-0000-0000-000000000003'),
  1::bigint,
  're-recording evidence does not create a duplicate acknowledgement'
);
select is(
  (select evidence_reference from public.waiver_acknowledgements
   where event_id = 'f2000000-0000-0000-0000-000000000001'
     and user_id = 'f0000000-0000-0000-0000-000000000003'),
  'paper-form-001-corrected',
  're-recording evidence updates the opaque reference'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000003';
select throws_ok(
  $$select * from public.register_for_event('f2000000-0000-0000-0000-000000000002')$$,
  'P0001',
  'approved waiver completion is required before registration',
  'a member without organizer evidence cannot register'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000001';
select is(
  (select version from public.record_event_waiver_evidence(
    'f2000000-0000-0000-0000-000000000002',
    'f3000000-0000-0000-0000-000000000003',
    'paper-form-002'
  )),
  'organizer-evidence-test-v1',
  'the host can record evidence for a second event'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000003';
select is(
  (select registration_status::text
   from public.register_for_event('f2000000-0000-0000-0000-000000000002')),
  'confirmed',
  'a member can register after organizer evidence is recorded'
);

set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000002';
select is(
  (select version from public.record_event_waiver_evidence(
    'f2000000-0000-0000-0000-000000000002',
    'f3000000-0000-0000-0000-000000000004',
    'paper-form-003'
  )),
  'organizer-evidence-test-v1',
  'an executive can record organizer evidence'
);
select is(
  (select waiver_acknowledgement_status::text
   from public.list_event_attendance('f2000000-0000-0000-0000-000000000002')
   where registration_id = 'f3000000-0000-0000-0000-000000000004'),
  'acknowledged',
  'the roster reports executive-recorded evidence'
);

select * from finish();

rollback;