begin;

select plan(87);

insert into auth.users (id, email)
values
  ('14000000-0000-0000-0000-000000000001', 'directory-member@example.test'),
  ('14000000-0000-0000-0000-000000000002', 'directory-executive@example.test'),
  ('14000000-0000-0000-0000-000000000003', 'directory-pending@example.test'),
  ('14000000-0000-0000-0000-000000000005', 'directory-organizer@example.test'),
  ('14000000-0000-0000-0000-000000000006', 'directory-expired@example.test');

insert into auth.users (id, email, raw_user_meta_data)
values
  (
    '14000000-0000-0000-0000-000000000004',
    'directory-trigger@example.test',
    '{"first_name":"Trigger","last_name":"Account","phone_number":"403-555-0140","student_id":"T-1404","affiliation":"UCalgary","emergency_contact_name":"Trigger Contact","emergency_contact_phone":"403-555-0144","emergency_contact_consent_to_share":true}'::jsonb
  ),
  (
    '14000000-0000-0000-0000-000000000007',
    'directory-no-consent@example.test',
    '{"first_name":"No","last_name":"Consent","emergency_contact_name":"Hidden Contact","emergency_contact_phone":"403-555-0147","emergency_contact_consent_to_share":false}'::jsonb
  );

insert into public.profiles (
  id,
  first_name,
  last_name,
  last_name_initial,
  display_name,
  student_id,
  phone_number,
  emergency_contact_name,
  emergency_contact_phone,
  emergency_contact_consent_to_share
)
values
  (
    '14000000-0000-0000-0000-000000000001',
    'Directory',
    'Member',
    'M',
    'Directory Member',
    'D-1401',
    '403-555-0141',
    'Emergency Member',
    '403-555-0142',
    true
  ),
  ('14000000-0000-0000-0000-000000000002', 'Directory', 'Executive', 'E', 'Directory Executive', null, null, null, null, false),
  ('14000000-0000-0000-0000-000000000003', 'Directory', 'Pending', 'P', 'Directory Pending', null, null, null, null, false),
  ('14000000-0000-0000-0000-000000000005', 'Directory', 'Organizer', 'O', 'Directory Organizer', null, null, null, null, false);

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  date_joined,
  approved_at
)
values
  (
    '14000000-0000-0000-0000-000000000001',
    '2026-09-01',
    '2027-08-31',
    'active',
    '2026-09-05',
    '2026-09-05 00:00:00+00'
  ),
  (
    '14000000-0000-0000-0000-000000000002',
    '2026-09-01',
    '2027-08-31',
    'active',
    '2026-09-01',
    '2026-09-01 00:00:00+00'
  ),
  (
    '14000000-0000-0000-0000-000000000003',
    null,
    null,
    'pending',
    null,
    null
  ),
  (
    '14000000-0000-0000-0000-000000000005',
    '2026-09-01',
    '2027-08-31',
    'active',
    '2026-09-02',
    '2026-09-02 00:00:00+00'
  ),
  (
    '14000000-0000-0000-0000-000000000006',
    '2025-09-01',
    '2026-08-31',
    'expired',
    '2025-09-02',
    '2025-09-02 00:00:00+00'
  );

insert into public.membership_admin (
  membership_id,
  approved_by,
  payment_verified_at,
  payment_verified_by,
  probation,
  acc_member,
  added_to_email_list,
  directory_notes
)
select
  memberships.id,
  '14000000-0000-0000-0000-000000000002',
  case when memberships.user_id = '14000000-0000-0000-0000-000000000001' then '2026-09-05 00:00:00+00'::timestamptz else null end,
  case when memberships.user_id = '14000000-0000-0000-0000-000000000001' then '14000000-0000-0000-0000-000000000002'::uuid else null end,
  memberships.user_id = '14000000-0000-0000-0000-000000000001',
  memberships.user_id = '14000000-0000-0000-0000-000000000001',
  memberships.user_id = '14000000-0000-0000-0000-000000000001',
  case when memberships.user_id = '14000000-0000-0000-0000-000000000001' then 'AST1; two no shows' else null end
