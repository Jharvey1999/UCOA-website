begin;

select plan(54);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000011', 'storage-member@example.test'),
  ('00000000-0000-0000-0000-000000000012', 'storage-organizer@example.test'),
  ('00000000-0000-0000-0000-000000000013', 'storage-executive@example.test'),
  ('00000000-0000-0000-0000-000000000014', 'storage-other-member@example.test'),
  ('00000000-0000-0000-0000-000000000015', 'storage-pending@example.test'),
  ('00000000-0000-0000-0000-000000000016', 'storage-expired@example.test'),
  ('00000000-0000-0000-0000-000000000017', 'storage-suspended@example.test');

insert into public.profiles (id, first_name)
values
  ('00000000-0000-0000-0000-000000000011', 'Storage Member'),
  ('00000000-0000-0000-0000-000000000014', 'Storage Other Member'),
  ('00000000-0000-0000-0000-000000000015', 'Storage Pending'),
  ('00000000-0000-0000-0000-000000000016', 'Storage Expired'),
  ('00000000-0000-0000-0000-000000000017', 'Storage Suspended');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '00000000-0000-0000-0000-000000000011',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000012',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000014',
    '2020-09-01',
    '2099-08-31',
    'active',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000015',
    null,
    null,
    'pending',
    null
  ),
  (
    '00000000-0000-0000-0000-000000000016',
    '2020-09-01',
    '2025-08-31',
    'expired',
    '2020-09-01 00:00:00+00'
  ),
  (
    '00000000-0000-0000-0000-000000000017',
    '2020-09-01',
    '2099-08-31',
    'suspended',
    '2020-09-01 00:00:00+00'
  );

insert into public.membership_admin (membership_id, approved_by)
select id, '00000000-0000-0000-0000-000000000013'
from public.memberships
where status in ('active', 'expired', 'suspended');

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '00000000-0000-0000-0000-000000000011',
    'member',
    '00000000-0000-0000-0000-000000000013'
  ),
  (
    '00000000-0000-0000-0000-000000000012',
    'organizer',
    '00000000-0000-0000-0000-000000000013'
  ),
  (
    '00000000-0000-0000-0000-000000000013',
    'executive',
    '00000000-0000-0000-0000-000000000012'
  ),
  (
    '00000000-0000-0000-0000-000000000014',
    'member',
    '00000000-0000-0000-0000-000000000013'
  ),
  (
    '00000000-0000-0000-0000-000000000016',
    'organizer',
    '00000000-0000-0000-0000-000000000013'
  ),
  (
    '00000000-0000-0000-0000-000000000017',
    'organizer',
    '00000000-0000-0000-0000-000000000013'
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
  '30000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000012',
  'Storage Test Event',
  'A member-only event for Storage policy tests.',
  '2026-10-10 14:00:00+00',
  '2026-10-10 16:00:00+00',
  'hike',
  'members_only',
  'published'
);

insert into public.event_private_details (event_id, member_description)
values (
  '30000000-0000-0000-0000-000000000001',
  'Private details for the Storage test event.'
);

insert into public.event_hosts (event_id, user_id, assigned_by)
values (
  '30000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000012',
  '00000000-0000-0000-0000-000000000013'
);

insert into storage.objects (bucket_id, name, owner_id, metadata)
values
  (
    'profile-photos',
    'profiles/00000000-0000-0000-0000-000000000011/avatar.webp',
    '00000000-0000-0000-0000-000000000011',
    '{"mimetype":"image/webp","size":12345}'::jsonb
  ),
  (
    'profile-photos',
    'profiles/00000000-0000-0000-0000-000000000014/avatar.webp',
    '00000000-0000-0000-0000-000000000014',
    '{"mimetype":"image/webp","size":23456}'::jsonb
  ),
  (
    'profile-photos',
    'profiles/00000000-0000-0000-0000-000000000015/avatar.webp',
    '00000000-0000-0000-0000-000000000015',
    '{"mimetype":"image/webp","size":24680}'::jsonb
  ),
  (
    'profile-photos',
    'profiles/00000000-0000-0000-0000-000000000016/avatar.webp',
    '00000000-0000-0000-0000-000000000016',
    '{"mimetype":"image/webp","size":25680}'::jsonb
  ),
  (
    'profile-photos',
    'profiles/00000000-0000-0000-0000-000000000017/avatar.webp',
    '00000000-0000-0000-0000-000000000017',
    '{"mimetype":"image/webp","size":26680}'::jsonb
  ),
  (
    'profile-photos',
    'profiles/00000000-0000-0000-0000-000000000011/nested/avatar.webp',
    '00000000-0000-0000-0000-000000000011',
    '{"mimetype":"image/webp","size":34567}'::jsonb
  ),
  (
    'event-media',
    'events/30000000-0000-0000-0000-000000000001/trip.webp',
    '00000000-0000-0000-0000-000000000012',
    '{"mimetype":"image/webp","size":45678}'::jsonb
  ),
  (
    'event-media',
    'events/39999999-9999-9999-9999-999999999999/guessed.webp',
    '00000000-0000-0000-0000-000000000012',
    '{"mimetype":"image/webp","size":56789}'::jsonb
  );

