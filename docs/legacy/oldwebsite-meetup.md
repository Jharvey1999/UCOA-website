# Legacy Meetup Findings

**Source:** [UofC Outdoor Adventurers (UCOA) on Meetup](https://www.meetup.com/uofc-outdooradventurers/)

**Observed:** August 29, 2026

**Purpose:** Record the publicly observable behavior and data shape of the current Meetup presence so the replacement preserves useful workflows without copying private data or creating an unauthorized integration.

## Group snapshot

The canonical public group is named **UofC Outdoor Adventurers (UCOA)** and is located in Calgary, Alberta, Canada. The page identifies it as a private group. The observed snapshot showed approximately 688 members and a 4.8 rating from 1,894 ratings. These counts are dynamic and must not be used as application seed data without a new, authorized source.

The public mission describes a student-founded outdoor club connected to the University of Calgary, with activities in the mountains and an emphasis on responsible, sustainable, environmentally conscious recreation.

## Eligibility and membership language

The public page says applicants must be one of the following:

- A current University of Calgary student or staff member.
- A University of Calgary alumnus.
- A current student at another post-secondary institution who lives in Calgary.

The page says registration requires a full first name, at least the initial of the last name, and a profile photo. It describes an annual CAD 10 fee, a September-to-September membership year, unlimited event access during the paid membership year, and an event-specific waiver sent by the organizer.

The exact wording must be approved before being moved into the new site. The Jotform currently describes the membership dates more precisely as September 1 through August 31; the new app should use one executive-approved value.

## Public versus member-only behavior

### Publicly visible

- Group name, location, mission, and private-group label.
- Membership count and rating summary.
- Eligibility and high-level membership instructions.
- Upcoming event titles, dates, times, and attendee counts as exposed by Meetup.
- Some waitlist and cancellation signals.
- Links to the membership form, organizer application, gear form, Discord, Instagram, Campsite.bio, and contact email.
- Existence of organizers and an organizer count/list entry.

### Restricted on the observed public pages

- Full event descriptions.
- Exact event locations.
- Detailed attendee lists and member profiles.
- Member photos and private group media.
- Full member directory information.

The replacement should preserve this privacy model by default: public event shells may be indexed, but member descriptions, exact locations, attendee identities, profiles, waivers, and private media require the new application's authorization rules.

## Event patterns observed

The public events listing showed 26 upcoming events at the time of observation and a total listing count of 1,918, with past events displayed separately. Counts are dynamic and are recorded only as research context.

Observed event types and examples included:

- Weekly **Top Rope Mondays** indoor climbing sessions, generally around 3:30 PM.
- Tuesday top-roping sessions.
- Hikes and scrambles such as Mount Sparrowhawk, Arnica Lake, Pharaoh Peak, Taylor Lake, Pocaterra Ridge, Smutwood Peak, Jumpingpound Mountain, and Healy Pass.
- Difficulty labels such as `Difficult Scramble` and `Moderate - Difficult`.
- Weekend camping and group-camp events.
- Social gatherings such as a fall kickoff BBQ/potluck.
- Multi-day or themed sequences such as Highwood Hell Week.

The event detail page publicly exposed the title, host group, date, start/end time, and the phrase `Location visible to members`, while the details and location remained restricted. The sampled Mount Rae event ran from 7:30 AM to 7:30 PM MDT and showed a member-only location and member-only details.

The observed event model requires:

- Explicit start and end timestamps.
- An IANA timezone, normally `America/Edmonton`.
- Activity type and optional difficulty.
- Public summary and member-only description.
- Member-only meeting/location data.
- Organizer/host relation.
- Capacity, confirmed count, waitlist, and cancellation state.
- Event-specific waiver association.
- Attendance/check-in status.
- One-off and bounded recurring series support.

One recurring Tuesday event appeared far in the future, in 2050. This is treated as a Meetup data-quality artifact. The replacement must generate recurring instances only to a bounded end date or count and must allow an executive to stop or edit a series.

## External links observed from Meetup

The page linked to the membership Jotform, executive/event-organizer Google Form, communal gear form, Discord, Instagram, Campsite.bio, and `uofc.oa@gmail.com`. The public link inventory and verification status are maintained in [external-services.md](external-services.md).

The Meetup page and Campsite.bio currently showed the Discord invite `https://discord.gg/7XrWTcBCpW`. The original repository README contains a different invite. This discrepancy is a launch blocker for publishing a canonical link and must be resolved by the executive.

## Migration implications

Meetup should be treated as a transition reference and optional read-only archive, not a permanent live synchronization target.

- Recreate or import only upcoming events that UCOA authorizes.
- Do not scrape or copy private event details, attendee data, member profiles, or media.
- Do not copy Meetup images without permission or a clear license.
- Verify exact member-only locations before entering them into Supabase.
- Invite members to the new portal through a controlled account-claim process.
- Run Meetup and UCOA in parallel for a short pilot period before making UCOA primary.

## Unknowns requiring executive confirmation

- Whether Meetup has export/API access available to UCOA and whether using it is permitted.
- Which current organizers should receive organizer or executive roles.
- The approved attendee identity visibility policy.
- The final waiver signing and storage workflow.
- Whether historical event records have operational or reporting value.
- Ownership and licensing status of Meetup cover photos and event media.
- The canonical Discord invite and current external forms.

## Source caveat

This is a time-stamped public research snapshot. Member counts, ratings, event counts, links, event schedules, and descriptions can change. It is not a substitute for an executive-approved content inventory or a private data export.