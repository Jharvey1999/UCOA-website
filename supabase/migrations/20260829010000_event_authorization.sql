create type public.event_status as enum (
  'draft',
  'published',
  'cancelled',
  'completed'
);

create type public.event_visibility as enum (
  'public',
  'members_only'
);

create type public.event_activity_type as enum (
  'hike',
  'scramble',
  'climbing',
  'camping',
  'course',
  'social',
  'other'
);

create type public.recurrence_frequency as enum (
  'daily',
  'weekly',
  'monthly'
);

create or replace function private.is_valid_timezone(p_timezone text)
returns boolean
language sql
stable
set search_path = pg_catalog
as $$
  select exists (
    select 1
    from pg_catalog.pg_timezone_names
    where name = p_timezone
  );
$$;

create or replace function private.is_trusted_system_actor()
returns boolean
language sql
stable
set search_path = pg_catalog
as $$
  select session_user = 'postgres'
    or coalesce(current_setting('request.jwt.claim.role', true), '') in ('service_role', 'supabase_admin');
$$;

create table public.event_series (
  id uuid primary key default extensions.gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete restrict,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  activity_type public.event_activity_type not null,
  difficulty text check (
    difficulty is null or char_length(btrim(difficulty)) between 1 and 40
  ),
  timezone_name text not null default 'America/Edmonton',
  recurrence_frequency public.recurrence_frequency not null,
  recurrence_interval smallint not null default 1 check (recurrence_interval between 1 and 52),
  recurrence_weekdays smallint[] not null default '{}'::smallint[],
  starts_on date not null,
  ends_on date not null,
  max_instances integer not null default 366 check (max_instances between 1 and 366),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint event_series_date_order check (starts_on <= ends_on),
  constraint event_series_weekdays_valid check (
    recurrence_frequency <> 'weekly'
    or (
      cardinality(recurrence_weekdays) between 1 and 7
      and recurrence_weekdays <@ array[0, 1, 2, 3, 4, 5, 6]::smallint[]
    )
  ),
  constraint event_series_timezone_valid check (private.is_valid_timezone(timezone_name))
);