from public.memberships
where memberships.user_id in (
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-000000000002',
  '14000000-0000-0000-0000-000000000005'
);

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '14000000-0000-0000-0000-000000000001',
    'member',
    '14000000-0000-0000-0000-000000000002'
  ),
  (
    '14000000-0000-0000-0000-000000000002',
    'executive',
    '14000000-0000-0000-0000-000000000001'
  ),
  (
    '14000000-0000-0000-0000-000000000005',
    'organizer',
    '14000000-0000-0000-0000-000000000002'
  );

insert into public.waivers (
  id,
  version,
  acknowledgement_method,
  document_reference,
  status,
  member_downloadable,
  approved_by,
  approved_at
)
values (
  '14000000-0000-0000-0000-000000000101',
  'directory-test-blanket-v1',
  'organizer_recorded',
  'waivers/2026-2027/directory-test-blanket.pdf',
  'approved',
  true,
  '14000000-0000-0000-0000-000000000002',
  '2026-09-06 00:00:00+00'
);

insert into storage.objects (bucket_id, name, owner_id, metadata)
values
  (
    'signed-waivers',
    'signed-waivers/14000000-0000-0000-0000-000000000005/14000000-0000-0000-0000-000000000101/organizer-signed.pdf',
    '14000000-0000-0000-0000-000000000005',
    '{"mimetype":"application/pdf","size":1234}'::jsonb
  );

insert into public.signed_waivers (
  id,
  waiver_id,
  user_id,
  object_path
)
values (
  '14000000-0000-0000-0000-000000000201',
  '14000000-0000-0000-0000-000000000101',
  '14000000-0000-0000-0000-000000000005',
  'signed-waivers/14000000-0000-0000-0000-000000000005/14000000-0000-0000-0000-000000000101/organizer-signed.pdf'
);

insert into storage.objects (bucket_id, name, owner_id, metadata)
values (
  'signed-waivers',
  'signed-waivers/14000000-0000-0000-0000-000000000006/14000000-0000-0000-0000-000000000101/expired-signed.pdf',
  '14000000-0000-0000-0000-000000000006',
  '{"mimetype":"application/pdf","size":3456}'::jsonb
);

insert into public.signed_waivers (
  id,
  waiver_id,
  user_id,
  object_path
)
values (
  '14000000-0000-0000-0000-000000000202',
  '14000000-0000-0000-0000-000000000101',
  '14000000-0000-0000-0000-000000000006',
  'signed-waivers/14000000-0000-0000-0000-000000000006/14000000-0000-0000-0000-000000000101/expired-signed.pdf'
);