set local role postgres;
select is(
  (select public from storage.buckets where id = 'profile-photos'),
  false,
  'profile photo bucket is private'
);
select is(
  (select public from storage.buckets where id = 'event-media'),
  false,
  'event media bucket is private'
);
select is(
  (select file_size_limit from storage.buckets where id = 'profile-photos'),
  5242880::bigint,
  'profile photo uploads have a five megabyte limit'
);
select is(
  (select file_size_limit from storage.buckets where id = 'event-media'),
  52428800::bigint,
  'event media uploads have a fifty megabyte limit'
);

set local role anon;
select is(
  (select count(id) from storage.objects),
  0::bigint,
  'anonymous users cannot read Storage objects'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('profile-photos', 'profiles/00000000-0000-0000-0000-000000000011/blocked.webp')$$,
  '42501',
  null,
  'anonymous users cannot upload Storage objects'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000015';
select is(
  (select count(id) from storage.objects where bucket_id = 'profile-photos'),
  0::bigint,
  'pending users cannot read profile photos'
);
select is(
  (select count(id) from storage.objects where bucket_id = 'event-media'),
  0::bigint,
  'pending users cannot read event media'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('profile-photos', 'profiles/00000000-0000-0000-0000-000000000015/avatar.webp')$$,
  '42501',
  null,
  'pending users cannot upload profile photos'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000015/avatar.webp'),
  0::bigint,
  'pending users cannot read their own profile photo'
);

set local role postgres;
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000011';
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/avatar.webp'),
  1::bigint,
  'members can read their own profile photo'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000014/avatar.webp'),
  0::bigint,
  'members cannot read another profile photo'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/nested/avatar.webp'),
  0::bigint,
  'nested profile paths are denied'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/39999999-9999-9999-9999-999999999999/guessed.webp'),
  0::bigint,
  'guessed event IDs do not reveal event media'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/trip.webp'),
  1::bigint,
  'active members can read media for an authorized event'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('profile-photos', 'profiles/00000000-0000-0000-0000-000000000014/new.webp')$$,
  '42501',
  null,
  'members cannot upload another user profile photo'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('event-media', 'events/30000000-0000-0000-0000-000000000001/new.webp')$$,
  '42501',
  null,
  'members cannot upload event media'
);
select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values (
      'profile-photos',
      'profiles/00000000-0000-0000-0000-000000000011/new.webp',
      '00000000-0000-0000-0000-000000000011',
      '{"mimetype":"image/webp","size":111}'::jsonb
    )$$,
  'members can upload their own profile photo'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values (
      'profile-photos',
      'profiles/00000000-0000-0000-0000-000000000011/forged.webp',
      '00000000-0000-0000-0000-000000000014',
      '{"mimetype":"image/webp","size":112}'::jsonb
    )$$,
  '42501',
  null,
  'members cannot forge Storage object ownership'
);
select lives_ok(
  $$update storage.objects
    set metadata = '{"mimetype":"image/webp","size":222}'::jsonb
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/new.webp'$$,
  'members can update their own profile photo metadata'
);
set local storage.allow_delete_query = 'true';
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/new.webp'$$,
  'members can delete their own profile photo through the Storage operation'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000014';
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000014/avatar.webp'),
  1::bigint,
  'members can read their own second profile photo'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/avatar.webp'),
  0::bigint,
  'members cannot read a different profile photo'
);
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/avatar.webp'$$,
  'unauthorized profile deletion does not raise an unsafe error'
);
set local role postgres;
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/avatar.webp'),
  1::bigint,
  'unauthorized profile deletion leaves the object unchanged'
);
set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000014';
select is(
  (select count(id) from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/trip.webp'),
  1::bigint,
  'other active members can read authorized event media'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('event-media', 'events/30000000-0000-0000-0000-000000000001/other.webp')$$,
  '42501',
  null,
  'members cannot upload event media even when they can read it'
);
select lives_ok(
  $$update storage.objects
    set metadata = '{"mimetype":"image/webp","size":999}'::jsonb
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/trip.webp'$$,
  'unauthorized event-media update does not raise an unsafe error'
);
select is(
  (select metadata from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/trip.webp'),
  '{"mimetype":"image/webp","size":45678}'::jsonb,
  'unauthorized event-media update leaves metadata unchanged'
);
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/trip.webp'$$,
  'members cannot delete event media even when they can read it'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/trip.webp'),
  1::bigint,
  'unauthorized event deletion leaves the object unchanged'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000012';
select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values (
      'event-media',
      'events/30000000-0000-0000-0000-000000000001/organizer.webp',
      '00000000-0000-0000-0000-000000000012',
      '{"mimetype":"image/webp","size":333}'::jsonb
    )$$,
  'a hosted organizer can upload event media'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/organizer.webp'),
  1::bigint,
  'organizer event media upload is visible to the host'
);
select lives_ok(
  $$update storage.objects
    set metadata = '{"mimetype":"image/webp","size":666}'::jsonb
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/organizer.webp'$$,
  'a hosted organizer can update event media metadata'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('event-media', 'events/39999999-9999-9999-9999-999999999999/organizer.webp')$$,
  '42501',
  null,
  'organizers cannot upload media for an unknown event'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('profile-photos', 'profiles/00000000-0000-0000-0000-000000000011/organizer.webp')$$,
  '42501',
  null,
  'organizers cannot upload another profile photo'
);
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/organizer.webp'$$,
  'a hosted organizer can delete event media through the Storage operation'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000016';
select is(
  (select count(id) from storage.objects where bucket_id = 'event-media'),
  0::bigint,
  'expired organizers cannot read event media'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('event-media', 'events/30000000-0000-0000-0000-000000000001/expired.webp')$$,
  '42501',
  null,
  'expired organizers cannot upload event media'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000016/avatar.webp'),
  0::bigint,
  'expired users cannot read their own profile photo'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('profile-photos', 'profiles/00000000-0000-0000-0000-000000000016/new.webp')$$,
  '42501',
  null,
  'expired users cannot upload profile photos'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000017';
select is(
  (select count(id) from storage.objects where bucket_id = 'event-media'),
  0::bigint,
  'suspended organizers cannot read event media'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('event-media', 'events/30000000-0000-0000-0000-000000000001/suspended.webp')$$,
  '42501',
  null,
  'suspended organizers cannot upload event media'
);
select is(
  (select count(id) from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000017/avatar.webp'),
  0::bigint,
  'suspended users cannot read their own profile photo'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('profile-photos', 'profiles/00000000-0000-0000-0000-000000000017/new.webp')$$,
  '42501',
  null,
  'suspended users cannot upload profile photos'
);

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-0000-0000-000000000013';
select is(
  (select count(id) from storage.objects where bucket_id = 'profile-photos'),
  5::bigint,
  'executives can read all valid profile media objects'
);
select is(
  (select count(id) from storage.objects where bucket_id = 'event-media'),
  1::bigint,
  'executives can read all event media objects'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values (
      'event-media',
      'events/39999999-9999-9999-9999-999999999999/executive.webp',
      '00000000-0000-0000-0000-000000000013',
      '{"mimetype":"image/webp","size":555}'::jsonb
    )$$,
  '42501',
  null,
  'executives cannot upload media for an unknown event'
);
select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values (
      'event-media',
      'events/30000000-0000-0000-0000-000000000001/executive.webp',
      '00000000-0000-0000-0000-000000000013',
      '{"mimetype":"image/webp","size":555}'::jsonb
    )$$,
  'executives can upload media for an existing event'
);
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'event-media'
      and name = 'events/30000000-0000-0000-0000-000000000001/executive.webp'$$,
  'executives can delete event media through the Storage operation'
);
select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id, metadata)
    values (
      'profile-photos',
      'profiles/00000000-0000-0000-0000-000000000011/executive.webp',
      '00000000-0000-0000-0000-000000000013',
      '{"mimetype":"image/webp","size":444}'::jsonb
    )$$,
  'executives can upload a profile photo for another user'
);
select throws_ok(
  $$update storage.objects
    set owner_id = '00000000-0000-0000-0000-000000000013'
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/avatar.webp'$$,
  '42501',
  null,
  'executives cannot change Storage object ownership'
);
select is(
  (select owner_id from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/avatar.webp'),
  '00000000-0000-0000-0000-000000000011'::text,
  'Storage object ownership remains unchanged after a denied update'
);
select lives_ok(
  $$delete from storage.objects
    where bucket_id = 'profile-photos'
      and name = 'profiles/00000000-0000-0000-0000-000000000011/executive.webp'$$,
  'executives can delete profile media through the Storage operation'
);

select * from finish();

rollback;