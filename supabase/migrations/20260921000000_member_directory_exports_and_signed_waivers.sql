alter table public.profiles
  add column last_name text,
  add column phone_number text,
  add column student_id text,
  add column emergency_contact_name text,
  add column emergency_contact_phone text,
  add column emergency_contact_consent_to_share boolean not null default false,
  add constraint profiles_last_name_valid check (
    last_name is null or char_length(btrim(last_name)) between 1 and 120
  ),
  add constraint profiles_phone_number_valid check (
    phone_number is null or char_length(btrim(phone_number)) between 1 and 40
  ),
  add constraint profiles_student_id_valid check (
    student_id is null or char_length(btrim(student_id)) between 1 and 80
  ),
  add constraint profiles_emergency_contact_name_valid check (
    emergency_contact_name is null
    or char_length(btrim(emergency_contact_name)) between 1 and 160
  ),
  add constraint profiles_emergency_contact_phone_valid check (
    emergency_contact_phone is null
    or char_length(btrim(emergency_contact_phone)) between 1 and 40
  );

alter table public.memberships
  add column date_joined date;

create or replace function private.normalize_profile_emergency_contact()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  if not new.emergency_contact_consent_to_share then
    new.emergency_contact_name := null;
    new.emergency_contact_phone := null;
  end if;

  return new;
end;
$$;

revoke all on function private.normalize_profile_emergency_contact() from public;

drop trigger if exists profiles_emergency_contact_consent_normalization on public.profiles;
create trigger profiles_emergency_contact_consent_normalization
before insert or update on public.profiles
for each row execute function private.normalize_profile_emergency_contact();

alter table public.membership_admin
  add column probation boolean not null default false,
  add column banned boolean not null default false,
  add column acc_member boolean not null default false,
  add column added_to_email_list boolean not null default false,
  add column directory_notes text,
  add constraint membership_admin_directory_notes_valid check (
    directory_notes is null or char_length(directory_notes) <= 4000
  );

create or replace function private.audit_membership_admin_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if tg_op = 'DELETE' then
    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      'membership_admin.deleted',
      'membership',
      old.membership_id,
      jsonb_build_object(
        'probation', old.probation,
        'banned', old.banned,
        'acc_member', old.acc_member,
        'added_to_email_list', old.added_to_email_list,
        'has_directory_notes', old.directory_notes is not null
      )
    );
    return old;
  end if;

  if tg_op = 'INSERT' then
    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      'membership_admin.created',
      'membership',
      new.membership_id,
      jsonb_build_object(
        'has_approval', new.approved_by is not null,
        'has_payment_verification', new.payment_verified_at is not null,
        'has_legacy_reference', new.legacy_reference is not null,
        'probation', new.probation,
        'banned', new.banned,
        'acc_member', new.acc_member,
        'added_to_email_list', new.added_to_email_list,
        'has_directory_notes', new.directory_notes is not null
      )
    );
    return new;
  end if;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    'membership_admin.updated',
    'membership',
    new.membership_id,
    jsonb_build_object(
      'has_approval', new.approved_by is not null,
      'has_payment_verification', new.payment_verified_at is not null,
      'has_legacy_reference', new.legacy_reference is not null,
      'probation_from', old.probation,
      'probation_to', new.probation,
      'banned_from', old.banned,
      'banned_to', new.banned,
      'acc_member_from', old.acc_member,
      'acc_member_to', new.acc_member,
      'added_to_email_list_from', old.added_to_email_list,
      'added_to_email_list_to', new.added_to_email_list,
      'directory_notes_changed', old.directory_notes is distinct from new.directory_notes,
      'has_directory_notes', new.directory_notes is not null
    )
  );
  return new;
end;
$$;

revoke all on function private.audit_membership_admin_change() from public;

create or replace function private.is_current_user_active_member()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.memberships
    left join public.membership_admin
      on membership_admin.membership_id = memberships.id
    where memberships.user_id = (select auth.uid())
      and memberships.status = 'active'::public.membership_status
      and current_date between memberships.membership_year_start
        and memberships.membership_year_end
      and not coalesce(membership_admin.banned, false)
  );
$$;

create or replace function public.can_current_user_submit_signed_waiver()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select coalesce(
    (select auth.uid()) is not null
      and private.is_current_user_active_member(),
    false
  );
$$;

revoke all on function public.can_current_user_submit_signed_waiver() from public, anon;
grant execute on function public.can_current_user_submit_signed_waiver() to authenticated;

create or replace function private.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  first_name_value text;
  last_name_value text;
  phone_number_value text;
  student_id_value text;
  affiliation_value text;
  emergency_contact_name_value text;
  emergency_contact_phone_value text;
  emergency_contact_consent_value boolean;
  last_name_initial_value text;
