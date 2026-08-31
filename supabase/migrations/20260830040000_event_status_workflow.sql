revoke update on table public.events from authenticated;
grant update (
  series_id,
  title,
  public_summary,
  starts_at,
  ends_at,
  timezone_name,
  activity_type,
  difficulty,
  visibility,
  capacity,
  waitlist_enabled
) on table public.events to authenticated;

create or replace function public.set_event_status(
  p_event_id uuid,
  p_status public.event_status
)
returns table (
  event_id uuid,
  previous_status public.event_status,
  status public.event_status
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  event_record public.events%rowtype;
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

  if p_status is null then
    raise exception using
      errcode = '22023',
      message = 'event status is invalid';
  end if;

  if event_record.status = p_status then
    return query
    select event_record.id, event_record.status, event_record.status;
    return;
  end if;

  if p_status = 'published'::public.event_status
    and not exists (
      select 1
      from public.event_private_details
      where public.event_private_details.event_id = event_record.id
    ) then
    raise exception using
      errcode = 'P0001',
      message = 'event cannot be published';
  end if;

  if event_record.status = 'published'::public.event_status
    and p_status = 'completed'::public.event_status
    and event_record.ends_at > timezone('utc', now()) then
    raise exception using
      errcode = 'P0001',
      message = 'event cannot be completed';
  end if;

  if not (
    (
      event_record.status = 'draft'::public.event_status
      and p_status in (
        'published'::public.event_status,
        'cancelled'::public.event_status
      )
    )
    or (
      event_record.status = 'published'::public.event_status
      and p_status = 'cancelled'::public.event_status
    )
    or (
      event_record.status = 'published'::public.event_status
      and p_status = 'completed'::public.event_status
      and event_record.ends_at <= timezone('utc', now())
    )
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'event status transition is invalid';
  end if;

  update public.events
  set status = p_status
  where public.events.id = event_record.id;

  if p_status = 'cancelled'::public.event_status then
    update public.event_registrations
    set status = 'cancelled'::public.event_registration_status,
        waitlist_position = null,
        queued_at = null,
        cancelled_at = timezone('utc', now()),
        promoted_at = null
    where public.event_registrations.event_id = event_record.id
      and public.event_registrations.status in (
        'confirmed'::public.event_registration_status,
        'waitlisted'::public.event_registration_status
      );
  end if;

  return query
  select event_record.id, event_record.status, p_status;
end;
$$;

revoke all on function public.set_event_status(uuid, public.event_status) from public;
revoke execute on function public.set_event_status(uuid, public.event_status) from anon;
grant execute on function public.set_event_status(uuid, public.event_status) to authenticated;
