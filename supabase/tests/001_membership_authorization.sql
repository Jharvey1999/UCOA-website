begin;

select plan(32);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000001', 'pending@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'expired@example.test'),
  ('00000000-0000-0000-0000-000000000003', 'member@example.test'),
  ('00000000-0000-0000-0000-000000000004', 'organizer@example.test'),
  ('00000000-0000-0000-0000-000000000005', 'executive@example.test'),
  ('00000000-0000-0000-0000-000000000006', 'other-member@example.test'),
  ('00000000-0000-0000-0000-000000000007', 'target@example.test'),
  ('00000000-0000-0000-0000-000000000008', 'expired-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000009', 'applicant@example.test');

insert into public.profiles (id, first_name, last_name_initial, display_name)
values
  ('00000000-0000-0000-0000-000000000001', 'Pending', 'P', 'Pending P'),
  ('00000000-0000-0000-0000-000000000002', 'Expired', 'E', 'Expired E'),
  ('00000000-0000-0000-0000-000000000003', 'Member', 'M', 'Member M'),
  ('00000000-0000-0000-0000-000000000004', 'Organizer', 'O', 'Organizer O'),
  ('00000000-0000-0000-0000-000000000005', 'Executive', 'X', 'Executive X'),
  ('00000000-0000-0000-0000-000000000006', 'Other', 'M', 'Other M'),
  ('00000000-0000-0000-0000-000000000007', 'Target', 'T', 'Target T'),
  ('00000000-0000-0000-0000-000000000008', 'Expired Host', 'H', 'Expired Host H'),
  ('00000000-0000-0000-0000-000000000009', 'Applicant', 'A', 'Applicant A');

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
    '00000000-0000-0000-0000-000000000008',
    '2020-09-01',
    '2025-08-31',
    'expired',
    '2020-09-01 00:00:00+00'
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000005'
from public.memberships
where user_id in (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000008'
);

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
    '00000000-0000-0000-0000-000000000008',
    'organizer',
    '00000000-0000-0000-0000-000000000005'
  );