begin
  first_name_value := nullif(btrim(new.raw_user_meta_data ->> 'first_name'), '');
  last_name_value := nullif(btrim(new.raw_user_meta_data ->> 'last_name'), '');

  if first_name_value is null
    or char_length(first_name_value) > 80
    or last_name_value is null
    or char_length(last_name_value) > 120 then
    return new;
  end if;

  phone_number_value := nullif(btrim(new.raw_user_meta_data ->> 'phone_number'), '');
  if phone_number_value is not null and char_length(phone_number_value) > 40 then
    phone_number_value := null;
  end if;

  student_id_value := nullif(btrim(new.raw_user_meta_data ->> 'student_id'), '');
  if student_id_value is not null and char_length(student_id_value) > 80 then
    student_id_value := null;
  end if;

  affiliation_value := nullif(btrim(new.raw_user_meta_data ->> 'affiliation'), '');
  if affiliation_value is not null and char_length(affiliation_value) > 160 then
    affiliation_value := null;
  end if;

  emergency_contact_name_value := nullif(btrim(new.raw_user_meta_data ->> 'emergency_contact_name'), '');
  if emergency_contact_name_value is not null and char_length(emergency_contact_name_value) > 160 then
    emergency_contact_name_value := null;
  end if;

  emergency_contact_phone_value := nullif(btrim(new.raw_user_meta_data ->> 'emergency_contact_phone'), '');
  if emergency_contact_phone_value is not null and char_length(emergency_contact_phone_value) > 40 then
    emergency_contact_phone_value := null;
  end if;

  emergency_contact_consent_value := coalesce(
    lower(new.raw_user_meta_data ->> 'emergency_contact_consent_to_share') = 'true',
    false
  );

  if not emergency_contact_consent_value then
    emergency_contact_name_value := null;
    emergency_contact_phone_value := null;
  end if;

  last_name_initial_value := case
    when last_name_value ~ '^[[:alpha:]]' then substring(last_name_value from 1 for 1)
    else null
  end;

  insert into public.profiles (
    id,
    first_name,
    last_name,
    last_name_initial,
    display_name,
    affiliation,
    phone_number,
    student_id,
    emergency_contact_name,
    emergency_contact_phone,
    emergency_contact_consent_to_share
  )
  values (
    new.id,
    first_name_value,
    last_name_value,
    last_name_initial_value,
    concat(first_name_value, case when last_name_initial_value is null then '' else ' ' || last_name_initial_value || '.' end),
    affiliation_value,
    phone_number_value,
    student_id_value,
    emergency_contact_name_value,
    emergency_contact_phone_value,
    emergency_contact_consent_value
  )
  on conflict (id) do nothing;

  insert into public.memberships (user_id, status)
  values (new.id, 'pending'::public.membership_status)
  on conflict (user_id) where status in ('pending', 'needs_verification') do nothing;

  return new;
end;
$$;

revoke all on function private.handle_new_user_profile() from public;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function private.handle_new_user_profile();

alter table public.waivers
  add column member_downloadable boolean not null default false;

drop policy waivers_select_approved_for_allowed_event on public.waivers;
create policy waivers_select_approved_for_allowed_event
on public.waivers for select to authenticated
using (
  (
    status = 'approved'::public.waiver_status
    and (
      (member_downloadable and (select private.is_current_user_active_member()))
      or (select private.can_current_user_read_waiver(waivers.id))
    )
  )
  or (select private.is_current_user_executive())
);

create type public.signed_waiver_status as enum (
  'submitted',
  'approved',
  'rejected',
  'revoked'
);

create table public.signed_waivers (
  id uuid primary key default extensions.gen_random_uuid(),
  waiver_id uuid not null references public.waivers(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  object_path text not null check (
    object_path ~ '^signed-waivers/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$'
  ),
  status public.signed_waiver_status not null default 'submitted',
  submitted_at timestamptz not null default timezone('utc', now()),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (waiver_id, user_id),
  constraint signed_waivers_review_metadata_valid check (
    (status = 'submitted' and reviewed_by is null and reviewed_at is null)
    or (status in ('approved', 'rejected', 'revoked') and reviewed_at is not null)
  )
);

create index signed_waivers_user_status_idx
  on public.signed_waivers (user_id, status, submitted_at desc);

create index signed_waivers_waiver_status_idx
  on public.signed_waivers (waiver_id, status, submitted_at desc);

create table private.signed_waiver_used_paths (
  object_path text primary key check (
    object_path ~ '^signed-waivers/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$'
  ),
  first_seen_at timestamptz not null default timezone('utc', now())
);

revoke all on table private.signed_waiver_used_paths from public, anon, authenticated, service_role;

create table private.signed_waiver_cleanup_claims (
  object_path text primary key check (
    object_path ~ '^signed-waivers/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$'
  ),
  claimed_by uuid references auth.users(id) on delete set null,
  cutoff timestamptz not null,
  claimed_at timestamptz not null default timezone('utc', now())
);

create index signed_waiver_cleanup_claims_actor_idx
  on private.signed_waiver_cleanup_claims (claimed_by, claimed_at);

revoke all on table private.signed_waiver_cleanup_claims from public, anon, authenticated, service_role;

alter table public.signed_waivers enable row level security;

revoke all on table public.signed_waivers from anon, authenticated;
grant select on table public.signed_waivers to authenticated;

create policy signed_waivers_select_own_or_executive
on public.signed_waivers for select to authenticated
using (
  (
    user_id = (select auth.uid())
    and (select private.is_current_user_active_member())
  )
  or (select private.is_current_user_executive())
);

create policy signed_waivers_insert_denied
on public.signed_waivers for insert to authenticated
with check (false);

create policy signed_waivers_update_denied
on public.signed_waivers for update to authenticated
using (false)
with check (false);

create policy signed_waivers_delete_denied
on public.signed_waivers for delete to authenticated
using (false);

create or replace function private.audit_signed_waiver_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if tg_op = 'DELETE' then
    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      'signed_waiver.deleted',
      'signed_waiver',
      old.id,
      jsonb_build_object(
        'waiver_id', old.waiver_id,
        'user_id', old.user_id,
        'status', old.status::text,
        'object_path', old.object_path
      )
    );
    return old;
  end if;

  if tg_op = 'INSERT' then
    insert into private.signed_waiver_used_paths (object_path)
    values (new.object_path)
    on conflict (object_path) do nothing;

    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      'signed_waiver.submitted',
      'signed_waiver',
      new.id,
      jsonb_build_object(
        'waiver_id', new.waiver_id,
        'user_id', new.user_id,
        'status', new.status::text,
        'object_path', new.object_path
      )
    );
    return new;
  end if;

  insert into private.signed_waiver_used_paths (object_path)
  values (new.object_path)
  on conflict (object_path) do nothing;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    'signed_waiver.updated',
    'signed_waiver',
    new.id,
    jsonb_build_object(
      'waiver_id', new.waiver_id,
      'user_id', new.user_id,
      'previous_status', old.status::text,
      'status', new.status::text,
      'previous_object_path', old.object_path,
      'object_path', new.object_path,
      'object_path_changed', old.object_path is distinct from new.object_path
    )
  );
  return new;
