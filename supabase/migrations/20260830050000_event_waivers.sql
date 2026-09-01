create type public.waiver_status as enum (
  'draft',
  'approved',
  'retired'
);

create type public.waiver_acknowledgement_method as enum (
  'built_in',
  'external',
  'organizer_recorded'
);

create type public.waiver_acknowledgement_status as enum (
  'acknowledged',
  'revoked'
);

create table public.waivers (
  id uuid primary key default extensions.gen_random_uuid(),
  version text not null check (char_length(btrim(version)) between 1 and 80),
  acknowledgement_method public.waiver_acknowledgement_method not null,
  document_reference text not null check (
    char_length(btrim(document_reference)) between 1 and 600
  ),
  status public.waiver_status not null default 'draft',
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (version),
  constraint waivers_approval_metadata_valid check (
    status <> 'approved'
    or (approved_by is not null and approved_at is not null)
  )
);

create table public.waiver_acknowledgements (
  id uuid primary key default extensions.gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete restrict,
  waiver_id uuid not null references public.waivers(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  status public.waiver_acknowledgement_status not null default 'acknowledged',
  acknowledged_at timestamptz not null default timezone('utc', now()),
  evidence_reference text not null check (
    char_length(btrim(evidence_reference)) between 1 and 600
  ),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint waiver_acknowledgements_event_user_version_key
    unique (event_id, user_id, waiver_id)
);

alter table public.event_private_details
  add column waiver_id uuid references public.waivers(id) on delete restrict;

create index waivers_status_idx
  on public.waivers (status, approved_at desc);

create index waiver_acknowledgements_event_user_idx
  on public.waiver_acknowledgements (event_id, user_id, status);

create index waiver_acknowledgements_waiver_idx
  on public.waiver_acknowledgements (waiver_id, status);

create index event_private_details_waiver_idx
  on public.event_private_details (waiver_id);

alter table public.waivers enable row level security;
alter table public.waiver_acknowledgements enable row level security;

create or replace function private.audit_waiver_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    case
      when tg_op = 'INSERT' then 'waiver.created'
      when tg_op = 'UPDATE' then 'waiver.updated'
      else 'waiver.deleted'
    end,
    'waiver',
    case when tg_op = 'DELETE' then old.id else new.id end,
    case
      when tg_op = 'DELETE' then jsonb_build_object(
        'version', old.version,
        'status', old.status::text,
        'actor_type', case when auth.uid() is null then 'system' else 'user' end
      )
      else jsonb_build_object(
        'version', new.version,
        'status', new.status::text,
        'acknowledgement_method', new.acknowledgement_method::text,
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

create or replace function private.audit_waiver_acknowledgement_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    case
      when tg_op = 'INSERT' then 'waiver_acknowledgement.created'
      when new.status = 'revoked'::public.waiver_acknowledgement_status
        then 'waiver_acknowledgement.revoked'
      else 'waiver_acknowledgement.updated'
    end,
    'waiver_acknowledgement',
    new.id,
    jsonb_build_object(
      'event_id', new.event_id,
      'waiver_id', new.waiver_id,
      'status', new.status::text,
      'actor_type', case when auth.uid() is null then 'system' else 'user' end
    )
  );
  return new;
end;
$$;

create or replace function private.audit_event_waiver_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if old.waiver_id is not distinct from new.waiver_id then
    return new;
  end if;

  insert into public.audit_log (actor_id, action, entity_type, entity_id, metadata)
  values (
    auth.uid(),
    'event.waiver_updated',
    'event',
    new.event_id,
    jsonb_build_object(
      'has_waiver_reference', new.waiver_id is not null,
      'waiver_id', new.waiver_id,
      'waiver_required', new.waiver_required,
      'actor_type', case when auth.uid() is null then 'system' else 'user' end
    )
  );
  return new;
end;
$$;

revoke all on function private.audit_waiver_change() from public;
revoke all on function private.audit_waiver_acknowledgement_change() from public;
revoke all on function private.audit_event_waiver_change() from public;

create trigger waivers_set_updated_at
before update on public.waivers
for each row execute function private.set_updated_at();

create trigger waiver_acknowledgements_set_updated_at
before update on public.waiver_acknowledgements
for each row execute function private.set_updated_at();

create trigger waivers_audit_changes
after insert or update or delete on public.waivers
for each row execute function private.audit_waiver_change();

create trigger waiver_acknowledgements_audit_changes
after insert or update on public.waiver_acknowledgements
for each row execute function private.audit_waiver_acknowledgement_change();

create trigger event_private_details_waiver_audit
after update of waiver_id on public.event_private_details
for each row execute function private.audit_event_waiver_change();

revoke all on table public.waivers from anon, authenticated;
revoke all on table public.waiver_acknowledgements from anon, authenticated;

grant select, insert, update, delete on table public.waivers to authenticated;
grant select on table public.waiver_acknowledgements to authenticated;

create or replace function private.can_current_user_read_waiver(p_waiver_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.event_private_details as details
    where details.waiver_id = p_waiver_id
      and (select private.can_current_user_read_event_details(details.event_id))
  );
$$;

revoke all on function private.can_current_user_read_waiver(uuid) from public;
grant execute on function private.can_current_user_read_waiver(uuid) to authenticated;

create policy waivers_select_approved_for_allowed_event
on public.waivers for select to authenticated
using (
  (
    status = 'approved'::public.waiver_status
    and (select private.can_current_user_read_waiver(waivers.id))
  )
  or (select private.is_current_user_executive())
);

create policy waivers_insert_executive
on public.waivers for insert to authenticated
with check (
  (select private.is_current_user_executive())
  and (approved_by is null or approved_by = (select auth.uid()))
);

create policy waivers_update_executive
on public.waivers for update to authenticated
using ((select private.is_current_user_executive()))
with check (
  (select private.is_current_user_executive())
  and (approved_by is null or approved_by = (select auth.uid()))
);

create policy waivers_delete_executive
on public.waivers for delete to authenticated
using ((select private.is_current_user_executive()));

create policy waiver_acknowledgements_select_own_or_manager
on public.waiver_acknowledgements for select to authenticated
using (
  (
    user_id = (select auth.uid())
    and (select private.is_current_user_active_member())
    and (select private.can_current_user_read_event_details(event_id))
  )
  or (select private.can_current_user_manage_event(event_id))
  or (select private.is_current_user_executive())
);

create policy waiver_acknowledgements_insert_denied
on public.waiver_acknowledgements for insert to authenticated
with check (false);

create policy waiver_acknowledgements_update_denied
on public.waiver_acknowledgements for update to authenticated
using (false)
with check (false);

create policy waiver_acknowledgements_delete_denied
on public.waiver_acknowledgements for delete to authenticated
using (false);

create or replace function private.is_event_waiver_complete(
  p_event_id uuid,
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.event_private_details as details
    join public.waivers as waivers
      on waivers.id = details.waiver_id
    join public.waiver_acknowledgements as acknowledgements
      on acknowledgements.event_id = details.event_id
     and acknowledgements.waiver_id = waivers.id
     and acknowledgements.user_id = p_user_id
     and acknowledgements.status = 'acknowledged'::public.waiver_acknowledgement_status
    where details.event_id = p_event_id
      and details.waiver_required
      and waivers.status = 'approved'::public.waiver_status
  );
$$;

create or replace function public.get_event_waiver_status(p_event_id uuid)
returns table (
  event_id uuid,
  waiver_required boolean,
  waiver_id uuid,
  version text,
  acknowledgement_method public.waiver_acknowledgement_method,
  document_reference text,
  acknowledgement_status public.waiver_acknowledgement_status
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  details_required boolean;
  selected_waiver_id uuid;
  selected_version text;
  selected_method public.waiver_acknowledgement_method;
  selected_reference text;
  selected_status public.waiver_status;
  current_acknowledgement_status public.waiver_acknowledgement_status;
begin
  if (select auth.uid()) is null
    or not (select private.can_current_user_read_event_details(p_event_id)) then
    return;
  end if;

  select details.waiver_required, details.waiver_id
  into details_required, selected_waiver_id
  from public.event_private_details as details
  where details.event_id = p_event_id;

  if not found then
    return;
  end if;

  if selected_waiver_id is null then
    return query
    select p_event_id, details_required, null::uuid, null::text,
      null::public.waiver_acknowledgement_method, null::text,
      null::public.waiver_acknowledgement_status;
    return;
  end if;

  select
    waivers.version,
    waivers.acknowledgement_method,
    waivers.document_reference,
    waivers.status
  into
    selected_version,
    selected_method,
    selected_reference,
    selected_status
  from public.waivers
  where waivers.id = selected_waiver_id;

  if not found
    or (
      selected_status <> 'approved'::public.waiver_status
      and not (select private.can_current_user_manage_event(p_event_id))
      and not (select private.is_current_user_executive())
    ) then
    return query
    select p_event_id, details_required, null::uuid, null::text,
      null::public.waiver_acknowledgement_method, null::text,
      null::public.waiver_acknowledgement_status;
    return;
  end if;

  select acknowledgements.status
  into current_acknowledgement_status
  from public.waiver_acknowledgements as acknowledgements
  where acknowledgements.event_id = p_event_id
    and acknowledgements.waiver_id = selected_waiver_id
    and acknowledgements.user_id = (select auth.uid());

  return query
  select
    p_event_id,
    details_required,
    selected_waiver_id,
    selected_version,
    selected_method,
    selected_reference,
    current_acknowledgement_status;
end;
$$;

create or replace function public.record_event_waiver_acknowledgement(p_event_id uuid)
returns table (
  event_id uuid,
  waiver_id uuid,
  version text,
  acknowledgement_status public.waiver_acknowledgement_status,
  acknowledged_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  event_status public.event_status;
  details_required boolean;
  selected_waiver_id uuid;
  selected_version text;
  selected_method public.waiver_acknowledgement_method;
  selected_reference text;
  selected_status public.waiver_status;
  acknowledgement_record public.waiver_acknowledgements%rowtype;
begin
  if (select auth.uid()) is null
    or not (select private.is_current_user_active_member()) then
    raise exception using
      errcode = '42501',
      message = 'event waiver unavailable';
  end if;

  select events.status
  into event_status
  from public.events
  where events.id = p_event_id
  for update;

  if not found or event_status <> 'published'::public.event_status then
    raise exception using
      errcode = 'P0001',
      message = 'event waiver unavailable';
  end if;

  select details.waiver_required, details.waiver_id
  into details_required, selected_waiver_id
  from public.event_private_details as details
  where details.event_id = p_event_id;

  if not found or not details_required or selected_waiver_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'approved waiver unavailable';
  end if;

  select
    waivers.version,
    waivers.acknowledgement_method,
    waivers.document_reference,
    waivers.status
  into
    selected_version,
    selected_method,
    selected_reference,
    selected_status
  from public.waivers
  where waivers.id = selected_waiver_id;

  if not found or selected_status <> 'approved'::public.waiver_status then
    raise exception using
      errcode = 'P0001',
      message = 'approved waiver unavailable';
  end if;

  if selected_method <> 'built_in'::public.waiver_acknowledgement_method then
    raise exception using
      errcode = 'P0001',
      message = 'approved waiver workflow is external';
  end if;

  insert into public.waiver_acknowledgements (
    event_id,
    waiver_id,
    user_id,
    status,
    acknowledged_at,
    evidence_reference
  )
  values (
    p_event_id,
    selected_waiver_id,
    (select auth.uid()),
    'acknowledged'::public.waiver_acknowledgement_status,
    timezone('utc', now()),
    selected_reference
  )
  on conflict on constraint waiver_acknowledgements_event_user_version_key do update
  set status = excluded.status,
      acknowledged_at = excluded.acknowledged_at,
      evidence_reference = excluded.evidence_reference
  returning * into acknowledgement_record;

  return query
  select
    acknowledgement_record.event_id,
    acknowledgement_record.waiver_id,
    selected_version,
    acknowledgement_record.status,
    acknowledgement_record.acknowledged_at;
end;
$$;

create or replace function public.set_event_waiver(
  p_event_id uuid,
  p_waiver_id uuid
)
returns table (
  event_id uuid,
  waiver_id uuid,
  waiver_required boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  selected_waiver_status public.waiver_status;
  details_waiver_id uuid;
begin
  if (select auth.uid()) is null
    or not (select private.can_current_user_manage_event(p_event_id)) then
    raise exception using
      errcode = '42501',
      message = 'event unavailable';
  end if;

  perform 1
  from public.events
  where public.events.id = p_event_id
  for update;

  if not found then
    raise exception using
      errcode = '42501',
      message = 'event unavailable';
  end if;

  select details.waiver_id
  into details_waiver_id
  from public.event_private_details as details
  where details.event_id = p_event_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'event private details unavailable';
  end if;

  if p_waiver_id is not null then
    select waivers.status
    into selected_waiver_status
    from public.waivers
    where waivers.id = p_waiver_id;

    if not found or selected_waiver_status <> 'approved'::public.waiver_status then
      raise exception using
        errcode = 'P0001',
        message = 'approved waiver unavailable';
    end if;
  end if;

  update public.event_private_details as details
  set waiver_id = p_waiver_id,
      waiver_required = p_waiver_id is not null
  where details.event_id = p_event_id;

  return query
  select p_event_id, p_waiver_id, p_waiver_id is not null;
end;
$$;

revoke all on function public.get_event_waiver_status(uuid) from public, anon, authenticated, service_role;
revoke all on function public.record_event_waiver_acknowledgement(uuid) from public, anon, authenticated, service_role;
revoke all on function public.set_event_waiver(uuid, uuid) from public, anon, authenticated, service_role;
grant execute on function public.get_event_waiver_status(uuid) to authenticated;
grant execute on function public.record_event_waiver_acknowledgement(uuid) to authenticated;
grant execute on function public.set_event_waiver(uuid, uuid) to authenticated;

revoke all on table public.event_private_details from authenticated;
grant select (
  event_id,
  member_description,
  exact_location,
  waiver_required
) on table public.event_private_details to authenticated;
grant insert (
  event_id,
  member_description,
  exact_location,
  waiver_required
) on table public.event_private_details to authenticated;
grant update (
  member_description,
  exact_location,
  waiver_required
) on table public.event_private_details to authenticated;
grant delete on table public.event_private_details to authenticated;

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

  select details.waiver_required
  into event_waiver_required
  from public.event_private_details as details
  where details.event_id = p_event_id;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'event registration unavailable';
  end if;

  if event_waiver_required
    and not (select private.is_event_waiver_complete(p_event_id, current_user_id)) then
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

  select details.waiver_required
  into event_waiver_required
  from public.event_private_details as details
  where details.event_id = p_event_id;

  if not found then
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
    and (
      not event_waiver_required
      or (select private.is_event_waiver_complete(p_event_id, event_registrations.user_id))
    )
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

revoke all on function private.is_event_waiver_complete(uuid, uuid) from public;
grant execute on function private.is_event_waiver_complete(uuid, uuid) to authenticated;
