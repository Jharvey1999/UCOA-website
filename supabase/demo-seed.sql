begin;

insert into auth.users (id, email)
values
  ('10000000-0000-0000-0000-000000000001', 'demo-member@example.test'),
  ('10000000-0000-0000-0000-000000000002', 'demo-organizer@example.test'),
  ('10000000-0000-0000-0000-000000000003', 'demo-executive@example.test'),
  ('10000000-0000-0000-0000-000000000004', 'demo-pending@example.test');

insert into public.profiles (id, first_name, last_name_initial, display_name, affiliation)
values
  ('10000000-0000-0000-0000-000000000001', 'Alex', 'M', 'Alex M.', 'UCalgary'),
  ('10000000-0000-0000-0000-000000000002', 'Jordan', 'K', 'Jordan K.', 'UCalgary'),
  ('10000000-0000-0000-0000-000000000003', 'Morgan', 'R', 'Morgan R.', 'UCalgary'),
  ('10000000-0000-0000-0000-000000000004', 'Taylor', 'S', 'Taylor S.', 'UCalgary');

insert into public.memberships (
  user_id,
  membership_year_start,
  membership_year_end,
  status,
  approved_at
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    '2026-09-01',
    '2027-08-31',
    'active',
    '2026-09-01 00:00:00+00'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '2026-09-01',
    '2027-08-31',
    'active',
    '2026-09-01 00:00:00+00'
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    '2026-09-01',
    '2027-08-31',
    'active',
    '2026-09-01 00:00:00+00'
  ),
  (
    '10000000-0000-0000-0000-000000000004',
    null,
    null,
    'pending',
    null
  );

insert into public.membership_admin (membership_id, approved_by)
select memberships.id, '10000000-0000-0000-0000-000000000003'
from public.memberships
where memberships.status = 'active';

insert into public.user_roles (user_id, role, assigned_by)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'member',
    '10000000-0000-0000-0000-000000000003'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'organizer',
    '10000000-0000-0000-0000-000000000003'
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'executive',
    '10000000-0000-0000-0000-000000000002'
  );

insert into public.waivers (
  id,
  version,
  acknowledgement_method,
  document_reference,
  status,
  approved_by,
  approved_at
)
values (
  '20000000-0000-0000-0000-000000000001',
  'demo-member-ack-v1',
  'built_in',
  'ucoa://waivers/demo-member-ack-v1',
  'approved',
  '10000000-0000-0000-0000-000000000003',
  '2026-09-01 00:00:00+00'
);

insert into public.events (
  id,
  created_by,
  title,
  public_summary,
  starts_at,
  ends_at,
  timezone_name,
  activity_type,
  difficulty,
  visibility,
  status,
  capacity,
  waitlist_enabled
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    'Prairie Mountain Morning Hike',
    'A steady early-season hike with wide views and a relaxed pace for new and experienced members.',
    '2026-09-19 15:00:00+00',
    '2026-09-19 18:00:00+00',
    'America/Edmonton',
    'hike',
    'Moderate',
    'public',
    'published',
    12,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'Indoor Climbing Social',
    'Meet other UCOA members for an evening of movement, technique, and low-pressure climbing.',
    '2026-09-26 01:00:00+00',
    '2026-09-26 03:30:00+00',
    'America/Edmonton',
    'climbing',
    'Introductory',
    'public',
    'published',
    8,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    'Cancelled Trail Skills Session',
    'A cancelled event kept in the calendar to demonstrate the public status boundary.',
    '2026-10-10 16:00:00+00',
    '2026-10-10 19:00:00+00',
    'America/Edmonton',
    'course',
    null,
    'public',
    'cancelled',
    0,
    false
  );

insert into public.event_private_details (
  event_id,
  member_description,
  exact_location,
  waiver_required,
  waiver_id
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    'Bring water, lunch, layers, and footwear suitable for uneven terrain. The host will share the final meeting instructions with registered members.',
    'Demo meeting location: confirm with the host after RSVP.',
    true,
    '20000000-0000-0000-0000-000000000001'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    'Rental gear and route details will be confirmed in the member event notes. No previous climbing experience is required.',
    'Demo climbing gym location: confirm with the host after RSVP.',
    false,
    null
  ),
  (
    '30000000-0000-0000-0000-000000000003',
    'This session has been cancelled for the demo environment.',
    null,
    false,
    null
  );

insert into public.event_hosts (event_id, user_id, assigned_by)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003'
  ),
  (
    '30000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003'
  );

commit;
