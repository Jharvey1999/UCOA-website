create extension if not exists "pgcrypto" with schema extensions;

create schema if not exists private;

create type public.membership_status as enum (
  'account_created',
  'pending',
  'needs_verification',
  'active',
  'expired',
  'rejected',
  'suspended'
);

create type public.app_role as enum (
  'member',
  'organizer',
  'executive'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null check (char_length(btrim(first_name)) between 1 and 80),
  last_name_initial text check (
    last_name_initial is null or last_name_initial ~ '^[[:alpha:]]$'
  ),
  display_name text check (
    display_name is null or char_length(btrim(display_name)) between 1 and 120
  ),
  affiliation text check (
    affiliation is null or char_length(btrim(affiliation)) between 1 and 160
  ),
  profile_photo_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.memberships (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  membership_year_start date,
  membership_year_end date,
  status public.membership_status not null default 'pending',
  application_submitted_at timestamptz not null default timezone('utc', now()),
  approved_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint memberships_dates_together check (
    (membership_year_start is null) = (membership_year_end is null)
  ),
  constraint memberships_date_order check (
    membership_year_start is null or membership_year_start <= membership_year_end
  ),
  constraint memberships_status_dates check (
    status not in ('active', 'expired', 'suspended')
    or (membership_year_start is not null and membership_year_end is not null)
  ),
  constraint memberships_active_approval check (
    status <> 'active' or approved_at is not null
  )
);

create table public.membership_admin (
  membership_id uuid primary key references public.memberships(id) on delete cascade,
  approved_by uuid references auth.users(id) on delete set null,
  payment_verified_at timestamptz,
  payment_verified_by uuid references auth.users(id) on delete set null,
  legacy_reference text,
  executive_note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint membership_admin_payment_verification_together check (
    (payment_verified_at is null) = (payment_verified_by is null)
  )
);

create table public.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null,
  assigned_by uuid not null references auth.users(id) on delete restrict,
  assigned_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, role),
  constraint user_roles_not_self_assigned check (user_id <> assigned_by)
);

create table public.audit_log (
  id uuid primary key default extensions.gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null check (char_length(btrim(action)) between 1 and 80),
  entity_type text not null check (char_length(btrim(entity_type)) between 1 and 80),
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default timezone('utc', now())
);

create unique index memberships_one_record_per_year
  on public.memberships (user_id, membership_year_start)
  where membership_year_start is not null;

create unique index memberships_one_open_application
  on public.memberships (user_id)
  where status in ('pending', 'needs_verification');

create index memberships_user_status_dates_idx
  on public.memberships (user_id, status, membership_year_start, membership_year_end);

create index membership_admin_approved_by_idx
  on public.membership_admin (approved_by);

create index user_roles_user_role_idx
  on public.user_roles (user_id, role);

create index audit_log_entity_idx
  on public.audit_log (entity_type, entity_id, created_at desc);

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function private.is_current_user_executive()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.user_roles
    where user_id = (select auth.uid())
      and role = 'executive'::public.app_role
  );
$$;

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
    where user_id = (select auth.uid())
      and status = 'active'::public.membership_status
      and current_date between membership_year_start and membership_year_end
  );
$$;

create or replace function private.validate_membership_approval()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if exists (
    select 1
    from public.memberships as memberships
    left join public.membership_admin as membership_admin
      on membership_admin.membership_id = memberships.id
    where memberships.status = 'active'::public.membership_status
      and (
        memberships.approved_at is null
        or membership_admin.approved_by is null
      )
  ) then
    raise exception using
      errcode = '23514',
      message = 'active memberships require executive approval';
  end if;

  return null;
end;
$$;

create or replace function private.audit_membership_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  change_metadata jsonb;
begin
  if tg_op = 'INSERT' then
    change_metadata := jsonb_build_object('to_status', new.status::text);
    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (auth.uid(), 'membership.created', 'membership', new.id, change_metadata);
    return new;
  end if;

  if tg_op = 'UPDATE' then
    change_metadata := jsonb_build_object(
      'from_status', old.status::text,
      'to_status', new.status::text
    );
    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (auth.uid(), 'membership.updated', 'membership', new.id, change_metadata);
    return new;
  end if;

  change_metadata := jsonb_build_object('from_status', old.status::text);
  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (auth.uid(), 'membership.deleted', 'membership', old.id, change_metadata);
  return old;
end;
$$;

create or replace function private.audit_role_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      'role.created',
      'user_role',
      new.user_id,
      jsonb_build_object('role', new.role::text)
    );
    return new;
  end if;

  if tg_op = 'UPDATE' then
    insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      'role.updated',
      'user_role',
      new.user_id,
      jsonb_build_object('from_role', old.role::text, 'to_role', new.role::text)
    );
    return new;
  end if;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    'role.deleted',
    'user_role',
    old.user_id,
    jsonb_build_object('role', old.role::text)
  );
  return old;
end;
$$;

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
      '{}'::jsonb
    );
    return old;
  end if;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    case when tg_op = 'INSERT' then 'membership_admin.created' else 'membership_admin.updated' end,
    'membership',
    new.membership_id,
    jsonb_build_object(
      'has_approval', new.approved_by is not null,
      'has_payment_verification', new.payment_verified_at is not null,
      'has_legacy_reference', new.legacy_reference is not null
    )
  );
  return new;