set local role postgres;
select is(
  (select first_name from public.profiles
   where id = '14000000-0000-0000-0000-000000000004'),
  'Trigger',
  'the auth profile trigger stores the signup first name'
);
select is(
  (select emergency_contact_name from public.profiles
   where id = '14000000-0000-0000-0000-000000000004'),
  'Trigger Contact',
  'the auth profile trigger stores the emergency contact name'
);
select is(
  (select emergency_contact_consent_to_share from public.profiles
   where id = '14000000-0000-0000-0000-000000000004'),
  true,
  'the auth profile trigger stores emergency-contact consent'
);
select is(
  (select emergency_contact_name from public.profiles
   where id = '14000000-0000-0000-0000-000000000007'),
  null::text,
  'the auth profile trigger discards an unconsented emergency contact'
);
select is(
  (select emergency_contact_phone from public.profiles
   where id = '14000000-0000-0000-0000-000000000007'),
  null::text,
  'the auth profile trigger discards an unconsented emergency phone'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
update public.profiles
set emergency_contact_name = 'Revoked Contact',
    emergency_contact_phone = '403-555-0199',
    emergency_contact_consent_to_share = false
where id = '14000000-0000-0000-0000-000000000001';
select is(
  (select emergency_contact_name from public.profiles
   where id = '14000000-0000-0000-0000-000000000001'),
  null::text,
  'revoking emergency-contact consent clears the stored contact name'
);
select is(
  (select emergency_contact_phone from public.profiles
   where id = '14000000-0000-0000-0000-000000000001'),
  null::text,
  'revoking emergency-contact consent clears the stored contact phone'
);
set local role postgres;
select is(
  (select count(*) from public.audit_log
   where action = 'signed_waiver.submitted'
     and entity_id = '14000000-0000-0000-0000-000000000201'),
  1::bigint,
  'signed waiver inserts create submitted audit records'
);

set local role anon;
set local "request.jwt.claim.sub" = '';
select throws_ok(
  $$select * from public.export_member_directory(
    '14000000-0000-0000-0000-000000000001',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    null,
    null
  )$$,
  '42501',
  null,
  'anonymous users cannot execute the member export'
);
select throws_ok(
  $$select * from public.list_signed_waiver_exports(null, null)$$,
  '42501',
  null,
  'anonymous users cannot execute the signed waiver export'
);
select throws_ok(
  $$select count(*) from public.signed_waivers$$,
  '42501',
  null,
  'anonymous users cannot read signed waiver metadata'
);
select throws_ok(
  $$select public.can_current_user_submit_signed_waiver()$$,
  '42501',
  null,
  'anonymous users cannot execute the signed waiver membership preflight'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select throws_ok(
  $$select * from public.export_member_directory(
    '14000000-0000-0000-0000-000000000001',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    null,
    null
  )$$,
  '42501',
  null,
  'members cannot execute the member export'
);
select is(
  (select public.can_current_user_submit_signed_waiver()),
  true,
  'active members pass the signed waiver membership preflight'
);
select throws_ok(
  $$insert into public.signed_waivers (waiver_id, user_id, object_path)
    values ('14000000-0000-0000-0000-000000000101', '14000000-0000-0000-0000-000000000001',
      'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/direct.pdf')$$,
  '42501',
  null,
  'members cannot insert signed waiver metadata directly'
);
select is(
  (select count(*) from public.signed_waivers
   where user_id = '14000000-0000-0000-0000-000000000005'),
  0::bigint,
  'members cannot see another users signed waiver metadata'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'signed-waivers'
     and name like 'signed-waivers/14000000-0000-0000-0000-000000000005/%'),
  0::bigint,
  'members cannot read another users signed waiver object'
);

set local role postgres;
insert into storage.objects (bucket_id, name, owner_id, metadata)
values (
  'signed-waivers',
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/member-signed.pdf',
  null,
  '{"mimetype":"application/pdf","size":2345,"ucoa_user_id":"14000000-0000-0000-0000-000000000001"}'::jsonb
);

set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select is(
  (select status::text from public.submit_signed_waiver(
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/member-signed.pdf'
  )),
  'submitted',
  'members can submit a server-uploaded signed waiver through the narrow RPC'
);
select is(
  (select count(*) from public.signed_waivers
   where user_id = '14000000-0000-0000-0000-000000000001'),
  1::bigint,
  'a signed waiver submission creates one metadata row'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'signed-waivers'
     and name like 'signed-waivers/14000000-0000-0000-0000-000000000001/%'),
  1::bigint,
  'members can read their own signed waiver object after submission'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values ('signed-waivers',
      'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/direct.pdf',
      '14000000-0000-0000-0000-000000000001',
      '{"mimetype":"application/pdf","size":25,"ucoa_user_id":"14000000-0000-0000-0000-000000000001"}'::jsonb)$$,
  '42501',
  null,
  'members cannot insert signed waiver objects directly through Storage'
);
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from storage.objects
   where bucket_id = 'signed-waivers'
     and name = 'signed-waivers/14000000-0000-0000-0000-000000000005/14000000-0000-0000-0000-000000000101/organizer-signed.pdf'),
  0::bigint,
  'executives cannot bypass the signed-waiver download route through Storage'
);
set local role postgres;
insert into storage.objects (bucket_id, name, owner_id, metadata)
values (
  'signed-waivers',
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/orphan.pdf',
  null,
  '{"mimetype":"application/pdf","size":25,"ucoa_user_id":"14000000-0000-0000-0000-000000000001"}'::jsonb
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from storage.objects
   where bucket_id = 'signed-waivers'
     and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/orphan.pdf'),
  0::bigint,
  'unreferenced route-owned signed waiver objects are not readable'
);
set local storage.allow_delete_query = 'true';
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'signed-waivers'
      and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/orphan.pdf'$$,
  'active members can delete an unreferenced route-owned signed waiver object'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'signed-waivers'
     and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/orphan.pdf'),
  0::bigint,
  'the unreferenced signed waiver object is deleted'
);
set local role postgres;
insert into storage.objects (bucket_id, name, owner_id, metadata, created_at)
values (
  'signed-waivers',
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf',
  null,
  '{"mimetype":"application/pdf","size":25,"ucoa_user_id":"14000000-0000-0000-0000-000000000001"}'::jsonb,
  now() - interval '2 days'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select throws_ok(
  $$select * from public.list_signed_waiver_orphans(now(), 100)$$,
  '42501',
  'signed waiver cleanup unavailable',
  'members cannot enumerate signed waiver orphans'
);
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from public.list_signed_waiver_orphans(now(), 100)
   where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'),
  1::bigint,
  'executives can enumerate only unreferenced signed waiver paths for cleanup'
);
select is(
  (select public.claim_signed_waiver_orphan(
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf',
    now()
  )),
  true,
  'executives can claim an orphan before Storage deletion'
);
select is(
  (select public.claim_signed_waiver_orphan(
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf',
    now()
  )),
  false,
  'a second cleanup request cannot acquire an active claim'
);
select is(
  (select count(*) from public.list_signed_waiver_orphans(now(), 100)
   where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'),
  0::bigint,
  'active cleanup claims are excluded from concurrent cleanup lists'
);
select is(
  (select metadata ->> 'object_path' from public.audit_log
   where actor_id = '14000000-0000-0000-0000-000000000002'
     and action = 'signed_waiver.cleanup_claimed'
   order by created_at desc
   limit 1),
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf',
  'cleanup claim audit records the exact object path'
);
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select throws_ok(
  $$select * from public.submit_signed_waiver(
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'
  )$$,
  'P0001',
  'signed waiver unavailable',
  'members cannot reclaim a cleanup-claimed signed waiver path'
);
set local role postgres;
update private.signed_waiver_cleanup_claims
set claimed_at = clock_timestamp() - interval '2 hours'
where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf';
update storage.objects
set metadata = '{"mimetype":"application/pdf","size":25,"ucoa_user_id":"14000000-0000-0000-0000-000000000005"}'::jsonb
where bucket_id = 'signed-waivers'
  and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf';
set local role authenticated;
set local "request.jwt.claim.role" = 'authenticated';
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select public.claim_signed_waiver_orphan(
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf',
    now()
  )),
  false,
  'stale claims cannot be renewed when object ownership metadata no longer matches'
);
set local role postgres;
update storage.objects
set metadata = '{"mimetype":"application/pdf","size":25,"ucoa_user_id":"14000000-0000-0000-0000-000000000001"}'::jsonb
where bucket_id = 'signed-waivers'
  and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf';