end;
$$;

revoke all on function private.audit_signed_waiver_change() from public;

create trigger signed_waivers_set_updated_at
before update on public.signed_waivers
for each row execute function private.set_updated_at();

create trigger signed_waivers_audit_changes
after insert or update or delete on public.signed_waivers
for each row execute function private.audit_signed_waiver_change();

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'signed-waivers',
  'signed-waivers',
  false,
  10485760,
  array['application/pdf']::text[]
);

create or replace function private.storage_signed_waiver_user_id(p_name text)
returns uuid
language plpgsql
immutable
set search_path = pg_catalog
as $$
begin
  if p_name is null
    or p_name !~ '^signed-waivers/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$' then
    return null;
  end if;

  return split_part(p_name, '/', 2)::uuid;
exception
  when invalid_text_representation then
    return null;
end;
$$;

create or replace function private.storage_signed_waiver_id(p_name text)
returns uuid
language plpgsql
immutable
set search_path = pg_catalog
as $$
begin
  if p_name is null
    or p_name !~ '^signed-waivers/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$' then
    return null;
  end if;

  return split_part(p_name, '/', 3)::uuid;
exception
  when invalid_text_representation then
    return null;
end;
$$;

drop function if exists private.can_current_user_upload_signed_waiver(text);

create or replace function private.can_current_user_read_signed_waiver(p_name text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.signed_waivers
    where object_path = p_name
      and user_id = (select auth.uid())
      and (select private.is_current_user_active_member())
  );
$$;

create or replace function private.can_current_user_delete_signed_waiver(p_name text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select (select private.storage_signed_waiver_user_id(p_name)) = (select auth.uid())
    and exists (
      select 1
      from storage.objects
      where storage.objects.bucket_id = 'signed-waivers'
        and storage.objects.name = p_name
        and storage.objects.metadata ->> 'ucoa_user_id' = (select auth.uid()::text)
    )
    and (select private.is_current_user_active_member())
    and not exists (
      select 1
      from public.signed_waivers
      where object_path = p_name
    );
$$;

revoke all on function private.storage_signed_waiver_user_id(text) from public;
revoke all on function private.storage_signed_waiver_id(text) from public;
revoke all on function private.can_current_user_read_signed_waiver(text) from public;
revoke all on function private.can_current_user_delete_signed_waiver(text) from public;
grant execute on function private.can_current_user_read_signed_waiver(text) to authenticated;
grant execute on function private.can_current_user_delete_signed_waiver(text) to authenticated;

drop policy if exists signed_waivers_storage_select_owner_or_executive on storage.objects;
create policy signed_waivers_storage_select_owner
on storage.objects for select to authenticated
using (
  bucket_id = 'signed-waivers'
  and (select private.can_current_user_read_signed_waiver(name))
);

drop policy if exists signed_waivers_storage_insert_owner on storage.objects;

drop policy if exists signed_waivers_storage_update_owner_or_executive on storage.objects;

drop policy if exists signed_waivers_storage_delete_owner_or_executive on storage.objects;
create policy signed_waivers_storage_delete_unreferenced_owner
on storage.objects for delete to authenticated
using (
  bucket_id = 'signed-waivers'
  and (select private.can_current_user_delete_signed_waiver(name))
);

create or replace function public.submit_signed_waiver(
  p_waiver_id uuid,
  p_object_path text
)
returns table (
  id uuid,
  status public.signed_waiver_status,
  previous_object_path text
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  current_user_id uuid;
  previous_path text;
  submitted_id uuid;
begin
  current_user_id := auth.uid();

  if current_user_id is null
    or p_waiver_id is null
    or not private.is_current_user_active_member()
    or private.storage_signed_waiver_user_id(p_object_path) is distinct from current_user_id
    or private.storage_signed_waiver_id(p_object_path) is distinct from p_waiver_id then
    raise exception using errcode = 'P0001', message = 'signed waiver unavailable';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_waiver_id::text || ':' || current_user_id::text,
      0
    )
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_object_path, 0)
  );

  if not exists (
    select 1
    from public.waivers as waivers
    where waivers.id = p_waiver_id
      and waivers.status = 'approved'::public.waiver_status
      and waivers.member_downloadable
  ) then
    raise exception using errcode = 'P0001', message = 'signed waiver unavailable';
  end if;

  if not exists (
    select 1
    from storage.objects
    where bucket_id = 'signed-waivers'
      and name = p_object_path
      and metadata ->> 'ucoa_user_id' = current_user_id::text
  ) then
    raise exception using errcode = 'P0001', message = 'signed waiver upload unavailable';
  end if;

  if exists (
    select 1
    from private.signed_waiver_used_paths
    where object_path = p_object_path
  )
  and not exists (
    select 1
    from public.signed_waivers
    where object_path = p_object_path
  ) then
    raise exception using errcode = 'P0001', message = 'signed waiver unavailable';
  end if;

  if exists (
    select 1
    from private.signed_waiver_cleanup_claims
    where object_path = p_object_path
  ) then
    raise exception using errcode = 'P0001', message = 'signed waiver unavailable';
  end if;

  select object_path
  into previous_path
  from public.signed_waivers
  where waiver_id = p_waiver_id
    and user_id = current_user_id;

  insert into public.signed_waivers (
    waiver_id,
    user_id,
    object_path,
    status,
    submitted_at,
    reviewed_by,
    reviewed_at
  )
  values (
    p_waiver_id,
    current_user_id,
    p_object_path,
    'submitted'::public.signed_waiver_status,
    timezone('utc', now()),
    null,
    null
  )
  on conflict (waiver_id, user_id) do update
  set object_path = excluded.object_path,
      status = excluded.status,
      submitted_at = excluded.submitted_at,
      reviewed_by = null,
      reviewed_at = null
  returning signed_waivers.id, signed_waivers.status
  into submitted_id, status;

  return query select submitted_id, status, previous_path;