create table public.events (
  id uuid primary key default extensions.gen_random_uuid(),
  series_id uuid references public.event_series(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  public_summary text not null check (char_length(btrim(public_summary)) between 1 and 2400),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  timezone_name text not null default 'America/Edmonton',
  activity_type public.event_activity_type not null,
  difficulty text check (
    difficulty is null or char_length(btrim(difficulty)) between 1 and 40
  ),
  visibility public.event_visibility not null default 'public',
  status public.event_status not null default 'draft',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint events_time_order check (starts_at < ends_at),
  constraint events_timezone_valid check (private.is_valid_timezone(timezone_name))
);

create table public.event_private_details (
  event_id uuid primary key references public.events(id) on delete cascade,
  member_description text not null check (
    char_length(btrim(member_description)) between 1 and 12000
  ),
  exact_location text check (
    exact_location is null or char_length(btrim(exact_location)) between 1 and 600
  ),
  waiver_required boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.event_hosts (
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete restrict,
  assigned_by uuid not null references auth.users(id) on delete restrict,
  assigned_at timestamptz not null default timezone('utc', now()),
  primary key (event_id, user_id)
);

create index event_series_created_by_idx
  on public.event_series (created_by, starts_on, ends_on);

create index events_public_listing_idx
  on public.events (status, visibility, starts_at);

create index events_created_by_idx
  on public.events (created_by, status, starts_at);

create index events_series_idx
  on public.events (series_id, starts_at);

create index event_hosts_user_event_idx
  on public.event_hosts (user_id, event_id);

create or replace function private.is_current_user_organizer()
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
      and role in ('organizer'::public.app_role, 'executive'::public.app_role)
  );
$$;

create or replace function private.is_user_event_host_eligible(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.user_roles
    where user_id = p_user_id
      and role in ('organizer'::public.app_role, 'executive'::public.app_role)
  )
  and exists (
    select 1
    from public.memberships
    where user_id = p_user_id
      and status = 'active'::public.membership_status
      and current_date between membership_year_start and membership_year_end
  );
$$;

create or replace function private.is_current_user_event_host(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.event_hosts
    where event_id = p_event_id
      and user_id = (select auth.uid())
  );
$$;

create or replace function private.can_current_user_bootstrap_event_host(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select (select private.is_current_user_active_member())
    and (select private.is_current_user_organizer())
    and exists (
      select 1
      from public.events
      where id = p_event_id
        and created_by = (select auth.uid())
        and status = 'draft'::public.event_status
    );
$$;

create or replace function private.can_current_user_manage_event(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.events
    where id = p_event_id
  )
  and (
    (select private.is_current_user_executive())
    or (
      (select private.is_current_user_active_member())
      and (select private.is_current_user_organizer())
      and (select private.is_current_user_event_host(p_event_id))
    )
  );
$$;

create or replace function private.can_current_user_manage_series(p_series_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select (select private.is_current_user_executive())
  or (
    (select private.is_current_user_active_member())
    and (select private.is_current_user_organizer())
    and exists (
      select 1
      from public.event_series
      where id = p_series_id
        and created_by = (select auth.uid())
    )
  );
$$;

create or replace function private.can_current_user_read_event_details(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.events
    where id = p_event_id
  )
  and (
    (select private.is_current_user_executive())
    or (
      (select private.is_current_user_active_member())
      and exists (
        select 1
        from public.events
        where id = p_event_id
          and status in (
            'published'::public.event_status,
            'cancelled'::public.event_status,
            'completed'::public.event_status
          )
      )
    )
    or (select private.can_current_user_manage_event(p_event_id))
  );
$$;

create or replace function private.validate_event_series_reference()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if (select auth.uid()) is null then
    if not (select private.is_trusted_system_actor()) then
      raise exception using
        errcode = '42501',
        message = 'event series reference requires a trusted actor';
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' and new.series_id is not distinct from old.series_id then
    return new;
  end if;

  if new.series_id is not null
    and not (select private.is_current_user_executive())
    and not exists (
      select 1
      from public.event_series
      where id = new.series_id
        and created_by = (select auth.uid())
    ) then
    raise exception using
      errcode = '42501',
      message = 'event series must be owned by the current organizer';
  end if;

  return new;
end;
$$;

create or replace function private.prevent_event_creator_change()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  if old.created_by <> new.created_by then
    raise exception using
      errcode = '42501',
      message = 'event creator cannot be changed';
  end if;
  return new;
end;
$$;

create or replace function private.validate_event_host()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if not private.is_user_event_host_eligible(new.user_id) then
    raise exception using
      errcode = '42501',
      message = 'event hosts must be active organizers';
  end if;
  return new;
end;
$$;

create or replace function private.validate_published_event()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if exists (
    select 1
    from public.events
    where status = 'published'::public.event_status
      and not exists (
        select 1
        from public.event_private_details
        where event_id = events.id
      )
  ) then
    raise exception using
      errcode = '23514',
      message = 'published events require private details';
  end if;
  return null;
end;
$$;

create or replace function private.audit_event_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  event_id uuid;
  event_metadata jsonb;
begin
  if tg_table_name = 'events' then
    if tg_op = 'DELETE' then
      event_id := old.id;
      event_metadata := jsonb_build_object('from_status', old.status::text);
    elsif tg_op = 'INSERT' then
      event_id := new.id;
      event_metadata := jsonb_build_object(
        'to_status', new.status::text,
        'visibility', new.visibility::text,
        'activity_type', new.activity_type::text
      );
    else
      event_id := new.id;
      event_metadata := jsonb_build_object(
        'from_status', old.status::text,
        'to_status', new.status::text,
        'visibility', new.visibility::text,
        'activity_type', new.activity_type::text
      );
    end if;
  elsif tg_op = 'DELETE' then
    event_id := old.event_id;
    event_metadata := jsonb_build_object('has_private_details', false);
  else
    event_id := new.event_id;
    event_metadata := jsonb_build_object(
      'has_private_details', true,
      'waiver_required', new.waiver_required
    );
  end if;

  event_metadata := event_metadata || jsonb_build_object(
    'actor_type', case when auth.uid() is null then 'system' else 'user' end
  );

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    case
      when tg_table_name = 'events' and tg_op = 'INSERT' then 'event.created'
      when tg_table_name = 'events' and tg_op = 'UPDATE' then 'event.updated'
      when tg_table_name = 'events' then 'event.deleted'
      when tg_op = 'INSERT' then 'event_private_details.created'
      when tg_op = 'UPDATE' then 'event_private_details.updated'
      else 'event_private_details.deleted'
    end,
    case when tg_table_name = 'events' then 'event' else 'event_private_details' end,
    event_id,
    event_metadata
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function private.audit_event_host_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  event_id uuid;
begin
  event_id := case when tg_op = 'DELETE' then old.event_id else new.event_id end;
  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    case when tg_op = 'INSERT' then 'event_host.created' else 'event_host.deleted' end,
    'event_host',
    event_id,
    jsonb_build_object(
      'actor_type', case when auth.uid() is null then 'system' else 'user' end
    )
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function private.audit_event_series_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  series_id uuid;
begin
  series_id := case when tg_op = 'DELETE' then old.id else new.id end;
  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    case
      when tg_op = 'INSERT' then 'event_series.created'
      when tg_op = 'UPDATE' then 'event_series.updated'
      else 'event_series.deleted'
    end,
    'event_series',
    series_id,
    case
      when tg_op = 'DELETE' then jsonb_build_object(
        'actor_type', case when auth.uid() is null then 'system' else 'user' end
      )
      else jsonb_build_object(
        'activity_type', new.activity_type::text,
        'recurrence_frequency', new.recurrence_frequency::text,
        'starts_on', new.starts_on,
        'ends_on', new.ends_on,
        'actor_type', case when auth.uid() is null then 'system' else 'user' end
      )
    end
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.is_valid_timezone(text) from public;
revoke all on function private.is_trusted_system_actor() from public;
revoke all on function private.is_current_user_organizer() from public;
revoke all on function private.is_user_event_host_eligible(uuid) from public;
revoke all on function private.is_current_user_event_host(uuid) from public;
revoke all on function private.can_current_user_bootstrap_event_host(uuid) from public;
revoke all on function private.can_current_user_manage_event(uuid) from public;
revoke all on function private.can_current_user_manage_series(uuid) from public;
revoke all on function private.can_current_user_read_event_details(uuid) from public;
revoke all on function private.validate_event_series_reference() from public;
revoke all on function private.prevent_event_creator_change() from public;
revoke all on function private.validate_event_host() from public;
revoke all on function private.validate_published_event() from public;
revoke all on function private.audit_event_change() from public;
revoke all on function private.audit_event_host_change() from public;
revoke all on function private.audit_event_series_change() from public;
grant execute on function private.is_valid_timezone(text) to authenticated;
grant execute on function private.is_current_user_organizer() to authenticated;
grant execute on function private.is_current_user_event_host(uuid) to authenticated;
grant execute on function private.can_current_user_bootstrap_event_host(uuid) to authenticated;
grant execute on function private.can_current_user_manage_event(uuid) to authenticated;
grant execute on function private.can_current_user_manage_series(uuid) to authenticated;
grant execute on function private.can_current_user_read_event_details(uuid) to authenticated;

create trigger event_series_set_updated_at
before update on public.event_series
for each row execute function private.set_updated_at();

create trigger event_series_audit_changes
after insert or update or delete on public.event_series
for each row execute function private.audit_event_series_change();

create trigger events_set_updated_at
before update on public.events
for each row execute function private.set_updated_at();

create trigger event_private_details_set_updated_at
before update on public.event_private_details
for each row execute function private.set_updated_at();

create trigger events_creator_immutable
before update on public.events
for each row execute function private.prevent_event_creator_change();

create trigger event_series_creator_immutable
before update on public.event_series
for each row execute function private.prevent_event_creator_change();

create trigger events_series_reference_valid
before insert or update on public.events
for each row execute function private.validate_event_series_reference();

create trigger event_hosts_validate
before insert or update on public.event_hosts
for each row execute function private.validate_event_host();

create constraint trigger events_publication_check
after insert or update on public.events
deferrable initially deferred
for each row execute function private.validate_published_event();

create constraint trigger event_private_details_publication_check
after insert or update or delete on public.event_private_details
deferrable initially deferred
for each row execute function private.validate_published_event();

create trigger events_audit_changes
after insert or update or delete on public.events
for each row execute function private.audit_event_change();

create trigger event_private_details_audit_changes
after insert or update or delete on public.event_private_details
for each row execute function private.audit_event_change();

create trigger event_hosts_audit_changes
after insert or delete on public.event_hosts
for each row execute function private.audit_event_host_change();

alter table public.event_series enable row level security;
alter table public.events enable row level security;
alter table public.event_private_details enable row level security;
alter table public.event_hosts enable row level security;

revoke all on table public.event_series from anon, authenticated;
revoke all on table public.events from anon, authenticated;
revoke all on table public.event_private_details from anon, authenticated;
revoke all on table public.event_hosts from anon, authenticated;

grant select, insert, update, delete on table public.event_series to authenticated;
grant insert, update on table public.events to authenticated;
grant select (
  id,
  title,
  public_summary,
  starts_at,
  ends_at,
  timezone_name,
  activity_type,
  difficulty,
  visibility,
  status
) on table public.events to anon, authenticated;
grant select, insert, update, delete on table public.event_private_details to authenticated;
grant select (event_id, user_id) on table public.event_hosts to authenticated;
grant insert (event_id, user_id, assigned_by) on table public.event_hosts to authenticated;
grant delete on table public.event_hosts to authenticated;

create view public.event_management
with (security_barrier = true)
as
select
  events.id,
  events.series_id,
  events.created_by,
  events.title,
  events.public_summary,
  events.starts_at,
  events.ends_at,
  events.timezone_name,
  events.activity_type,
  events.difficulty,
  events.visibility,
  events.status,
  events.created_at,
  events.updated_at
from public.events
where private.can_current_user_manage_event(events.id);

revoke all on table public.event_management from anon, authenticated;
grant select on table public.event_management to authenticated;

create policy event_series_select_owner_or_executive
on public.event_series for select to authenticated
using ((select private.can_current_user_manage_series(id)));

create policy event_series_insert_organizer_or_executive
on public.event_series for insert to authenticated
with check (
  (select private.is_current_user_executive())
  or (
    (select private.is_current_user_active_member())
    and (select private.is_current_user_organizer())
    and created_by = (select auth.uid())
  )
);

create policy event_series_update_owner_or_executive
on public.event_series for update to authenticated
using ((select private.can_current_user_manage_series(id)))
with check ((select private.can_current_user_manage_series(id)));

create policy event_series_delete_owner_or_executive
on public.event_series for delete to authenticated
using ((select private.can_current_user_manage_series(id)));

create policy events_select_public_anon
on public.events for select to anon
using (
  status in ('published'::public.event_status, 'cancelled'::public.event_status)
  and visibility = 'public'::public.event_visibility
);

create policy events_select_public_authenticated
on public.events for select to authenticated
using (
  status in ('published'::public.event_status, 'cancelled'::public.event_status)
  and visibility = 'public'::public.event_visibility
);

create policy events_select_active_member
on public.events for select to authenticated
using (
  (select private.is_current_user_active_member())
  and status in (
    'published'::public.event_status,
    'cancelled'::public.event_status,
    'completed'::public.event_status
  )
);

create policy events_select_manager
on public.events for select to authenticated
using ((select private.can_current_user_manage_event(id)));

create policy events_insert_organizer_or_executive
on public.events for insert to authenticated
with check (
  (select private.is_current_user_executive())
  or (
    (select private.is_current_user_active_member())
    and (select private.is_current_user_organizer())
    and created_by = (select auth.uid())
    and status = 'draft'::public.event_status
  )
);

create policy events_update_manager
on public.events for update to authenticated
using ((select private.can_current_user_manage_event(id)))
with check ((select private.can_current_user_manage_event(id)));

create policy events_delete_denied
on public.events for delete to authenticated
using (false);

create policy event_private_details_select_member_or_manager
on public.event_private_details for select to authenticated
using ((select private.can_current_user_read_event_details(event_id)));

create policy event_private_details_insert_manager
on public.event_private_details for insert to authenticated
with check ((select private.can_current_user_manage_event(event_id)));

create policy event_private_details_update_manager
on public.event_private_details for update to authenticated
using ((select private.can_current_user_manage_event(event_id)))
with check ((select private.can_current_user_manage_event(event_id)));

create policy event_private_details_delete_manager
on public.event_private_details for delete to authenticated
using ((select private.can_current_user_manage_event(event_id)));

create policy event_hosts_select_member_or_manager
on public.event_hosts for select to authenticated
using (
  (select private.is_current_user_executive())
  or (
    (select private.is_current_user_active_member())
    and exists (
      select 1
      from public.events
      where id = event_id
        and status <> 'draft'::public.event_status
    )
  )
  or (select private.can_current_user_manage_event(event_id))
);

create policy event_hosts_insert_executive_or_self
on public.event_hosts for insert to authenticated
with check (
  (
    (select private.is_current_user_executive())
    and assigned_by = (select auth.uid())
  )
  or (
    (select private.is_current_user_active_member())
    and (select private.is_current_user_organizer())
    and user_id = (select auth.uid())
    and assigned_by = (select auth.uid())
    and (select private.can_current_user_bootstrap_event_host(event_id))
  )
);

create policy event_hosts_update_denied
on public.event_hosts for update to authenticated
using (false)
with check (false);

create policy event_hosts_delete_executive_or_self
on public.event_hosts for delete to authenticated
using (
  (select private.is_current_user_executive())
  or (
    user_id = (select auth.uid())
    and (select private.can_current_user_manage_event(event_id))
  )
);