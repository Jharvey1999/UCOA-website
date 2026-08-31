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
    when (
      old.status is distinct from new.status
      or old.attended_at is distinct from new.attended_at
    )
      and new.status in (
        'attended'::public.event_registration_status,
        'no_show'::public.event_registration_status
      ) then 'event_registration.attendance_recorded'
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

create or replace function public.record_event_attendance(
  p_event_id uuid,
  p_user_id uuid,
  p_attendance public.event_registration_status
)
returns table (
  registration_id uuid,
  registration_status public.event_registration_status,
  attended_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  event_status public.event_status;
  target_registration public.event_registrations%rowtype;
begin
  if auth.uid() is null
    or not (select private.can_current_user_manage_event(p_event_id)) then
    raise exception using
      errcode = '42501',
      message = 'event attendance unavailable';
  end if;

  if p_attendance is null or p_attendance not in (
    'attended'::public.event_registration_status,
    'no_show'::public.event_registration_status
  ) then
    raise exception using
      errcode = '22023',
      message = 'attendance status is invalid';
  end if;

  select events.status
  into event_status
  from public.events
  where events.id = p_event_id
  for update;

  if not found
    or event_status not in (
      'published'::public.event_status,
      'completed'::public.event_status
    ) then
    raise exception using
      errcode = 'P0001',
      message = 'event attendance unavailable';
  end if;

  select event_registrations.*
  into target_registration
  from public.event_registrations
  where event_registrations.event_id = p_event_id
    and event_registrations.user_id = p_user_id
  for update;

  if not found
    or target_registration.status not in (
      'confirmed'::public.event_registration_status,
      'attended'::public.event_registration_status,
      'no_show'::public.event_registration_status
    ) then
    raise exception using
      errcode = 'P0001',
      message = 'event attendance unavailable';
  end if;

  update public.event_registrations
  set
    status = p_attendance,
    attended_at = timezone('utc', now())
  where id = target_registration.id;

  return query
  select
    event_registrations.id,
    event_registrations.status,
    event_registrations.attended_at
  from public.event_registrations
  where event_registrations.id = target_registration.id;
end;
$$;

create or replace function public.list_event_attendance(p_event_id uuid)
returns table (
  registration_id uuid,
  first_name text,
  last_name_initial text,
  registration_status public.event_registration_status,
  attended_at timestamptz
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select
    event_registrations.id,
    profiles.first_name,
    profiles.last_name_initial,
    event_registrations.status,
    event_registrations.attended_at
  from public.event_registrations
  left join public.profiles
    on profiles.id = event_registrations.user_id
  where event_registrations.event_id = p_event_id
    and (select private.can_current_user_manage_event(p_event_id))
  order by event_registrations.created_at, event_registrations.id;
$$;

revoke all on function public.record_event_attendance(uuid, uuid, public.event_registration_status) from public;
revoke execute on function public.record_event_attendance(uuid, uuid, public.event_registration_status) from anon;
grant execute on function public.record_event_attendance(uuid, uuid, public.event_registration_status) to authenticated;
revoke all on function public.list_event_attendance(uuid) from public;
revoke execute on function public.list_event_attendance(uuid) from anon;
grant execute on function public.list_event_attendance(uuid) to authenticated;