end;
$$;

revoke all on schema private from public;
grant usage on schema private to authenticated;

revoke all on function private.is_current_user_executive() from public;
revoke all on function private.is_current_user_active_member() from public;
revoke all on function private.set_updated_at() from public;
revoke all on function private.validate_membership_approval() from public;
revoke all on function private.audit_membership_change() from public;
revoke all on function private.audit_role_change() from public;
revoke all on function private.audit_membership_admin_change() from public;
grant execute on function private.is_current_user_executive() to authenticated;
grant execute on function private.is_current_user_active_member() to authenticated;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

create trigger memberships_set_updated_at
before update on public.memberships
for each row execute function private.set_updated_at();

create trigger membership_admin_set_updated_at
before update on public.membership_admin
for each row execute function private.set_updated_at();

create trigger memberships_audit_changes
after insert or update or delete on public.memberships
for each row execute function private.audit_membership_change();

create trigger user_roles_audit_changes
after insert or update or delete on public.user_roles
for each row execute function private.audit_role_change();

create trigger membership_admin_audit_changes
after insert or update or delete on public.membership_admin
for each row execute function private.audit_membership_admin_change();

create constraint trigger memberships_approval_check
after insert or update on public.memberships
deferrable initially deferred
for each row execute function private.validate_membership_approval();

create constraint trigger membership_admin_approval_check
after insert or update or delete on public.membership_admin
deferrable initially deferred
for each row execute function private.validate_membership_approval();

alter table public.profiles enable row level security;
alter table public.memberships enable row level security;
alter table public.membership_admin enable row level security;
alter table public.user_roles enable row level security;
alter table public.audit_log enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.memberships from anon, authenticated;
revoke all on table public.membership_admin from anon, authenticated;
revoke all on table public.user_roles from anon, authenticated;
revoke all on table public.audit_log from anon, authenticated;

grant select, insert, update on table public.profiles to authenticated;
grant select, insert, update on table public.memberships to authenticated;
grant select, insert, update, delete on table public.membership_admin to authenticated;
grant select, insert, update, delete on table public.user_roles to authenticated;
grant select on table public.audit_log to authenticated;

create policy profiles_select_own_or_executive
on public.profiles for select to authenticated
using (
  id = (select auth.uid())
  or (select private.is_current_user_executive())
);

create policy profiles_insert_own
on public.profiles for insert to authenticated
with check (id = (select auth.uid()));

create policy profiles_update_own
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy profiles_delete_denied
on public.profiles for delete to authenticated
using (false);

create policy memberships_select_own_or_executive
on public.memberships for select to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_current_user_executive())
);

create policy memberships_insert_applicant_or_executive
on public.memberships for insert to authenticated
with check (
  (
    user_id = (select auth.uid())
    and status = 'pending'::public.membership_status
    and membership_year_start is null
    and membership_year_end is null
    and approved_at is null
  )
  or (select private.is_current_user_executive())
);

create policy memberships_update_executive
on public.memberships for update to authenticated
using ((select private.is_current_user_executive()))
with check ((select private.is_current_user_executive()));

create policy memberships_delete_denied
on public.memberships for delete to authenticated
using (false);

create policy user_roles_select_own_or_executive
on public.user_roles for select to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_current_user_executive())
);

create policy user_roles_insert_executive_other_user
on public.user_roles for insert to authenticated
with check (
  (select private.is_current_user_executive())
  and user_id <> (select auth.uid())
  and assigned_by = (select auth.uid())
);

create policy user_roles_update_executive_other_user
on public.user_roles for update to authenticated
using (
  (select private.is_current_user_executive())
  and user_id <> (select auth.uid())
)
with check (
  (select private.is_current_user_executive())
  and user_id <> (select auth.uid())
  and assigned_by = (select auth.uid())
);

create policy user_roles_delete_executive_other_user
on public.user_roles for delete to authenticated
using (
  (select private.is_current_user_executive())
  and user_id <> (select auth.uid())
);

create policy membership_admin_select_executive
on public.membership_admin for select to authenticated
using ((select private.is_current_user_executive()));

create policy membership_admin_insert_executive
on public.membership_admin for insert to authenticated
with check (
  (select private.is_current_user_executive())
  and (approved_by is null or approved_by = (select auth.uid()))
  and (payment_verified_by is null or payment_verified_by = (select auth.uid()))
);

create policy membership_admin_update_executive
on public.membership_admin for update to authenticated
using ((select private.is_current_user_executive()))
with check (
  (select private.is_current_user_executive())
  and (approved_by is null or approved_by = (select auth.uid()))
  and (payment_verified_by is null or payment_verified_by = (select auth.uid()))
);

create policy membership_admin_delete_executive
on public.membership_admin for delete to authenticated
using ((select private.is_current_user_executive()));

create policy audit_log_select_executive
on public.audit_log for select to authenticated
using ((select private.is_current_user_executive()));

create policy audit_log_insert_denied
on public.audit_log for insert to authenticated
with check (false);

create policy audit_log_update_denied
on public.audit_log for update to authenticated
using (false)
with check (false);

create policy audit_log_delete_denied
on public.audit_log for delete to authenticated
using (false);