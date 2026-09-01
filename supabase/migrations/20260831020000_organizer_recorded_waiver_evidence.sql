drop function public.list_event_attendance(uuid);

create function public.list_event_attendance(p_event_id uuid)
returns table (
  registration_id uuid,
  first_name text,
  last_name_initial text,
  registration_status public.event_registration_status,
  attended_at timestamptz,
  waiver_version text,
  waiver_acknowledgement_method public.waiver_acknowledgement_method,
  waiver_status public.waiver_status,
  waiver_acknowledgement_status public.waiver_acknowledgement_status
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
    event_registrations.attended_at,
    waivers.version,
    waivers.acknowledgement_method,
    waivers.status,
    acknowledgements.status
  from public.event_registrations
  left join public.profiles
    on profiles.id = event_registrations.user_id
  left join public.event_private_details as details
    on details.event_id = event_registrations.event_id
  left join public.waivers
    on waivers.id = details.waiver_id
  left join public.waiver_acknowledgements as acknowledgements
    on acknowledgements.event_id = event_registrations.event_id
   and acknowledgements.waiver_id = details.waiver_id
   and acknowledgements.user_id = event_registrations.user_id
  where event_registrations.event_id = p_event_id
    and (select private.can_current_user_manage_event(p_event_id))
  order by event_registrations.created_at, event_registrations.id;
$$;

revoke all on function public.list_event_attendance(uuid) from public;
revoke execute on function public.list_event_attendance(uuid) from anon;
grant execute on function public.list_event_attendance(uuid) to authenticated;

create or replace function public.record_event_waiver_evidence(
  p_event_id uuid,
  p_registration_id uuid,
  p_evidence_reference text
)
returns table (
  registration_id uuid,
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
  target_registration public.event_registrations%rowtype;
  details_required boolean;
  selected_waiver_id uuid;
  selected_version text;
  selected_method public.waiver_acknowledgement_method;
  selected_status public.waiver_status;
  acknowledgement_record public.waiver_acknowledgements%rowtype;
begin
  if (select auth.uid()) is null
    or not (select private.can_current_user_manage_event(p_event_id)) then
    raise exception using
      errcode = '42501',
      message = 'event waiver unavailable';
  end if;

  if p_evidence_reference is null
    or char_length(btrim(p_evidence_reference)) not between 1 and 600 then
    raise exception using
      errcode = '22023',
      message = 'waiver evidence reference is invalid';
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
      message = 'event waiver unavailable';
  end if;

  select event_registrations.*
  into target_registration
  from public.event_registrations
  where event_registrations.id = p_registration_id
    and event_registrations.event_id = p_event_id
  for update;

  if not found
    or target_registration.status not in (
      'confirmed'::public.event_registration_status,
      'attended'::public.event_registration_status,
      'no_show'::public.event_registration_status
    ) then
    raise exception using
      errcode = 'P0001',
      message = 'waiver evidence unavailable';
  end if;

  select details.waiver_required, details.waiver_id
  into details_required, selected_waiver_id
  from public.event_private_details as details
  where details.event_id = p_event_id
  for update;

  if not found or not details_required or selected_waiver_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'approved waiver unavailable';
  end if;

  select
    waivers.version,
    waivers.acknowledgement_method,
    waivers.status
  into
    selected_version,
    selected_method,
    selected_status
  from public.waivers
  where waivers.id = selected_waiver_id;

  if not found or selected_status <> 'approved'::public.waiver_status then
    raise exception using
      errcode = 'P0001',
      message = 'approved waiver unavailable';
  end if;

  if selected_method <> 'organizer_recorded'::public.waiver_acknowledgement_method then
    raise exception using
      errcode = 'P0001',
      message = 'approved waiver workflow is not organizer-recorded';
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
    target_registration.user_id,
    'acknowledged'::public.waiver_acknowledgement_status,
    timezone('utc', now()),
    btrim(p_evidence_reference)
  )
  on conflict on constraint waiver_acknowledgements_event_user_version_key do update
  set status = excluded.status,
      acknowledged_at = excluded.acknowledged_at,
      evidence_reference = excluded.evidence_reference
  returning * into acknowledgement_record;

  return query
  select
    target_registration.id,
    acknowledgement_record.waiver_id,
    selected_version,
    acknowledgement_record.status,
    acknowledgement_record.acknowledged_at;
end;
$$;

revoke all on function public.record_event_waiver_evidence(uuid, uuid, text) from public;
revoke execute on function public.record_event_waiver_evidence(uuid, uuid, text) from anon;
grant execute on function public.record_event_waiver_evidence(uuid, uuid, text) to authenticated;