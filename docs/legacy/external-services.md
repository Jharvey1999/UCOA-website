# Legacy External Services and Link Inventory

**Observed:** August 29, 2026

**Purpose:** Inventory the public services currently surrounding UCOA so the replacement can preserve useful entry points while making ownership, verification, privacy, and migration status explicit.

External links are changeable operational content. The new site should store approved links in executive-managed settings rather than scattering them through components or source code. A link appearing here is not automatically approved for launch.

## Service inventory

| Service | Observed URL | Public purpose | Replacement treatment | Status |
| --- | --- | --- | --- | --- |
| Meetup | [uofc-outdooradventurers](https://www.meetup.com/uofc-outdooradventurers/) | Current private group, event calendar, membership context, and member-only event operations | Transition reference and short parallel-calendar period; no permanent live sync assumed | Verify cutover owner and permitted exports |
| Instagram | [@ucalgaryoa](https://www.instagram.com/ucalgaryoa/) | Social updates and outdoor media | Link only in MVP; no scraping or media mirroring | Handle linked; account/content ownership requires confirmation |
| Campsite.bio | [ucoa](https://campsite.bio/ucoa) | Link hub for membership, events, forms, Discord, gear, and merchandise | Use as a source inventory; replace with site-managed links over time | Public page observed; verify every destination |
| Discord | [discord.gg/7XrWTcBCpW](https://discord.gg/7XrWTcBCpW) | Community chat and member onboarding | Executive-managed link after verification; manual access at launch | Current public Meetup/Campsite.bio invite; verify before publishing |
| Membership form | [Jotform](https://form.jotform.com/261258137024250) | Membership application and fee information | Use during transition; migrate approved fields and workflow to Supabase | Public form observed; confirm data ownership and retention |
| Executive/event-organizer application | [Google Form](https://docs.google.com/forms/d/e/1FAIpQLScazEtJziD_N0m9u9E3-FHxrilBHSKvkOhbA7oZV9gnAgOlQA/viewform?usp=sf_link) | Applications for executive or organizer roles | Keep as a transition link or replace with executive-managed workflow | Verify current owner and future process |
| Gear checkout, Meetup link | [Google Form short link](https://forms.gle/aXhqaBpGTiT4T2838) | Communal club gear checkout | Defer gear system; retain verified external link if still needed | Short link redirected to a Google Form when observed |
| Gear checkout, Campsite link | [Google Form short link](https://forms.gle/nwxGT17NdwbS6VV78) | Communal club gear checkout from the link hub | Resolve against the other gear URL before publishing | Discrepancy requires executive confirmation |
| Buff orders | [Google Form](https://docs.google.com/forms/d/e/1FAIpQLSf-ETtstuCIU6p6Gmz27J-cpkL36T4A_GEMD-3h6UFLfzMJ-Q/viewform?usp=sharing&ouid=115585055215958227652) | UCOA branded merchandise orders | Link only in a later or managed-resources area | Public link observed through Campsite.bio |
| Contact email | `uofc.oa@gmail.com` | General club contact and current e-transfer recipient shown by the membership form | Executive-managed contact setting; protect from accidental exposure in private workflows | Verify operational ownership and recipient use |

## Source-specific findings

### Meetup

See [oldwebsite-meetup.md](oldwebsite-meetup.md) for the private-group visibility model, event patterns, dynamic counts, and migration restrictions.

### Instagram

See [instagram.md](instagram.md). The available public view confirmed the handle but did not provide a reliable content inventory. Use it as a link, not a data source.

### Campsite.bio

The public link hub identified itself as **UofC Outdoor Adventurers** and linked to the membership form, Buff orders, Meetup events, junior executive/event-organizer application, Discord, and a club gear form. It is useful for discovering current destinations but should not be treated as a source of truth because links can be changed independently of the website.

### Membership Jotform

The public form described:

- Membership validity from September 1 through August 31.
- First name and last name.
- UCID, with `N/A` for applicants without one.
- Email.
- Emergency contact name and phone number.
- Outdoor interests.
- CAD 10 payment by e-transfer or cash.
- Meetup as the event schedule during the transition.
+
+These fields require a new data-minimization decision. In particular, UCID and emergency contact information must not be imported or collected by default until purpose, access, consent, and retention are approved.
+
### Discord

The current public link observed on Meetup and Campsite.bio was `https://discord.gg/7XrWTcBCpW`. The repository's original README contains `https://discord.gg/cGNxMSajS`, which is different. Do not choose between them programmatically. The executive must verify the canonical invite, then store it in a managed setting and test that it resolves to the intended server.
+
+Automated Discord OAuth, invitations, and role synchronization are deferred. Manual onboarding is the MVP behavior.
+
### Gear links

Two different Google short links were observed for club gear: the Meetup-linked `aXhqaBpGTiT4T2838` and the Campsite-linked `nwxGT17NdwbS6VV78`. The first redirected to a Google Form during observation. The destination and ownership must be reconciled before either is presented as the official gear workflow.
+
## Link verification procedure
+
+Before publishing an external link in production:
+
+1. Executive confirms the destination and operational owner.
+2. Maintainer opens the link in a private browser session and records only the destination, purpose, and verification date.
+3. Maintainer checks that the destination does not request prohibited credentials or expose UCOA data unexpectedly.
+4. The link is entered into executive-managed site settings with a safe label.
+5. A change audit entry records who changed it and why.
+6. A scheduled or pre-release link check verifies that it still resolves.
+
+Do not store external service tokens, form response exports, Discord bot credentials, or private social credentials in the repository.
+
## Transition principles
+
- Keep external services as explicit links until the equivalent UCOA workflow is implemented and accepted.
- Do not promise automatic synchronization when the MVP is manual.
- Do not copy private form responses into Git, logs, or public pages.
- Give each migrated workflow one clear source of truth.
- Treat a changed or inaccessible external page as a normal operational failure with an editable link and visible status.
*** End Patch