end;
$$;

revoke all on function public.submit_signed_waiver(uuid, text) from public;
grant execute on function public.submit_signed_waiver(uuid, text) to authenticated;

drop function if exists public.export_member_directory(public.membership_status, public.app_role, text, boolean);

create or replace function public.export_member_directory(
  p_actor_id uuid,
  p_confirmation text,
  p_purpose text,
  p_status public.membership_status default null,
  p_role public.app_role default null,
  p_search text default null,
  p_has_signed_waiver boolean default null
)
returns table (
  executive boolean,
  organizer boolean,
  probation boolean,
  banned boolean,
  acc boolean,
  role text,
  first_name text,
  last_name text,
  paid_fee boolean,
  date_joined date,
  student_id text,
  email text,
  added_to_email_list boolean,
  phone_number text,
  blanket_waiver boolean,
  notes text,
  emergency_contact text,
  status text,
  emergency_contact_phone text,
  consent_to_share boolean,
  account_created_at timestamptz,
  membership_year_start date,
  membership_year_end date,
  affiliation text,
  display_name text,
  user_id uuid,
  membership_id uuid
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  exported_count bigint;
  normalized_search text;
  max_export_rows constant integer := 5000;
begin
  if (select auth.role()) <> 'service_role'
    or p_actor_id is null
    or p_confirmation <> 'yes'
    or p_purpose <> 'google_drive_reconciliation'
    or not exists (
      select 1
      from public.user_roles as actor_roles
      where actor_roles.user_id = p_actor_id
        and actor_roles.role = 'executive'::public.app_role
    ) then
    raise exception using errcode = '42501', message = 'member export unavailable';
  end if;

  normalized_search := nullif(btrim(p_search), '');

  return query
  with latest_membership as (
      select distinct on (memberships.user_id)
      memberships.*
    from public.memberships
    order by memberships.user_id,
      (memberships.status = 'active'::public.membership_status) desc,
      memberships.membership_year_end desc nulls last,
      memberships.created_at desc
  ),
  role_flags as (
    select
      user_roles.user_id,
      coalesce(bool_or(user_roles.role = 'executive'::public.app_role), false) as executive,
      coalesce(bool_or(user_roles.role = 'organizer'::public.app_role), false) as organizer,
      coalesce(string_agg(user_roles.role::text, ', ' order by user_roles.role::text), 'member') as role,
      count(*) > 0 as has_role
    from public.user_roles
    group by user_roles.user_id
  ),
  blanket_waiver_flags as (
    select
      signed_waivers.user_id,
      bool_or(
        signed_waivers.status in (
          'submitted'::public.signed_waiver_status,
          'approved'::public.signed_waiver_status
        )
        and waivers.status = 'approved'::public.waiver_status
        and waivers.member_downloadable
      ) as blanket_waiver
    from public.signed_waivers
    join public.waivers on waivers.id = signed_waivers.waiver_id
    group by signed_waivers.user_id
  ),
  export_rows as (
    select
      coalesce(role_flags.executive, false) as executive,
      coalesce(role_flags.organizer, false) as organizer,
      coalesce(membership_admin.probation, false) as probation,
      coalesce(membership_admin.banned, false) as banned,
      coalesce(membership_admin.acc_member, false) as acc,
      coalesce(role_flags.role, 'member') as role,
      coalesce(profiles.first_name, '') as first_name,
      coalesce(profiles.last_name, profiles.last_name_initial, '') as last_name,
      (membership_admin.payment_verified_at is not null) as paid_fee,
      coalesce(latest_membership.date_joined, (auth.users.created_at at time zone 'UTC')::date) as date_joined,
      profiles.student_id,
      auth.users.email::text,
      coalesce(membership_admin.added_to_email_list, false) as added_to_email_list,
      profiles.phone_number,
      coalesce(blanket_waiver_flags.blanket_waiver, false) as blanket_waiver,
      membership_admin.directory_notes as notes,
      case
        when coalesce(profiles.emergency_contact_consent_to_share, false)
          then profiles.emergency_contact_name
        else null
      end as emergency_contact,
      coalesce(latest_membership.status::text, 'account_created') as status,
      case
        when coalesce(profiles.emergency_contact_consent_to_share, false)
          then profiles.emergency_contact_phone
        else null
      end as emergency_contact_phone,
      coalesce(profiles.emergency_contact_consent_to_share, false) as consent_to_share,
      auth.users.created_at as account_created_at,
      latest_membership.membership_year_start,
      latest_membership.membership_year_end,
      profiles.affiliation,
      profiles.display_name,
      auth.users.id as user_id,
      latest_membership.id as membership_id
    from auth.users
    left join public.profiles on profiles.id = auth.users.id
    left join latest_membership on latest_membership.user_id = auth.users.id
    left join public.membership_admin on membership_admin.membership_id = latest_membership.id
    left join role_flags on role_flags.user_id = auth.users.id
    left join blanket_waiver_flags on blanket_waiver_flags.user_id = auth.users.id
    where (p_status is null or coalesce(latest_membership.status::text, 'account_created') = p_status::text)
      and (
        p_role is null
        or exists (
          select 1
          from public.user_roles as filtered_roles
          where filtered_roles.user_id = auth.users.id
            and filtered_roles.role = p_role
        )
        or (
          p_role = 'member'::public.app_role
          and not exists (
            select 1
            from public.user_roles as filtered_roles
            where filtered_roles.user_id = auth.users.id
          )
        )
      )
      and (
        normalized_search is null
        or auth.users.email ilike '%' || normalized_search || '%'
        or profiles.first_name ilike '%' || normalized_search || '%'
        or profiles.last_name ilike '%' || normalized_search || '%'
        or profiles.display_name ilike '%' || normalized_search || '%'
        or profiles.student_id ilike '%' || normalized_search || '%'
      )
      and (
        p_has_signed_waiver is null
        or coalesce(blanket_waiver_flags.blanket_waiver, false) = p_has_signed_waiver
      )
  )
  select * from export_rows
  order by lower(export_rows.last_name), lower(export_rows.first_name), lower(coalesce(export_rows.email, ''))
  limit max_export_rows + 1;

  get diagnostics exported_count = row_count;

  if exported_count > max_export_rows then
    raise exception using errcode = '54000', message = 'member export too large';
  end if;

  insert into public.audit_log (actor_id, action, entity_type, metadata)
  values (
    p_actor_id,
    'member_directory.exported',
    'member_directory',
    jsonb_build_object(
      'row_count', exported_count,
      'purpose', p_purpose,
      'status', coalesce(p_status::text, 'all'),
      'role', coalesce(p_role::text, 'all'),
      'has_signed_waiver', coalesce(p_has_signed_waiver::text, 'all'),
      'has_search', normalized_search is not null
    )
  );
end;
$$;

revoke all on function public.export_member_directory(uuid, text, text, public.membership_status, public.app_role, text, boolean) from public, anon, authenticated;
grant execute on function public.export_member_directory(uuid, text, text, public.membership_status, public.app_role, text, boolean) to service_role;

create or replace function public.list_signed_waiver_exports(
  p_waiver_id uuid default null,
  p_status public.signed_waiver_status default null
)
returns table (
  id uuid,
  waiver_id uuid,
  user_id uuid,
  object_path text,
  status public.signed_waiver_status,
  submitted_at timestamptz,
  waiver_version text,
  first_name text,
  last_name text,
  email text
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if not coalesce(private.is_current_user_executive(), false) then
    raise exception using errcode = '42501', message = 'signed waiver export unavailable';
  end if;

  return query
  select
    signed_waivers.id,
    signed_waivers.waiver_id,
    signed_waivers.user_id,
    signed_waivers.object_path,
    signed_waivers.status,
    signed_waivers.submitted_at,
    waivers.version,
    coalesce(profiles.first_name, ''),
    coalesce(profiles.last_name, profiles.last_name_initial, ''),
    auth.users.email::text
  from public.signed_waivers
  join public.waivers on waivers.id = signed_waivers.waiver_id
  left join public.profiles on profiles.id = signed_waivers.user_id
  join auth.users on auth.users.id = signed_waivers.user_id
  where (p_waiver_id is null or signed_waivers.waiver_id = p_waiver_id)
    and (p_status is null or signed_waivers.status = p_status)
  order by signed_waivers.submitted_at desc, signed_waivers.id
  limit 51;
end;
$$;

revoke all on function public.list_signed_waiver_exports(uuid, public.signed_waiver_status) from public;
grant execute on function public.list_signed_waiver_exports(uuid, public.signed_waiver_status) to authenticated;

drop function if exists public.audit_signed_waiver_export(integer, uuid, public.signed_waiver_status);

create or replace function public.audit_signed_waiver_export(
  p_actor_id uuid,
  p_signed_waiver_ids uuid[],
  p_waiver_id uuid default null,
  p_status public.signed_waiver_status default null
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  exported_count integer;
begin
  if (select auth.role()) <> 'service_role'
    or p_actor_id is null
    or p_signed_waiver_ids is null
    or cardinality(p_signed_waiver_ids) < 1
    or cardinality(p_signed_waiver_ids) > 50
    or not exists (
      select 1
      from public.user_roles
      where user_id = p_actor_id
        and role = 'executive'::public.app_role
    ) then
    raise exception using errcode = '42501', message = 'signed waiver export unavailable';
  end if;

  select count(*)::integer
  into exported_count
  from public.signed_waivers
  where id = any (p_signed_waiver_ids)
    and (p_waiver_id is null or waiver_id = p_waiver_id)
    and (p_status is null or status = p_status);

  if exported_count <> cardinality(p_signed_waiver_ids) then
    raise exception using errcode = '42501', message = 'signed waiver export unavailable';
  end if;

  insert into public.audit_log (actor_id, action, entity_type, metadata)
  values (
    p_actor_id,
    'signed_waiver.exported',
    'signed_waiver',
    jsonb_build_object(
      'row_count', exported_count,
      'waiver_id', p_waiver_id,
      'status', coalesce(p_status::text, 'all')
    )
  );
end;
$$;

revoke all on function public.audit_signed_waiver_export(uuid, uuid[], uuid, public.signed_waiver_status) from public, anon, authenticated;
grant execute on function public.audit_signed_waiver_export(uuid, uuid[], uuid, public.signed_waiver_status) to service_role;

create or replace function public.list_signed_waiver_orphans(
  p_before timestamptz,
  p_limit integer default 100
)
returns table (
  object_path text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if not coalesce(private.is_current_user_executive(), false)
    or p_before is null
    or p_before > now()
    or p_limit is null
    or p_limit < 1
    or p_limit > 100 then
    raise exception using errcode = '42501', message = 'signed waiver cleanup unavailable';
  end if;

  return query
  with orphan_objects as (
    select
      objects.name as object_path,
      objects.created_at
    from storage.objects as objects
    left join public.signed_waivers
      on signed_waivers.object_path = objects.name
    left join private.signed_waiver_cleanup_claims as cleanup_claims
      on cleanup_claims.object_path = objects.name
    where objects.bucket_id = 'signed-waivers'
      and signed_waivers.id is null
      and objects.created_at < p_before
      and objects.name ~ '^signed-waivers/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$'
      and objects.metadata ->> 'ucoa_user_id' = (private.storage_signed_waiver_user_id(objects.name))::text
      and (
        cleanup_claims.object_path is null
        or (
          cleanup_claims.claimed_at < clock_timestamp() - interval '1 hour'
          and cleanup_claims.cutoff <= p_before
        )
      )
  ),
  expired_claims as (
    select
      cleanup_claims.object_path,
      coalesce(objects.created_at, cleanup_claims.claimed_at) as created_at
    from private.signed_waiver_cleanup_claims as cleanup_claims
    left join storage.objects as objects
      on objects.bucket_id = 'signed-waivers'
      and objects.name = cleanup_claims.object_path
    left join public.signed_waivers
      on signed_waivers.object_path = cleanup_claims.object_path
    where cleanup_claims.claimed_at < clock_timestamp() - interval '1 hour'
      and cleanup_claims.cutoff <= p_before
      and signed_waivers.id is null
      and (
        objects.name is null
        or (
          objects.created_at < p_before
          and objects.metadata ->> 'ucoa_user_id' = (private.storage_signed_waiver_user_id(cleanup_claims.object_path))::text
        )
      )
  ),
  candidates as (
    select * from orphan_objects
    union
    select * from expired_claims
  )
  select candidates.object_path, candidates.created_at
  from candidates
  order by candidates.created_at, candidates.object_path
  limit p_limit;
end;
$$;

revoke all on function public.list_signed_waiver_orphans(timestamptz, integer) from public;
grant execute on function public.list_signed_waiver_orphans(timestamptz, integer) to authenticated;

create or replace function public.claim_signed_waiver_orphan(
  p_object_path text,
  p_before timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  current_actor uuid;
  existing_claimed_at timestamptz;
  existing_cutoff timestamptz;
begin
  current_actor := auth.uid();

  if not coalesce(private.is_current_user_executive(), false)
    or current_actor is null
    or p_before is null
    or p_before > now()
    or private.storage_signed_waiver_user_id(p_object_path) is null
    or private.storage_signed_waiver_id(p_object_path) is null then
    raise exception using errcode = '42501', message = 'signed waiver cleanup unavailable';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_object_path, 0)
  );

  select claimed_at, cutoff
  into existing_claimed_at, existing_cutoff
  from private.signed_waiver_cleanup_claims
  where object_path = p_object_path
  for update;

  if found then
    if existing_claimed_at >= clock_timestamp() - interval '1 hour'
      or p_before < existing_cutoff
      or exists (
        select 1
        from public.signed_waivers
        where object_path = p_object_path
      )
      or exists (
        select 1
        from storage.objects as objects
        where objects.bucket_id = 'signed-waivers'
          and objects.name = p_object_path
          and (
            objects.created_at >= p_before
            or objects.metadata ->> 'ucoa_user_id'
              is distinct from (private.storage_signed_waiver_user_id(objects.name))::text
          )
      ) then
      return false;
    end if;

    update private.signed_waiver_cleanup_claims
    set claimed_by = current_actor,
        cutoff = p_before,
        claimed_at = clock_timestamp()
    where object_path = p_object_path;
  else
    if not exists (
      select 1
      from storage.objects as objects
      left join public.signed_waivers
        on signed_waivers.object_path = objects.name
      where objects.bucket_id = 'signed-waivers'
        and objects.name = p_object_path
        and signed_waivers.id is null
        and objects.created_at < p_before
        and objects.metadata ->> 'ucoa_user_id' = (private.storage_signed_waiver_user_id(objects.name))::text
    ) then
      return false;
    end if;

    insert into private.signed_waiver_cleanup_claims (
      object_path,
      claimed_by,
      cutoff,
      claimed_at
    )
    values (
      p_object_path,
      current_actor,
      p_before,
      clock_timestamp()
    );
  end if;

  insert into public.audit_log (actor_id, action, entity_type, metadata)
  values (
    current_actor,
    'signed_waiver.cleanup_claimed',
    'signed_waiver',
    jsonb_build_object(
      'row_count', 1,
      'object_path', p_object_path,
      'before', p_before
    )
  );

  return true;
end;
$$;

revoke all on function public.claim_signed_waiver_orphan(text, timestamptz) from public;
grant execute on function public.claim_signed_waiver_orphan(text, timestamptz) to authenticated;

create or replace function public.audit_signed_waiver_cleanup(
  p_actor_id uuid,
  p_object_paths text[],
  p_before timestamptz
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  claimed_count integer;
  locked_path text;
begin
  if (select auth.role()) <> 'service_role'
    or p_actor_id is null
    or p_object_paths is null
    or cardinality(p_object_paths) < 1
    or cardinality(p_object_paths) > 100
    or p_before is null
    or p_before > now()
    or exists (
      select 1
      from unnest(p_object_paths) as paths(path)
      where path !~ '^signed-waivers/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$'
    )
    or not exists (
      select 1
      from public.user_roles
      where user_id = p_actor_id
        and role = 'executive'::public.app_role
    ) then
    raise exception using errcode = '42501', message = 'signed waiver cleanup unavailable';
  end if;

  for locked_path in
    select distinct paths.path
    from unnest(p_object_paths) as paths(path)
    order by paths.path
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(locked_path, 0)
    );
  end loop;

  if exists (
    select 1
    from unnest(p_object_paths) as paths(path)
    left join private.signed_waiver_cleanup_claims as cleanup_claims
      on cleanup_claims.object_path = paths.path
    where cleanup_claims.object_path is null
      or cleanup_claims.claimed_by is distinct from p_actor_id
      or cleanup_claims.cutoff is distinct from p_before
  ) then
    raise exception using errcode = '42501', message = 'signed waiver cleanup unavailable';
  end if;

  delete from private.signed_waiver_cleanup_claims as cleanup_claims
  where cleanup_claims.object_path = any (p_object_paths)
    and cleanup_claims.claimed_by = p_actor_id
    and cleanup_claims.cutoff = p_before;

  get diagnostics claimed_count = row_count;

  if claimed_count <> cardinality(p_object_paths) then
    raise exception using errcode = '42501', message = 'signed waiver cleanup unavailable';
  end if;

  insert into public.audit_log (actor_id, action, entity_type, metadata)
  values (
    p_actor_id,
    'signed_waiver.cleaned_up',
    'signed_waiver',
    jsonb_build_object(
      'row_count', claimed_count,
      'object_paths', to_jsonb(p_object_paths),
      'before', p_before
    )
  );
end;
$$;

revoke all on function public.audit_signed_waiver_cleanup(uuid, text[], timestamptz) from public, anon, authenticated;
grant execute on function public.audit_signed_waiver_cleanup(uuid, text[], timestamptz) to service_role;

create or replace function public.audit_signed_waiver_upload_compensation_failure(
  p_actor_id uuid,
  p_waiver_id uuid,
  p_object_path text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  storage_object_present boolean;
begin
  if (select auth.role()) is distinct from 'service_role'
    or p_actor_id is null
    or p_waiver_id is null
    or private.storage_signed_waiver_user_id(p_object_path) is distinct from p_actor_id
    or private.storage_signed_waiver_id(p_object_path) is distinct from p_waiver_id
    or exists (
      select 1
      from public.signed_waivers
      where object_path = p_object_path
    ) then
    raise exception using errcode = '42501', message = 'signed waiver cleanup unavailable';
  end if;

  select exists (
    select 1
    from storage.objects
    where bucket_id = 'signed-waivers'
      and name = p_object_path
  )
  into storage_object_present;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    p_actor_id,
    'signed_waiver.upload_compensation_failed',
    'signed_waiver',
    p_waiver_id,
    jsonb_build_object(
      'object_path', p_object_path,
      'storage_object_present', storage_object_present
    )
  );
end;
$$;

revoke all on function public.audit_signed_waiver_upload_compensation_failure(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.audit_signed_waiver_upload_compensation_failure(uuid, uuid, text) to service_role;

create or replace function public.audit_signed_waiver_replacement_cleanup_failure(
  p_actor_id uuid,
  p_waiver_id uuid,
  p_object_path text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  signed_waiver_id uuid;
  storage_object_present boolean;
begin
  if (select auth.role()) is distinct from 'service_role'
    or p_actor_id is null
    or p_waiver_id is null
    or private.storage_signed_waiver_user_id(p_object_path) is distinct from p_actor_id
    or private.storage_signed_waiver_id(p_object_path) is distinct from p_waiver_id
    or exists (
      select 1
      from public.signed_waivers
      where object_path = p_object_path
    )
    or not exists (
      select 1
      from public.signed_waivers
      where waiver_id = p_waiver_id
        and user_id = p_actor_id
        and object_path is distinct from p_object_path
    ) then
    raise exception using errcode = '42501', message = 'signed waiver cleanup unavailable';
  end if;

  select id
  into signed_waiver_id
  from public.signed_waivers
  where waiver_id = p_waiver_id
    and user_id = p_actor_id;

  select exists (
    select 1
    from storage.objects
    where bucket_id = 'signed-waivers'
      and name = p_object_path
  )
  into storage_object_present;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    p_actor_id,
    'signed_waiver.replacement_cleanup_failed',
    'signed_waiver',
    signed_waiver_id,
    jsonb_build_object(
      'waiver_id', p_waiver_id,
      'user_id', p_actor_id,
      'object_path', p_object_path,
      'storage_object_present', storage_object_present
    )
  );
end;
$$;

revoke all on function public.audit_signed_waiver_replacement_cleanup_failure(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.audit_signed_waiver_replacement_cleanup_failure(uuid, uuid, text) to service_role;

create or replace function public.review_signed_waiver(
  p_signed_waiver_id uuid,
  p_status public.signed_waiver_status
)
returns table (
  id uuid,
  status public.signed_waiver_status,
  reviewed_by uuid,
  reviewed_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  current_status public.signed_waiver_status;
  reviewed_id uuid;
  reviewed_status public.signed_waiver_status;
  reviewed_actor uuid;
  reviewed_time timestamptz;
begin
  if not coalesce(private.is_current_user_executive(), false)
    or p_signed_waiver_id is null
    or p_status is null
    or p_status = 'submitted'::public.signed_waiver_status then
    raise exception using errcode = '42501', message = 'signed waiver review unavailable';
  end if;

  select signed_waivers.status
  into current_status
  from public.signed_waivers
  where signed_waivers.id = p_signed_waiver_id
  for update;

  if not found
    or not (
      (current_status = 'submitted'::public.signed_waiver_status
        and p_status in ('approved'::public.signed_waiver_status, 'rejected'::public.signed_waiver_status))
      or (current_status = 'rejected'::public.signed_waiver_status
        and p_status = 'approved'::public.signed_waiver_status)
      or (current_status = 'approved'::public.signed_waiver_status
        and p_status = 'revoked'::public.signed_waiver_status)
    ) then
    raise exception using errcode = 'P0001', message = 'signed waiver review unavailable';
  end if;

  if p_status = 'approved'::public.signed_waiver_status
    and not exists (
      select 1
      from public.signed_waivers
      join storage.objects
        on storage.objects.bucket_id = 'signed-waivers'
       and storage.objects.name = signed_waivers.object_path
      where signed_waivers.id = p_signed_waiver_id
    ) then
    raise exception using errcode = 'P0001', message = 'signed waiver review unavailable';
  end if;

  update public.signed_waivers
  set status = p_status,
      reviewed_by = auth.uid(),
      reviewed_at = timezone('utc', now())
  where signed_waivers.id = p_signed_waiver_id
    and signed_waivers.status = current_status
  returning signed_waivers.id, signed_waivers.status, signed_waivers.reviewed_by, signed_waivers.reviewed_at
  into reviewed_id, reviewed_status, reviewed_actor, reviewed_time;

  if not found then
    raise exception using errcode = 'P0001', message = 'signed waiver review unavailable';
  end if;

  return query select reviewed_id, reviewed_status, reviewed_actor, reviewed_time;
end;
$$;

revoke all on function public.review_signed_waiver(uuid, public.signed_waiver_status) from public;
grant execute on function public.review_signed_waiver(uuid, public.signed_waiver_status) to authenticated;

update public.waivers
set member_downloadable = true
where version = '2026-2027-club-approved-activities';

create or replace function private.can_current_user_read_waiver_document(p_name text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.waivers
    where document_reference = (select private.storage_waiver_document_path(p_name))
      and (
        (
          status = 'approved'::public.waiver_status
          and (
            (member_downloadable and (select private.is_current_user_active_member()))
            or (select private.can_current_user_read_waiver(waivers.id))
          )
        )
        or (select private.is_current_user_executive())
        or exists (
          select 1
          from public.event_private_details as details
          where details.waiver_id = waivers.id
            and (select private.can_current_user_manage_event(details.event_id))
        )
      )
  );
$$;

revoke all on function private.can_current_user_read_waiver_document(text) from public;
grant execute on function private.can_current_user_read_waiver_document(text) to authenticated;