set local role authenticated;
set local "request.jwt.claim.role" = 'authenticated';
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from public.list_signed_waiver_orphans(now(), 100)
   where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'),
  1::bigint,
  'stale cleanup claims are listed for retry while the object remains'
);
select is(
  (select public.claim_signed_waiver_orphan(
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf',
    now()
  )),
  true,
  'executives can reacquire a stale cleanup claim while the object remains'
);
set local role postgres;
delete from storage.objects
where bucket_id = 'signed-waivers'
  and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf';
update private.signed_waiver_cleanup_claims
set claimed_at = clock_timestamp() - interval '2 hours'
where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf';
set local role authenticated;
set local "request.jwt.claim.role" = 'authenticated';
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from public.list_signed_waiver_orphans(now(), 100)
   where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'),
  1::bigint,
  'stale cleanup claims are listed for retry after the object is gone'
);
select is(
  (select public.claim_signed_waiver_orphan(
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf',
    now()
  )),
  true,
  'executives can reacquire a stale cleanup claim after the object is gone'
);
set local role postgres;
update private.signed_waiver_cleanup_claims
set claimed_by = '14000000-0000-0000-0000-000000000001'
where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf';
set local role service_role;
set local "request.jwt.claim.role" = 'service_role';
select throws_ok(
  $$select public.audit_signed_waiver_cleanup(
    '14000000-0000-0000-0000-000000000002',
    array['signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'],
    now()
  )$$,
  '42501',
  'signed waiver cleanup unavailable',
  'cleanup audit rejects a claim reassigned to another actor'
);
set local role postgres;
update private.signed_waiver_cleanup_claims
set claimed_by = '14000000-0000-0000-0000-000000000002'
where object_path = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf';
set local role service_role;
select throws_ok(
  $$select public.audit_signed_waiver_cleanup(
    '14000000-0000-0000-0000-000000000002',
    array['signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'],
    now() - interval '1 second'
  )$$,
  '42501',
  'signed waiver cleanup unavailable',
  'cleanup audit rejects a mismatched cutoff'
);
select lives_ok(
  $$select public.audit_signed_waiver_cleanup(
    '14000000-0000-0000-0000-000000000002',
    array['signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf'],
    now()
  )$$,
  'service role can finalize cleanup for its claimed paths'
);
set local role postgres;
select is(
  (select metadata -> 'object_paths' from public.audit_log
   where actor_id = '14000000-0000-0000-0000-000000000002'
     and action = 'signed_waiver.cleaned_up'
   order by created_at desc
   limit 1),
  to_jsonb(array['signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/cleanup-orphan.pdf']::text[]),
  'cleanup completion audit records the exact object paths'
);
set local role authenticated;
set local "request.jwt.claim.role" = 'authenticated';
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select lives_ok(
  $$update storage.objects
    set metadata = '{"mimetype":"application/pdf","size":26}'::jsonb
    where bucket_id = 'signed-waivers'
      and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/member-signed.pdf'$$,
  'members cannot update a recorded signed waiver object'
);
select is(
  (select metadata ->> 'ucoa_user_id' from storage.objects
   where bucket_id = 'signed-waivers'
     and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/member-signed.pdf'),
  '14000000-0000-0000-0000-000000000001',
  'recorded signed waiver metadata remains unchanged after a direct update attempt'
);
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'signed-waivers'
      and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/member-signed.pdf'$$,
  'members cannot delete a recorded signed waiver object'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'signed-waivers'
     and name = 'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/member-signed.pdf'),
  1::bigint,
  'recorded signed waiver objects remain after a direct delete attempt'
);
select throws_ok(
  $$select * from public.submit_signed_waiver(
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000005/14000000-0000-0000-0000-000000000101/organizer-signed.pdf'
  )$$,
  'P0001',
  'signed waiver unavailable',
  'members cannot claim another users signed waiver object'
);