set local role anon;
select throws_ok(
  $$select count(*) from public.profiles$$,
  '42501',
  null,
  'anonymous users cannot read profiles'
);
select throws_ok(
  $$select count(*) from public.memberships$$,
  '42501',
  null,
  'anonymous users cannot read memberships'
);
select throws_ok(
  $$select count(*) from public.user_roles$$,
  '42501',
  null,
  'anonymous users cannot read roles'
);
select throws_ok(
  $$select count(*) from public.membership_admin$$,
  '42501',
  null,
  'anonymous users cannot read membership administration'
);
select throws_ok(
  $$insert into public.profiles (id, first_name) values ('00000000-0000-0000-0000-000000000009', 'Blocked')$$,
  '42501',
  null,
  'anonymous users cannot insert profiles'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000001';
select is(
  (select count(*) from public.memberships where user_id = '00000000-0000-0000-0000-000000000001'),
  1::bigint,
  'pending users can read their own membership'
);
select is(
  (select count(*) from public.memberships where user_id = '00000000-0000-0000-0000-000000000003'),
  0::bigint,
  'pending users cannot read another membership'
);
select throws_ok(
  $$insert into public.memberships (user_id, status, membership_year_start, membership_year_end, approved_at)
    values ('00000000-0000-0000-0000-000000000001', 'active', '2026-09-01', '2027-08-31', now())$$,
  '42501',
  null,
  'pending users cannot create an active membership'
);
select throws_ok(
  $$insert into public.user_roles (user_id, role, assigned_by)
    values ('00000000-0000-0000-0000-000000000001', 'executive', '00000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'pending users cannot assign roles'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000009';
select lives_ok(
  $$insert into public.memberships (user_id, status) values ('00000000-0000-0000-0000-000000000009', 'pending')$$,
  'an applicant can create one pending application'
);
select is(
  (select count(*) from public.memberships where user_id = '00000000-0000-0000-0000-000000000009'),
  1::bigint,
  'the applicant can read the created application'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000003';
select is(
  (select count(*) from public.profiles where id = '00000000-0000-0000-0000-000000000003'),
  1::bigint,
  'active members can read their own profile'
);
select is(
  (select count(*) from public.profiles where id = '00000000-0000-0000-0000-000000000005'),
  0::bigint,
  'active members cannot read another profile'
);
select lives_ok(
  $$update public.profiles set display_name = 'Member Updated' where id = '00000000-0000-0000-0000-000000000003'$$,
  'active members can update their own profile'
);
select lives_ok(
  $$update public.profiles set display_name = 'Blocked' where id = '00000000-0000-0000-0000-000000000005'$$,
  'active members cannot update another profile'
);
select lives_ok(
  $$update public.memberships set status = 'suspended' where user_id = '00000000-0000-0000-0000-000000000003'$$,
  'active members cannot update membership approval state'
);
set local role postgres;
select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-000000000005'),
  'Executive X',
  'a cross-user profile update leaves the target unchanged'
);
select is(
  (select status::text from public.memberships where user_id = '00000000-0000-0000-0000-000000000003'),
  'active',
  'a membership approval update leaves the target unchanged'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000003';
select is(
  (select count(*) from public.membership_admin),
  0::bigint,
  'members cannot read executive-only membership metadata'
);
select throws_ok(
  $$insert into public.user_roles (user_id, role, assigned_by)
    values ('00000000-0000-0000-0000-000000000007', 'executive', '00000000-0000-0000-0000-000000000003')$$,
  '42501',
  null,
  'active members cannot grant themselves or others a role'
);
select is(
  (select private.is_current_user_active_member()),
  true,
  'active membership is recognized independently of role'
);
set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000008';
select is(
  (select private.is_current_user_active_member()),
  false,
  'expired membership is not active even with an organizer role'
);
set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000003';
select is(
  (select count(*) from public.audit_log),
  0::bigint,
  'non-executives cannot read the audit log'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000004';
select throws_ok(
  $$insert into public.user_roles (user_id, role, assigned_by)
    values ('00000000-0000-0000-0000-000000000007', 'organizer', '00000000-0000-0000-0000-000000000004')$$,
  '42501',
  null,
  'organizers cannot assign roles'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000005';
select is(
  (select count(*) from public.profiles),
  9::bigint,
  'executives can read all profiles'
);
select is(
  (select count(*) from public.memberships),
  6::bigint,
  'executives can read all memberships'
);
select is(
  (select count(*) from public.membership_admin),
  4::bigint,
  'executives can read membership administration metadata'
);
select throws_ok(
  $$insert into public.membership_admin (membership_id, approved_by)
    select id, '00000000-0000-0000-0000-000000000004'
    from public.memberships
    where user_id = '00000000-0000-0000-0000-000000000009'$$,
  '42501',
  null,
  'executives cannot claim another user as the approver'
);
select lives_ok(
  $$insert into public.user_roles (user_id, role, assigned_by)
    values ('00000000-0000-0000-0000-000000000009', 'member', '00000000-0000-0000-0000-000000000005')$$,
  'executives can assign a role to another user'
);
select is(
  (select count(*) from public.user_roles
    where user_id = '00000000-0000-0000-0000-000000000009' and role = 'member'),
  1::bigint,
  'the assigned role is visible to the executive'
);
select throws_ok(
  $$insert into public.user_roles (user_id, role, assigned_by)
    values ('00000000-0000-0000-0000-000000000005', 'organizer', '00000000-0000-0000-0000-000000000004')$$,
  '42501',
  null,
  'executives cannot assign a role to themselves'
);
select is(
  (select count(*) from public.audit_log
    where entity_type = 'user_role'
      and entity_id = '00000000-0000-0000-0000-000000000009'
      and action = 'role.created'),
  1::bigint,
  'role assignment creates a safe audit record'
);

select * from finish();

rollback;