begin;

select plan(8);

insert into auth.users (id, email)
values
  ('13000000-0000-0000-0000-000000000001', 'new-waiver-member@example.test'),
  ('13000000-0000-0000-0000-000000000002', 'new-waiver-executive@example.test');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values (
  '13000000-0000-0000-0000-000000000001',
  '2026-09-01',
  '2027-08-31',
  'active',
  '2026-09-01 00:00:00+00'
);

insert into public.membership_admin (membership_id, approved_by)
select id, '13000000-0000-0000-0000-000000000002'
from public.memberships
where user_id = '13000000-0000-0000-0000-000000000001';

set local role postgres;
select is(
  (select count(*) from public.waivers
   where version = '2026-2027-club-approved-activities'),
  1::bigint,
  'the 2026-2027 club activities waiver has one metadata record'
);
select is(
  (select acknowledgement_method::text from public.waivers
   where version = '2026-2027-club-approved-activities'),
  'organizer_recorded',
  'the new waiver is mapped to organizer-recorded completion pending approval'
);
select is(
  (select status::text from public.waivers
   where version = '2026-2027-club-approved-activities'),
  'draft',
  'the new waiver remains a draft'
);
select is(
  (select document_reference from public.waivers
   where version = '2026-2027-club-approved-activities'),
  'waivers/2026-2027/club-approved-activities.pdf',
  'the new waiver has a canonical private object path'
);
select is(
  (select approved_by from public.waivers
   where version = '2026-2027-club-approved-activities'),
  null::uuid,
  'the new waiver has no approval actor'
);
select is(
  (select approved_at from public.waivers
   where version = '2026-2027-club-approved-activities'),
  null::timestamptz,
  'the new waiver has no approval timestamp'
);
select is(
  has_table_privilege('anon', 'public.waivers', 'select'),
  false,
  'anonymous users have no direct waiver metadata grant'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '13000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from public.waivers
   where version = '2026-2027-club-approved-activities'),
  0::bigint,
  'active members cannot read the unapproved new waiver'
);

select * from finish();
rollback;