set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000003';
select is(
  (select count(*) from storage.objects where bucket_id = 'signed-waivers'),
  0::bigint,
  'pending users cannot read signed waiver objects'
);
select throws_ok(
  $$select * from public.submit_signed_waiver(
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000003/14000000-0000-0000-0000-000000000101/pending-signed.pdf'
  )$$,
  'P0001',
  'signed waiver unavailable',
  'pending users cannot submit a signed waiver'
);

set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000006';
select is(
  (select count(*) from public.signed_waivers
   where user_id = '14000000-0000-0000-0000-000000000006'),
  0::bigint,
  'expired members cannot read signed waiver metadata'
);
select is(
  (select count(*) from storage.objects
   where bucket_id = 'signed-waivers'
     and name like 'signed-waivers/14000000-0000-0000-0000-000000000006/%'),
  0::bigint,
  'expired members cannot read signed waiver objects'
);

set local role postgres;
update public.membership_admin
set banned = true
where membership_id = (
  select id from public.memberships where user_id = '14000000-0000-0000-0000-000000000001'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select is(
  (select private.is_current_user_active_member()),
  false,
  'banned active members lose active-member authorization'
);
select is(
  (select public.can_current_user_submit_signed_waiver()),
  false,
  'banned active members fail the signed waiver membership preflight'
);
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select metadata ->> 'banned_from'
   from public.audit_log
   where entity_type = 'membership'
     and action = 'membership_admin.updated'
     and entity_id = (select id from public.memberships
                      where user_id = '14000000-0000-0000-0000-000000000001')
   order by created_at desc
   limit 1),
  'false',
  'directory audit records the previous banned flag'
);
select is(
  (select metadata ->> 'banned_to'
   from public.audit_log
   where entity_type = 'membership'
     and action = 'membership_admin.updated'
     and entity_id = (select id from public.memberships
                      where user_id = '14000000-0000-0000-0000-000000000001')
   order by created_at desc
   limit 1),
  'true',
  'directory audit records the new banned flag'
);

