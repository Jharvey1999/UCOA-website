create type public.event_registration_status as enum (
  'confirmed',
  'waitlisted',
  'cancelled',
  'attended',
  'no_show'
);

alter table public.events
  add column capacity integer not null default 0,
  add column waitlist_enabled boolean not null default true;

alter table public.events
  add constraint events_capacity_nonnegative check (capacity >= 0);

create table public.event_registrations (
  id uuid primary key default extensions.gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  status public.event_registration_status not null default 'confirmed',
  waitlist_position integer,
  queued_at timestamptz,
  cancelled_at timestamptz,
  promoted_at timestamptz,
  attended_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (event_id, user_id),
  constraint event_registrations_waitlist_state check (
    (
      status = 'waitlisted'
      and waitlist_position is not null
      and waitlist_position >= 1
      and queued_at is not null
    )
    or (
      status <> 'waitlisted'
      and waitlist_position is null
      and queued_at is null
    )
  ),
  constraint event_registrations_cancelled_state check (
    (status = 'cancelled') = (cancelled_at is not null)
  ),
  constraint event_registrations_attendance_state check (
    (attended_at is null) or (status in ('attended', 'no_show'))
  )
);

create index event_registrations_event_status_idx
  on public.event_registrations (event_id, status, waitlist_position, queued_at, id);

create index event_registrations_user_event_idx
  on public.event_registrations (user_id, event_id);

