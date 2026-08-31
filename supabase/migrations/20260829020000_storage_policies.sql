insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'profile-photos',
    'profile-photos',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']::text[]
  ),
  (
    'event-media',
    'event-media',
    false,
    52428800,
    array['image/jpeg', 'image/png', 'image/webp']::text[]
  );

create or replace function private.storage_profile_user_id(p_name text)
returns uuid
language plpgsql
immutable
set search_path = pg_catalog
as $$
begin
  if p_name is null
    or p_name !~ '^profiles/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' then
    return null;
  end if;

  return split_part(p_name, '/', 2)::uuid;
exception
  when invalid_text_representation then
    return null;
end;
$$;

create or replace function private.storage_event_id(p_name text)
returns uuid
language plpgsql
immutable
set search_path = pg_catalog
as $$
begin
  if p_name is null
    or p_name !~ '^events/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' then
    return null;
  end if;

  return split_part(p_name, '/', 2)::uuid;
exception
  when invalid_text_representation then
    return null;
end;
$$;

create or replace function private.storage_object_owner_id(p_object_id uuid)
returns text
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select storage.objects.owner_id
  from storage.objects
  where storage.objects.id = p_object_id;
$$;

create or replace function private.can_current_user_access_profile_media(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  profile_user_id uuid;
begin
  profile_user_id := private.storage_profile_user_id(p_name);
  return profile_user_id is not null
    and (
      coalesce((select private.is_current_user_executive()), false)
      or (
        coalesce(profile_user_id = (select auth.uid()), false)
        and coalesce((select private.is_current_user_active_member()), false)
      )
    )
    and exists (
      select 1
      from public.profiles
      where id = profile_user_id
    );
end;
$$;

create or replace function private.can_current_user_read_event_media(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  event_id uuid;
begin
  event_id := private.storage_event_id(p_name);
  return event_id is not null
    and exists (
      select 1
      from public.events
      where id = event_id
    )
    and coalesce((select private.can_current_user_read_event_details(event_id)), false);
end;
$$;

create or replace function private.can_current_user_manage_event_media(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  event_id uuid;
begin
  event_id := private.storage_event_id(p_name);
  return event_id is not null
    and exists (
      select 1
      from public.events
      where id = event_id
    )
    and coalesce((select private.can_current_user_manage_event(event_id)), false);
end;
$$;

revoke all on function private.storage_profile_user_id(text) from public;
revoke all on function private.storage_event_id(text) from public;
revoke all on function private.storage_object_owner_id(uuid) from public;
revoke all on function private.can_current_user_access_profile_media(text) from public;
revoke all on function private.can_current_user_read_event_media(text) from public;
revoke all on function private.can_current_user_manage_event_media(text) from public;
grant execute on function private.storage_object_owner_id(uuid) to authenticated;
grant execute on function private.can_current_user_access_profile_media(text) to authenticated;
grant execute on function private.can_current_user_read_event_media(text) to authenticated;
grant execute on function private.can_current_user_manage_event_media(text) to authenticated;

create policy storage_profile_media_select_owner_or_executive
on storage.objects for select to authenticated
using (
  bucket_id = 'profile-photos'
  and (select private.can_current_user_access_profile_media(name))
);

create policy storage_profile_media_insert_owner_or_executive
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-photos'
  and owner_id = (select auth.uid()::text)
  and (select private.can_current_user_access_profile_media(name))
);

create policy storage_profile_media_update_owner_or_executive
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-photos'
  and (select private.can_current_user_access_profile_media(name))
)
with check (
  bucket_id = 'profile-photos'
  and owner_id is not distinct from (select private.storage_object_owner_id(id))
  and (
    owner_id = (select auth.uid()::text)
    or coalesce((select private.is_current_user_executive()), false)
  )
  and (select private.can_current_user_access_profile_media(name))
);

create policy storage_profile_media_delete_owner_or_executive
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-photos'
  and (select private.can_current_user_access_profile_media(name))
);

create policy storage_event_media_select_member_or_manager
on storage.objects for select to authenticated
using (
  bucket_id = 'event-media'
  and (select private.can_current_user_read_event_media(name))
);

create policy storage_event_media_insert_manager
on storage.objects for insert to authenticated
with check (
  bucket_id = 'event-media'
  and owner_id = (select auth.uid()::text)
  and (select private.can_current_user_manage_event_media(name))
);

create policy storage_event_media_update_manager
on storage.objects for update to authenticated
using (
  bucket_id = 'event-media'
  and (select private.can_current_user_manage_event_media(name))
)
with check (
  bucket_id = 'event-media'
  and owner_id is not distinct from (select private.storage_object_owner_id(id))
  and (
    owner_id = (select auth.uid()::text)
    or coalesce((select private.is_current_user_executive()), false)
  )
  and (select private.can_current_user_manage_event_media(name))
);

create policy storage_event_media_delete_manager
on storage.objects for delete to authenticated
using (
  bucket_id = 'event-media'
  and (select private.can_current_user_manage_event_media(name))
);