set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select throws_ok(
  $$select public.audit_signed_waiver_upload_compensation_failure(
    '14000000-0000-0000-0000-000000000001',
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/compensation-failure.pdf'
  )$$,
  '42501',
  null,
  'authenticated users cannot forge upload compensation audits'
);
set local role service_role;
set local "request.jwt.claim.role" = 'service_role';
select lives_ok(
  $$select public.audit_signed_waiver_upload_compensation_failure(
    '14000000-0000-0000-0000-000000000001',
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/compensation-failure.pdf'
  )$$,
  'service role can audit failed upload compensation'
);
set local role postgres;
select is(
  (select metadata ->> 'object_path'
   from public.audit_log
   where action = 'signed_waiver.upload_compensation_failed'
   order by created_at desc
   limit 1),
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/compensation-failure.pdf',
  'failed upload compensation audit records the exact object path'
);
set local role postgres;
insert into storage.objects (bucket_id, name, owner_id, metadata)
values (
  'signed-waivers',
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/replacement-cleanup.pdf',
  null,
  '{"mimetype":"application/pdf","size":25,"ucoa_user_id":"14000000-0000-0000-0000-000000000001"}'::jsonb
);
set local role authenticated;
select throws_ok(
  $$select public.audit_signed_waiver_replacement_cleanup_failure(
    '14000000-0000-0000-0000-000000000001',
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/replacement-cleanup.pdf'
  )$$,
  '42501',
  null,
  'authenticated users cannot forge replacement cleanup audits'
);
set local role service_role;
set local "request.jwt.claim.role" = 'service_role';
select lives_ok(
  $$select public.audit_signed_waiver_replacement_cleanup_failure(
    '14000000-0000-0000-0000-000000000001',
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/replacement-cleanup.pdf'
  )$$,
  'service role can audit failed replacement cleanup'
);
set local role postgres;
select is(
  (select metadata ->> 'object_path'
   from public.audit_log
   where action = 'signed_waiver.replacement_cleanup_failed'
   order by created_at desc
   limit 1),
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/replacement-cleanup.pdf',
  'replacement cleanup audit records the exact superseded object path'
);
select is(
  (select metadata ->> 'storage_object_present'
   from public.audit_log
   where action = 'signed_waiver.replacement_cleanup_failed'
   order by created_at desc
   limit 1),
  'true',
  'replacement cleanup audit records whether the object remains'
);