create or replace function private.resequence_event_waitlist(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  with ordered_waitlist as (
    select
      event_registrations.id,
      row_number() over (
        order by event_registrations.waitlist_position, event_registrations.queued_at, event_registrations.id
      )::integer as new_position
    from public.event_registrations
    where event_registrations.event_id = p_event_id
      and event_registrations.status = 'waitlisted'::public.event_registration_status
  )
  update public.event_registrations
  set waitlist_position = ordered_waitlist.new_position
  from ordered_waitlist
  where event_registrations.id = ordered_waitlist.id;
end;
$$;

create or replace function private.is_active_event_participant(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.memberships
    where user_id = p_user_id
      and status = 'active'::public.membership_status
      and current_date between membership_year_start and membership_year_end
  );
$$;

create or replace function private.lock_event_for_registration_policy()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if tg_op = 'DELETE' then
    perform 1
    from public.events
    where id = old.event_id
    for update;
    return old;
  end if;

  perform 1
  from public.events
  where id = new.event_id
  for update;
  return new;
end;
$$;

create or replace function private.promote_next_eligible_event_registration(p_event_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  event_capacity integer;
  event_status public.event_status;
  event_waiver_required boolean;
  confirmed_count integer;
  candidate_id uuid;
begin
  select events.capacity, events.status
  into event_capacity, event_status
  from public.events
  where events.id = p_event_id
  for update;

  if not found or event_status <> 'published'::public.event_status then
    return null;
  end if;

  select event_private_details.waiver_required
  into event_waiver_required
  from public.event_private_details
  where event_private_details.event_id = p_event_id;

  if not found or event_waiver_required then
    return null;
  end if;

  select count(*)::integer
  into confirmed_count
  from public.event_registrations
  where event_registrations.event_id = p_event_id
    and event_registrations.status = 'confirmed'::public.event_registration_status;

  if event_capacity > 0 and confirmed_count >= event_capacity then
    return null;
  end if;

  select event_registrations.id
  into candidate_id
  from public.event_registrations
  where event_registrations.event_id = p_event_id
    and event_registrations.status = 'waitlisted'::public.event_registration_status
    and (select private.is_active_event_participant(event_registrations.user_id))
  order by event_registrations.waitlist_position,
    event_registrations.queued_at,
    event_registrations.id
  limit 1
  for update;

  if not found then
    return null;
  end if;

  update public.event_registrations
  set
    status = 'confirmed'::public.event_registration_status,
    waitlist_position = null,
    queued_at = null,
    cancelled_at = null,
    promoted_at = timezone('utc', now()),
    attended_at = null
  where id = candidate_id;

  return candidate_id;
end;
$$;

create or replace function private.reconcile_event_waitlist(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  promoted_id uuid;
begin
  loop
    promoted_id := private.promote_next_eligible_event_registration(p_event_id);
    exit when promoted_id is null;
  end loop;

  perform private.resequence_event_waitlist(p_event_id);
end;
$$;

create or replace function private.reconcile_event_waitlist_on_capacity_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  perform private.reconcile_event_waitlist(new.id);
  return new;
end;
$$;

create or replace function private.validate_event_capacity_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.capacity <> old.capacity
    and new.capacity > 0
    and (
      select count(*)
      from public.event_registrations
      where event_id = new.id
        and status = 'confirmed'::public.event_registration_status
    ) > new.capacity then
    raise exception using
      errcode = '23514',
      message = 'event capacity cannot be lower than confirmed registrations';
  end if;
  return new;
end;
$$;

create or replace function private.audit_event_registration_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  audit_action text;
begin
  if tg_op = 'UPDATE'
    and old.status = new.status
    and old.waitlist_position is not distinct from new.waitlist_position
    and old.cancelled_at is not distinct from new.cancelled_at
    and old.promoted_at is not distinct from new.promoted_at
    and old.attended_at is not distinct from new.attended_at then
    return new;
  end if;

  audit_action := case
    when tg_op = 'INSERT' then 'event_registration.created'
    when new.status = 'cancelled'::public.event_registration_status then 'event_registration.cancelled'
    when old.status = 'waitlisted'::public.event_registration_status
      and new.status = 'confirmed'::public.event_registration_status then 'event_registration.promoted'
    when old.status = 'cancelled'::public.event_registration_status then 'event_registration.rejoined'
    else 'event_registration.updated'
  end;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    audit_action,
    'event_registration',
    new.id,
    jsonb_build_object(
      'event_id', new.event_id,
      'status', new.status::text,
      'waitlist_position', new.waitlist_position,
      'actor_type', case when auth.uid() is null then 'system' else 'user' end
    )
  );
  return new;
end;
$$;

create or replace function private.audit_event_capacity_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if old.capacity is not distinct from new.capacity
    and old.waitlist_enabled is not distinct from new.waitlist_enabled then
    return new;
  end if;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    'event.capacity_updated',
    'event',
    new.id,
    jsonb_build_object(
      'from_capacity', old.capacity,
      'to_capacity', new.capacity,
      'from_waitlist_enabled', old.waitlist_enabled,
      'to_waitlist_enabled', new.waitlist_enabled,
      'actor_type', case when auth.uid() is null then 'system' else 'user' end
    )
  );
  return new;
end;
$$;

create or replace function public.register_for_event(p_event_id uuid)
returns table (
  registration_id uuid,
  registration_status public.event_registration_status,
  waitlist_position integer
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  current_user_id uuid;
  event_capacity integer;
  event_waitlist_enabled boolean;
  event_waiver_required boolean;
  existing_registration public.event_registrations%rowtype;
  confirmed_count integer;
  target_status public.event_registration_status;
  target_registration_id uuid;
begin
  current_user_id := auth.uid();
  if current_user_id is null
    or not (select private.is_current_user_active_member()) then
    raise exception using
      errcode = '42501',
      message = 'event registration unavailable';
  end if;

  select events.capacity, events.waitlist_enabled
  into event_capacity, event_waitlist_enabled
  from public.events
  where events.id = p_event_id
    and events.status = 'published'::public.event_status
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'event registration unavailable';
  end if;

  select event_private_details.waiver_required
  into event_waiver_required
  from public.event_private_details
  where event_private_details.event_id = p_event_id;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'event registration unavailable';
  end if;

  if event_waiver_required then
    raise exception using
      errcode = 'P0001',
      message = 'approved waiver completion is required before registration';
  end if;

  select event_registrations.*
  into existing_registration
  from public.event_registrations
  where event_registrations.event_id = p_event_id
    and event_registrations.user_id = current_user_id
  for update;

  if existing_registration.id is not null then
    if existing_registration.status in (
      'confirmed'::public.event_registration_status,
      'waitlisted'::public.event_registration_status
    ) then
      return query
      select
        existing_registration.id,
        existing_registration.status,
        existing_registration.waitlist_position;
      return;
    end if;

    if existing_registration.status in (
      'attended'::public.event_registration_status,
      'no_show'::public.event_registration_status
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'event registration is closed';
    end if;
  end if;

  select count(*)::integer
  into confirmed_count
  from public.event_registrations
  where event_registrations.event_id = p_event_id
    and event_registrations.status = 'confirmed'::public.event_registration_status;

  if event_capacity = 0 or confirmed_count < event_capacity then
    target_status := 'confirmed'::public.event_registration_status;
  elsif not event_waitlist_enabled then
    raise exception using
      errcode = 'P0001',
      message = 'event is full';
  else
    target_status := 'waitlisted'::public.event_registration_status;
  end if;

  if existing_registration.id is null then
    insert into public.event_registrations (
      event_id,
      user_id,
      status,
      waitlist_position,
      queued_at
    )
    values (
      p_event_id,
      current_user_id,
      target_status,
      case when target_status = 'waitlisted'::public.event_registration_status
        then coalesce((
          select max(event_registrations.waitlist_position) + 1
          from public.event_registrations
          where event_registrations.event_id = p_event_id
            and event_registrations.status = 'waitlisted'::public.event_registration_status
        ), 1)
        else null
      end,
      case when target_status = 'waitlisted'::public.event_registration_status
        then timezone('utc', now())
        else null
      end
    )
    returning id into target_registration_id;
  else
    update public.event_registrations
    set
      status = target_status,
      waitlist_position = case when target_status = 'waitlisted'::public.event_registration_status
        then coalesce((
          select max(event_registrations.waitlist_position) + 1
          from public.event_registrations
          where event_registrations.event_id = p_event_id
            and event_registrations.status = 'waitlisted'::public.event_registration_status
        ), 1)
        else null
      end,
      queued_at = case when target_status = 'waitlisted'::public.event_registration_status
        then timezone('utc', now())
        else null
      end,
      cancelled_at = null,
      promoted_at = null,
      attended_at = null
    where id = existing_registration.id
    returning id into target_registration_id;
  end if;

  if target_status = 'waitlisted'::public.event_registration_status then
    perform private.resequence_event_waitlist(p_event_id);
  end if;

  return query
  select
    event_registrations.id,
    event_registrations.status,
    event_registrations.waitlist_position
  from public.event_registrations
  where event_registrations.id = target_registration_id;
end;
$$;

create or replace function public.cancel_event_registration(p_event_id uuid)
returns table (
  registration_id uuid,
  registration_status public.event_registration_status,
  waitlist_position integer,
  promoted_registration_id uuid
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  current_user_id uuid;
  event_status public.event_status;
  existing_registration public.event_registrations%rowtype;
  promoted_id uuid;
begin
  current_user_id := auth.uid();
  if current_user_id is null
    or not (select private.is_current_user_active_member()) then
    raise exception using
      errcode = '42501',
      message = 'event registration unavailable';
  end if;

  select events.status
  into event_status
  from public.events
  where events.id = p_event_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'event registration unavailable';
  end if;

  select event_registrations.*
  into existing_registration
  from public.event_registrations
  where event_registrations.event_id = p_event_id
    and event_registrations.user_id = current_user_id
  for update;

  -- Match the unknown-event error exactly so the RPC never discloses
  -- whether an event the caller cannot access exists.
  if existing_registration.id is null then
    raise exception using
      errcode = 'P0001',
      message = 'event registration unavailable';
  end if;

  if existing_registration.status = 'cancelled'::public.event_registration_status then
    return query
    select
      existing_registration.id,
      existing_registration.status,
      existing_registration.waitlist_position,
      null::uuid;
    return;
  end if;

  if event_status <> 'published'::public.event_status then
    raise exception using
      errcode = 'P0001',
      message = 'event registration is closed';
  end if;

  if existing_registration.status not in (
    'confirmed'::public.event_registration_status,
    'waitlisted'::public.event_registration_status
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'event registration is closed';
  end if;

  update public.event_registrations
  set
    status = 'cancelled'::public.event_registration_status,
    waitlist_position = null,
    queued_at = null,
    cancelled_at = timezone('utc', now()),
    promoted_at = null
  where id = existing_registration.id;

  if existing_registration.status = 'confirmed'::public.event_registration_status then
    promoted_id := private.promote_next_eligible_event_registration(p_event_id);
  end if;

  perform private.resequence_event_waitlist(p_event_id);

  return query
  select
    existing_registration.id,
    'cancelled'::public.event_registration_status,
    null::integer,
    promoted_id;
end;
$$;

revoke all on function private.resequence_event_waitlist(uuid) from public;
revoke all on function private.is_active_event_participant(uuid) from public;
revoke all on function private.lock_event_for_registration_policy() from public;
revoke all on function private.promote_next_eligible_event_registration(uuid) from public;
revoke all on function private.reconcile_event_waitlist(uuid) from public;
revoke all on function private.reconcile_event_waitlist_on_capacity_change() from public;
revoke all on function private.validate_event_capacity_change() from public;
revoke all on function private.audit_event_registration_change() from public;
revoke all on function private.audit_event_capacity_change() from public;
revoke all on function public.register_for_event(uuid) from public;
revoke all on function public.cancel_event_registration(uuid) from public;
grant execute on function public.register_for_event(uuid) to authenticated;
grant execute on function public.cancel_event_registration(uuid) to authenticated;

create trigger events_capacity_valid
before update on public.events
for each row execute function private.validate_event_capacity_change();

create trigger events_waitlist_reconcile
after update of capacity on public.events
for each row execute function private.reconcile_event_waitlist_on_capacity_change();

create trigger event_private_details_registration_lock
before insert or update or delete on public.event_private_details
for each row execute function private.lock_event_for_registration_policy();

create trigger event_registrations_set_updated_at
before update on public.event_registrations
for each row execute function private.set_updated_at();

create trigger event_registrations_audit_changes
after insert or update on public.event_registrations
for each row execute function private.audit_event_registration_change();

create trigger events_capacity_audit_changes
after update of capacity, waitlist_enabled on public.events
for each row execute function private.audit_event_capacity_change();

alter table public.event_registrations enable row level security;

revoke all on table public.event_registrations from anon, authenticated;
grant select on table public.event_registrations to authenticated;
grant select (capacity, waitlist_enabled) on table public.events to authenticated;

create policy event_registrations_select_own_or_manager
on public.event_registrations for select to authenticated
using (
  (
    user_id = (select auth.uid())
    and (select private.is_current_user_active_member())
  )
  or (select private.can_current_user_manage_event(event_id))
);

create policy event_registrations_insert_denied
on public.event_registrations for insert to authenticated
with check (false);

create policy event_registrations_update_denied
on public.event_registrations for update to authenticated
using (false)
with check (false);

create policy event_registrations_delete_denied
on public.event_registrations for delete to authenticated
using (false);