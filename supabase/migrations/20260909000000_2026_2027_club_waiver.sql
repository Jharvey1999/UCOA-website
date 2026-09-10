insert into public.waivers (
  version,
  acknowledgement_method,
  document_reference,
  status
)
values (
  '2026-2027-club-approved-activities',
  'organizer_recorded',
  'waivers/2026-2027/club-approved-activities.pdf',
  'draft'
)
on conflict (version) do nothing;