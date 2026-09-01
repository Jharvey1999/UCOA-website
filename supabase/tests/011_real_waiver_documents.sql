begin;

select plan(25);

insert into auth.users (id, email)
values
  ('d0000000-0000-0000-0000-000000000001', 'real-waiver-member@example.test'),
  ('d0000000-0000-0000-0000-000000000002', 'real-waiver-pending@example.test'),
  ('d0000000-0000-0000-0000-000000000003', 'real-waiver-executive@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    'd0000000-0000-0000-0000-000000000001',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    'd0000000-0000-0000-0000-000000000002',
    null,
    null,
    'pending',
    null
  ),
  (
    'd0000000-0000-0000-0000-000000000003',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  );

insert into public.membership_admin (membership_id, approved_by)
select id, 'd0000000-0000-0000-0000-000000000003'
from public.memberships
where user_id in (
  'd0000000-0000-0000-0000-000000000001',
  'd0000000-0000-0000-0000-000000000003'
);

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    'd0000000-0000-0000-0000-000000000001',
    'member',
    'd0000000-0000-0000-0000-000000000003'
  ),
  (
    'd0000000-0000-0000-0000-000000000003',
    'executive',
    'd0000000-0000-0000-0000-000000000001'
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
  status
)
values (
  'e0000000-0000-0000-0000-000000000001',
  'd0000000-0000-0000-0000-000000000003',
  'Real waiver document event',
  'A published event for the real waiver document boundary.',
  '2026-10-10 14:00:00+00',
  '2026-10-10 16:00:00+00',
  'hike',
  'members_only',
  'published'
);

insert into public.event_private_details (
  event_id,
  member_description,
  waiver_required,
  waiver_id
)
values (
  'e0000000-0000-0000-0000-000000000001',
  'Private details for the real waiver document event.',
  true,
  (select id from public.waivers where version = '2025-2026-provincial')
);

insert into storage.objects (bucket_id, name, owner_id, metadata)
values
  (
    'waiver-documents',
    'waivers/2025-2026/provincial.pdf',
    'd0000000-0000-0000-0000-000000000003',
    '{"mimetype":"application/pdf","size":59968}'::jsonb
  ),
  (
    'waiver-documents',
    'waivers/2025-2026/national.pdf',
    'd0000000-0000-0000-0000-000000000003',
    '{"mimetype":"application/pdf","size":59708}'::jsonb
  )
on conflict (bucket_id, name) do update
set owner_id = excluded.owner_id,
    metadata = excluded.metadata;

set local role postgres;
select is(
  (select public from storage.buckets where id = 'waiver-documents'),
  false,
  'real waiver documents use a private bucket'
);
select is(
  (select file_size_limit from storage.buckets where id = 'waiver-documents'),
  5242880::bigint,
  'real waiver documents have a five megabyte limit'
);
select is(
  (select allowed_mime_types @> array['application/pdf']::text[]
   from storage.buckets
   where id = 'waiver-documents'),
  true,
  'real waiver documents accept PDF files'
);
select is(
  (select count(*) from public.waivers
   where version in ('2025-2026-provincial', '2025-2026-national')),
  2::bigint,
  'both supplied waiver forms have version records'
);
select is(
  (select acknowledgement_method::text
   from public.waivers
   where version = '2025-2026-provincial'),
  'organizer_recorded',
  'the provincial form uses organizer-recorded completion'
);
select is(
  (select acknowledgement_method::text
   from public.waivers
   where version = '2025-2026-national'),
  'organizer_recorded',
  'the national form uses organizer-recorded completion'
);
select is(
  (select count(*) from public.waivers
   where version in ('2025-2026-provincial', '2025-2026-national')
     and status = 'draft'),
  2::bigint,
  'real waiver forms remain drafts until UCOA approval'
);
select is(
  (select document_reference
   from public.waivers
   where version = '2025-2026-provincial'),
  'waivers/2025-2026/provincial.pdf',
  'the provincial form has a canonical private object path'
);
select is(
  (select document_reference
   from public.waivers
   where version = '2025-2026-national'),
  'waivers/2025-2026/national.pdf',
  'the national form has a canonical private object path'
);

set local role anon;
select is(
  (select count(*) from storage.objects where bucket_id = 'waiver-documents'),
  0::bigint,
  'anonymous users cannot read real waiver documents'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('waiver-documents', 'waivers/2025-2026/provincial.pdf')$$,
  '42501',
  null,
  'anonymous users cannot upload real waiver documents'
);

set local role authenticated;
set local "request.jwt.claim.sub" = 'd0000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from public.waivers
   where version = '2025-2026-provincial'),
  0::bigint,
  'active members cannot read draft real waiver metadata'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'waiver-documents'
     and name = 'waivers/2025-2026/provincial.pdf'),
  0::bigint,
  'active members cannot read an unapproved real waiver document'
);
select is(
  (select document_reference
   from public.get_event_waiver_status('e0000000-0000-0000-0000-000000000001')),
  null::text,
  'draft real waiver assignments do not expose their document path to members'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('e0000000-0000-0000-0000-000000000001')$$,
  'P0001',
  'approved waiver unavailable',
  'members cannot acknowledge an unapproved real waiver'
);

set local role postgres;
update public.waivers
set status = 'approved',
    approved_by = 'd0000000-0000-0000-0000-000000000003',
    approved_at = '2026-09-01 00:00:00+00'
where version in ('2025-2026-provincial', '2025-2026-national');

set local role authenticated;
set local "request.jwt.claim.sub" = 'd0000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from storage.objects
   where bucket_id = 'waiver-documents'
     and name = 'waivers/2025-2026/provincial.pdf'),
  1::bigint,
  'an active member can read an assigned approved real waiver document'
);
select is(
  (select document_reference
   from public.get_event_waiver_status('e0000000-0000-0000-0000-000000000001')),
  'waivers/2025-2026/provincial.pdf',
  'an assigned member receives only the approved document reference'
);
select is(
  (select acknowledgement_method::text
   from public.get_event_waiver_status('e0000000-0000-0000-0000-000000000001')),
  'organizer_recorded',
  'an assigned member sees the organizer-recorded completion method'
);
select throws_ok(
  $$select * from public.record_event_waiver_acknowledgement('e0000000-0000-0000-0000-000000000001')$$,
  'P0001',
  'approved waiver workflow is external',
  'the real organizer-recorded form cannot use built-in acknowledgement'
);
select throws_ok(
  $$select * from public.register_for_event('e0000000-0000-0000-0000-000000000001')$$,
  'P0001',
  'approved waiver completion is required before registration',
  'the real organizer-recorded form keeps RSVP fail-closed'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'waiver-documents'
     and name = 'waivers/2025-2026/national.pdf'),
  0::bigint,
  'an approved but unassigned real waiver document remains hidden'
);

set local "request.jwt.claim.sub" = 'd0000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from storage.objects where bucket_id = 'waiver-documents'),
  0::bigint,
  'pending users cannot read real waiver documents'
);
select throws_ok(
  $$delete from storage.objects
    where bucket_id = 'waiver-documents'
      and name = 'waivers/2025-2026/provincial.pdf'$$,
  '42501',
  null,
  'pending users cannot delete real waiver documents'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('waiver-documents', 'waivers/2025-2026/provincial.pdf')$$,
  '42501',
  null,
  'pending users cannot upload real waiver documents'
);

set local "request.jwt.claim.sub" = 'd0000000-0000-0000-0000-000000000003';
select is(
  (select count(*) from storage.objects where bucket_id = 'waiver-documents'),
  2::bigint,
  'executives can inspect both real waiver documents'
);

select * from finish();

rollback;