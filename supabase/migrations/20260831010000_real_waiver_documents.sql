insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'waiver-documents',
  'waiver-documents',
  false,
  5242880,
  array['application/pdf']::text[]
);

create or replace function private.storage_waiver_document_path(p_name text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select case
    when p_name ~ '^waivers/[0-9]{4}-[0-9]{4}/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$'
      then p_name
    else null
  end;
$$;

create or replace function private.can_current_user_read_waiver_document(p_name text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.waivers
    where document_reference = (select private.storage_waiver_document_path(p_name))
      and (
        (
          status = 'approved'::public.waiver_status
          and (select private.can_current_user_read_waiver(waivers.id))
        )
        or (select private.is_current_user_executive())
        or exists (
          select 1
          from public.event_private_details as details
          where details.waiver_id = waivers.id
            and (select private.can_current_user_manage_event(details.event_id))
        )
      )
  );
$$;

create or replace function private.can_current_user_manage_waiver_document(p_name text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select (select private.is_current_user_executive())
    and exists (
      select 1
      from public.waivers
      where document_reference = (select private.storage_waiver_document_path(p_name))
    );
$$;

revoke all on function private.storage_waiver_document_path(text) from public;
revoke all on function private.can_current_user_read_waiver_document(text) from public;
revoke all on function private.can_current_user_manage_waiver_document(text) from public;
grant execute on function private.can_current_user_read_waiver_document(text) to authenticated;
grant execute on function private.can_current_user_manage_waiver_document(text) to authenticated;

create policy waiver_documents_select_authorized
on storage.objects for select to authenticated
using (
  bucket_id = 'waiver-documents'
  and (select private.can_current_user_read_waiver_document(name))
);

create policy waiver_documents_insert_executive
on storage.objects for insert to authenticated
with check (
  bucket_id = 'waiver-documents'
  and (select private.can_current_user_manage_waiver_document(name))
);

create policy waiver_documents_update_executive
on storage.objects for update to authenticated
using (
  bucket_id = 'waiver-documents'
  and (select private.can_current_user_manage_waiver_document(name))
)
with check (
  bucket_id = 'waiver-documents'
  and (select private.can_current_user_manage_waiver_document(name))
);

create policy waiver_documents_delete_executive
on storage.objects for delete to authenticated
using (
  bucket_id = 'waiver-documents'
  and (select private.can_current_user_manage_waiver_document(name))
);

insert into public.waivers (
  version,
  acknowledgement_method,
  document_reference,
  status
)
values
  (
    '2025-2026-provincial',
    'organizer_recorded',
    'waivers/2025-2026/provincial.pdf',
    'draft'
  ),
  (
    '2025-2026-national',
    'organizer_recorded',
    'waivers/2025-2026/national.pdf',
    'draft'
  );