alter table public.events
  add constraint events_series_starts_at_unique unique (series_id, starts_at);

create or replace function public.generate_event_series_instances(p_series_id uuid)
returns table (
  event_id uuid,
  starts_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  series_record public.event_series%rowtype;
  template_event public.events%rowtype;
  template_details public.event_private_details%rowtype;
  template_local_start timestamp without time zone;
  event_date date;
  candidate_start timestamptz;
  candidate_end timestamptz;
  duration interval;
  generated_id uuid;
  generated_start timestamptz;
  existing_count integer;
  month_offset integer;
begin
  if auth.uid() is null
    or not (select private.can_current_user_manage_series(p_series_id)) then
    raise exception using
      errcode = '42501',
      message = 'event series unavailable';
  end if;

  select event_series.*
  into series_record
  from public.event_series
  where event_series.id = p_series_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'event series unavailable';
  end if;

  select events.*
  into template_event
  from public.events
  where events.series_id = p_series_id
    and events.status in (
      'draft'::public.event_status,
      'published'::public.event_status
    )
  order by events.starts_at, events.id
  limit 1;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'event series template unavailable';
  end if;

  duration := template_event.ends_at - template_event.starts_at;
  template_local_start := template_event.starts_at at time zone series_record.timezone_name;

  select count(*)::integer
  into existing_count
  from public.events
  where events.series_id = p_series_id;

  for event_date in
    select generated_date::date
    from generate_series(
      series_record.starts_on,
      series_record.ends_on,
      interval '1 day'
    ) as generated_date
    order by generated_date
  loop
    if existing_count >= series_record.max_instances then
      exit;
    end if;

    if series_record.recurrence_frequency = 'daily'::public.recurrence_frequency then
      if mod(
        event_date - series_record.starts_on,
        series_record.recurrence_interval
      ) <> 0 then
        continue;
      end if;
    elsif series_record.recurrence_frequency = 'weekly'::public.recurrence_frequency then
      if not (
        extract(dow from event_date)::smallint = any(series_record.recurrence_weekdays)
      ) then
        continue;
      end if;

      if mod(
        (event_date - series_record.starts_on) / 7,
        series_record.recurrence_interval
      ) <> 0 then
        continue;
      end if;
    elsif series_record.recurrence_frequency = 'monthly'::public.recurrence_frequency then
      month_offset := (
        extract(year from event_date)::integer * 12
        + extract(month from event_date)::integer
      ) - (
        extract(year from series_record.starts_on)::integer * 12
        + extract(month from series_record.starts_on)::integer
      );

      if extract(day from event_date)::integer
          <> extract(day from series_record.starts_on)::integer
        or mod(month_offset, series_record.recurrence_interval) <> 0 then
        continue;
      end if;
    end if;

    candidate_start := (
      event_date::timestamp without time zone + template_local_start::time
    ) at time zone series_record.timezone_name;
    candidate_end := candidate_start + duration;

    insert into public.events (
      series_id,
      created_by,
      title,
      public_summary,
      starts_at,
      ends_at,
      timezone_name,
      activity_type,
      difficulty,
      visibility,
      status
    )
    values (
      p_series_id,
      template_event.created_by,
      template_event.title,
      template_event.public_summary,
      candidate_start,
      candidate_end,
      series_record.timezone_name,
      template_event.activity_type,
      template_event.difficulty,
      template_event.visibility,
      template_event.status
    )
    on conflict on constraint events_series_starts_at_unique do nothing
    returning id, events.starts_at
    into generated_id, generated_start;

    if found then
      existing_count := existing_count + 1;

      select event_private_details.*
      into template_details
      from public.event_private_details
      where event_private_details.event_id = template_event.id;

      if found then
        insert into public.event_private_details (
          event_id,
          member_description,
          exact_location,
          waiver_required
        )
        values (
          generated_id,
          template_details.member_description,
          template_details.exact_location,
          template_details.waiver_required
        );
      end if;

      insert into public.event_hosts (event_id, user_id, assigned_by)
      select generated_id, event_hosts.user_id, event_hosts.assigned_by
      from public.event_hosts
      where event_hosts.event_id = template_event.id;

      if not exists (
        select 1
        from public.event_hosts
        where event_hosts.event_id = generated_id
      ) then
        insert into public.event_hosts (event_id, user_id, assigned_by)
        values (generated_id, template_event.created_by, auth.uid());
      end if;

      event_id := generated_id;
      starts_at := generated_start;
      return next;
    end if;
  end loop;
end;
$$;

revoke all on function public.generate_event_series_instances(uuid) from public;
revoke execute on function public.generate_event_series_instances(uuid) from anon;
grant execute on function public.generate_event_series_instances(uuid) to authenticated;