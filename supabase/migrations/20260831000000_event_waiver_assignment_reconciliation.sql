drop function public.update_event_instance(
  uuid,
  text,
  text,
  text,
  text,
  text,
  public.event_activity_type,
  text,
  public.event_visibility,
  text,
  text,
  boolean
);

create or replace function public.update_event_instance(
  p_event_id uuid,
  p_title text,
  p_public_summary text,
  p_starts_local text,
  p_ends_local text,
  p_timezone_name text,
  p_activity_type public.event_activity_type,
  p_difficulty text,
  p_visibility public.event_visibility,
  p_member_description text,
  p_exact_location text
)
returns table (
  event_id uuid,
  series_id uuid,
  title text,
  public_summary text,
  starts_at timestamptz,
  ends_at timestamptz,
  timezone_name text,
  activity_type public.event_activity_type,
  difficulty text,
  visibility public.event_visibility,
  status public.event_status
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  event_record public.events%rowtype;
  local_start timestamp without time zone;
  local_end timestamp without time zone;
  updated_start timestamptz;
  updated_end timestamptz;
begin
  if (select auth.uid()) is null
    or not (select private.can_current_user_manage_event(p_event_id)) then
    raise exception using
      errcode = '42501',
      message = 'event unavailable';
  end if;

  select events.*
  into event_record
  from public.events
  where events.id = p_event_id
  for update;

  if not found then
    raise exception using
      errcode = '42501',
      message = 'event unavailable';
  end if;

  if p_title is null
    or char_length(btrim(p_title)) not between 1 and 160
    or p_public_summary is null
    or char_length(btrim(p_public_summary)) not between 1 and 2400
    or p_member_description is null
    or char_length(btrim(p_member_description)) not between 1 and 12000
    or p_timezone_name is null
    or p_starts_local is null
    or p_ends_local is null
    or not (select private.is_valid_timezone(p_timezone_name))
    or p_activity_type is null
    or p_visibility is null
    or (
      p_difficulty is not null
      and char_length(btrim(p_difficulty)) not between 1 and 40
    )
    or (
      p_exact_location is not null
      and char_length(btrim(p_exact_location)) not between 1 and 600
    ) then
    raise exception using
      errcode = '22023',
      message = 'event input is invalid';
  end if;

  begin
    local_start := p_starts_local::timestamp without time zone;
    local_end := p_ends_local::timestamp without time zone;
  exception when others then
    raise exception using
      errcode = '22023',
      message = 'event input is invalid';
  end;

  updated_start := local_start at time zone p_timezone_name;
  updated_end := local_end at time zone p_timezone_name;

  if updated_start >= updated_end then
    raise exception using
      errcode = '22023',
      message = 'event input is invalid';
  end if;

  update public.events as target_event
  set title = p_title,
      public_summary = p_public_summary,
      starts_at = updated_start,
      ends_at = updated_end,
      timezone_name = p_timezone_name,
      activity_type = p_activity_type,
      difficulty = p_difficulty,
      visibility = p_visibility
  where target_event.id = p_event_id
  returning target_event.* into event_record;

  insert into public.event_private_details (
    event_id,
    member_description,
    exact_location
  )
  values (
    event_record.id,
    p_member_description,
    p_exact_location
  )
  on conflict on constraint event_private_details_pkey do update
  set member_description = excluded.member_description,
      exact_location = excluded.exact_location;

  event_id := event_record.id;
  series_id := event_record.series_id;
  title := event_record.title;
  public_summary := event_record.public_summary;
  starts_at := event_record.starts_at;
  ends_at := event_record.ends_at;
  timezone_name := event_record.timezone_name;
  activity_type := event_record.activity_type;
  difficulty := event_record.difficulty;
  visibility := event_record.visibility;
  status := event_record.status;
  return next;
end;
$$;

revoke all on function public.update_event_instance(
  uuid,
  text,
  text,
  text,
  text,
  text,
  public.event_activity_type,
  text,
  public.event_visibility,
  text,
  text
) from public;
revoke execute on function public.update_event_instance(
  uuid,
  text,
  text,
  text,
  text,
  text,
  public.event_activity_type,
  text,
  public.event_visibility,
  text,
  text
) from anon;
grant execute on function public.update_event_instance(
  uuid,
  text,
  text,
  text,
  text,
  text,
  public.event_activity_type,
  text,
  public.event_visibility,
  text,
  text
) to authenticated;

revoke insert (waiver_required)
  on table public.event_private_details
  from authenticated;
revoke update (waiver_required)
  on table public.event_private_details
  from authenticated;