set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
set local role service_role;
set local "request.jwt.claim.role" = 'service_role';
select throws_ok(
  $$select * from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'no',
    'google_drive_reconciliation',
    null,
    null,
    null,
    null
  )$$,
  '42501',
  'member export unavailable',
  'the export RPC enforces explicit confirmation'
);
select is(
  (select count(*) from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    null,
    null
  )),
  7::bigint,
  'executives can export all website accounts'
);
select is(
  (select probation from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    null,
    null
  )
   where user_id = '14000000-0000-0000-0000-000000000001'),
  true,
  'the member export includes executive directory flags'
);
select is(
  (select paid_fee from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    null,
    null
  )
   where user_id = '14000000-0000-0000-0000-000000000001'),
  true,
  'the member export derives paid fee from verification metadata'
);
select is(
  (select blanket_waiver from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    null,
    null
  )
   where user_id = '14000000-0000-0000-0000-000000000001'),
  true,
  'the member export derives blanket waiver from a submitted PDF'
);
select is(
  (select count(*) from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    'D-1401',
    null
  )),
  1::bigint,
  'executives can filter member exports by search text'
);
select is(
  (select count(*) from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    'active',
    null,
    null,
    null
  )),
  3::bigint,
  'executives can filter member exports by membership status'
);
select is(
  (select count(*) from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    null,
    'organizer',
    null,
    null
  )),
  1::bigint,
  'executives can filter member exports by role'
);
select is(
  (select count(*) from public.export_member_directory(
    '14000000-0000-0000-0000-000000000002',
    'yes',
    'google_drive_reconciliation',
    null,
    null,
    null,
    true
  )),
  3::bigint,
  'executives can filter member exports by submitted waiver'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from public.list_signed_waiver_exports(null, 'submitted')),
  3::bigint,
  'executives can list all submitted signed waivers'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select throws_ok(
  $$select public.audit_signed_waiver_export(
    '14000000-0000-0000-0000-000000000002',
    array['14000000-0000-0000-0000-000000000201'::uuid],
    null,
    'submitted'
  )$$,
  '42501',
  null,
  'executives cannot forge signed-waiver export audit calls'
);
set local role service_role;
set local "request.jwt.claim.role" = 'service_role';
select public.audit_signed_waiver_export(
  '14000000-0000-0000-0000-000000000002',
  array[
    '14000000-0000-0000-0000-000000000201'::uuid,
    '14000000-0000-0000-0000-000000000202'::uuid,
    (select id from public.signed_waivers where user_id = '14000000-0000-0000-0000-000000000001')
  ],
  null,
  'submitted'
);
set local role anon;
set local "request.jwt.claim.sub" = '';
select throws_ok(
  $$select * from public.review_signed_waiver('14000000-0000-0000-0000-000000000201', 'approved')$$,
  '42501',
  null,
  'anonymous users cannot review signed waivers'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select throws_ok(
  $$select * from public.review_signed_waiver('14000000-0000-0000-0000-000000000201', 'approved')$$,
  '42501',
  'signed waiver review unavailable',
  'members cannot review signed waivers'
);
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select status::text from public.review_signed_waiver(
    '14000000-0000-0000-0000-000000000201',
    'approved'
  )),
  'approved',
  'executives can approve a signed waiver through the review RPC'
);
select is(
  (select reviewed_by from public.signed_waivers
   where id = '14000000-0000-0000-0000-000000000201'),
  '14000000-0000-0000-0000-000000000002'::uuid,
  'signed waiver review records the executive reviewer'
);
select is(
  (select count(*) from public.audit_log
   where action = 'signed_waiver.updated'
     and entity_id = '14000000-0000-0000-0000-000000000201'
     and actor_id = '14000000-0000-0000-0000-000000000002'),
  1::bigint,
  'signed waiver review creates an audit record'
);
set local role postgres;
insert into auth.users (id, email)
values ('14000000-0000-0000-0000-000000000008', 'directory-reviewer@example.test');
insert into public.user_roles (user_id, role, assigned_by)
values (
  '14000000-0000-0000-0000-000000000008',
  'executive',
  '14000000-0000-0000-0000-000000000002'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000008';
select is(
  (select status::text from public.review_signed_waiver(
    '14000000-0000-0000-0000-000000000202',
    'rejected'
  )),
  'rejected',
  'executives can reject a submitted signed waiver'
);
select is(
  (select status::text from public.review_signed_waiver(
    '14000000-0000-0000-0000-000000000202',
    'approved'
  )),
  'approved',
  'executives can approve a previously rejected signed waiver'
);
set local role postgres;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
delete from auth.users
where id = '14000000-0000-0000-0000-000000000008';
select is(
  (select reviewed_by from public.signed_waivers
   where id = '14000000-0000-0000-0000-000000000202'),
  null::uuid,
  'deleting a reviewer preserves the signed waiver record'
);
select is(
  (select reviewed_at is not null from public.signed_waivers
   where id = '14000000-0000-0000-0000-000000000202'),
  true,
  'deleting a reviewer preserves the review timestamp'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000002';
select is(
  (select count(*) from public.audit_log
   where action = 'member_directory.exported'
     and actor_id = '14000000-0000-0000-0000-000000000002'),
  8::bigint,
  'member export requests create audit records'
);
select is(
  (select count(*) from public.audit_log
   where action = 'signed_waiver.exported'
     and actor_id = '14000000-0000-0000-0000-000000000002'),
  1::bigint,
  'bulk signed waiver requests create an audit record'
);

set local role postgres;
insert into public.signed_waivers (
  id,
  waiver_id,
  user_id,
  object_path
)
values (
  '14000000-0000-0000-0000-000000000203',
  '14000000-0000-0000-0000-000000000101',
  '14000000-0000-0000-0000-000000000003',
  'signed-waivers/14000000-0000-0000-0000-000000000003/14000000-0000-0000-0000-000000000101/trigger-delete.pdf'
);
delete from public.signed_waivers
where id = '14000000-0000-0000-0000-000000000203';
select is(
  (select count(*) from public.audit_log
   where action = 'signed_waiver.deleted'
     and entity_id = '14000000-0000-0000-0000-000000000203'),
  1::bigint,
  'signed waiver deletes create deleted audit records'
);
select is(
  (select metadata ->> 'object_path'
   from public.audit_log
   where action = 'signed_waiver.deleted'
     and entity_id = '14000000-0000-0000-0000-000000000203'
   order by created_at desc
   limit 1),
  'signed-waivers/14000000-0000-0000-0000-000000000003/14000000-0000-0000-0000-000000000101/trigger-delete.pdf',
  'deleted signed waiver audits retain the exact object path'
);

set local role postgres;
update public.membership_admin
set banned = false
where membership_id = (
  select id from public.memberships where user_id = '14000000-0000-0000-0000-000000000001'
);
insert into storage.objects (bucket_id, name, owner_id, metadata)
values (
  'signed-waivers',
  'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/reuse-probe.pdf',
  null,
  '{"mimetype":"application/pdf","size":25,"ucoa_user_id":"14000000-0000-0000-0000-000000000001"}'::jsonb
);
set local role authenticated;
set local "request.jwt.claim.sub" = '14000000-0000-0000-0000-000000000001';
select is(
  (select status::text from public.submit_signed_waiver(
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/reuse-probe.pdf'
  )),
  'submitted',
  'active members can replace a signed waiver with a new object path'
);
select throws_ok(
  $$select * from public.submit_signed_waiver(
    '14000000-0000-0000-0000-000000000101',
    'signed-waivers/14000000-0000-0000-0000-000000000001/14000000-0000-0000-0000-000000000101/member-signed.pdf'
  )$$,
  'P0001',
  'signed waiver unavailable',
  'a superseded signed waiver object path cannot be reused'
);

select * from finish();

rollback;