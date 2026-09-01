# Phase 5 Event Acceptance

**Status:** acceptance in progress

**Owner:** UCOA executive product owner

This checklist covers the event and participation workflows that must be exercised before Phase 5 closes. It does not approve waiver wording or create legal language. The executive must record the approved wording, signing method, and operational owner separately.

## Outstanding requirements

Phase 5 remains open until the following are recorded:

- The full authenticated event-detail, waiver, RSVP, cancellation, and error-state review passes at phone, tablet, and desktop widths.
- UCOA approves the final waiver wording and selects the completion method: built-in, external, or organizer-recorded.
- UCOA names the operational owner for completion evidence, confirms retention, and records the acceptance date and unresolved risks.
- The supplied 2025-2026 waiver documents are confirmed as current, mapped to event scope, uploaded to private Storage, and verified by their recorded hashes.
- The organizer waiver-assignment workflow is accepted against that final operating decision; until then, unsupported and unresolved waiver paths remain fail-closed.

## Supplied waiver documents

The two supplied PDFs are recorded in the [waiver source inventory](../security/waivers/README.md). Both are two-page 2025-2026 forms with participant signature fields and a separate parent/legal-guardian section for minors. The application therefore maps them to `organizer_recorded` as an implementation assumption, not as a UCOA approval.

The records are `draft`, are not assigned to an event, and are not visible to ordinary members. The exact PDFs are present in the local development bucket at their canonical paths and were verified by byte count and SHA-256 round trip; production upload remains open. After UCOA approval and assignment, a document can be reached only through the authenticated event-scoped signed-URL route. Migrations do not upload the PDF binaries.

## Member checks

- [x] An active member can open a published event and see its member description and exact location.
- [x] An active member can acknowledge an approved built-in waiver, RSVP, cancel, and see the resulting state.
- [x] A member without acknowledgement is blocked from RSVP when the event requires a waiver.
- [x] External, organizer-recorded, unavailable, and unresolved legacy waiver workflows remain blocked until their approved completion path is available.
- [x] Pending and expired accounts cannot read private event details or RSVP.
- [x] A member cannot see another member's acknowledgement or registration details through guessed IDs.
- [ ] The event detail, waiver, RSVP, cancellation, and error states work at phone, tablet, and desktop widths.
- [ ] An approved event lets an authorized member review its assigned PDF through a private, expiring signed URL without exposing the object publicly.

## Organizer checks

- [x] An active host can edit one event instance without changing its series link, creator, or publication state.
- [x] An active host can publish, cancel, complete, and manage attendance only for hosted events.
- [x] A non-host organizer cannot edit, moderate, inspect attendance, or inspect acknowledgements for another organizer's event.
- [x] An expired or pending organizer loses event-management capabilities.
- [x] The editor has no standalone legacy waiver checkbox; unresolved legacy requirements are visible and cannot be cleared by ordinary event edits.
- [x] An active host or executive can record an opaque evidence reference only for an approved, assigned `organizer_recorded` waiver and an eligible registration; cross-event, non-host, inactive, and direct-write attempts are denied.
- [ ] A host can use the approved waiver-assignment workflow only as approved by UCOA's final operating decision.

## Executive checks

- [x] An executive can inspect all event and waiver-management states without receiving unnecessary member or legal-text payloads.
- [x] An executive can assign an approved waiver version or explicitly clear an unresolved legacy requirement.
- [x] Draft, retired, unassigned, and guessed waiver records remain unavailable to ordinary members.
- [x] Event status, waiver assignment, acknowledgement, attendance, and destructive changes produce safe audit records.
- [x] Direct table writes and forged client fields cannot bypass the database authorization rules.

## Automated checks

- [x] `npm run lint`
- [x] `npm run typecheck`
- [x] `npm test`
- [x] `npm run build`
- [x] Local migration reset and pgTAP suites pass, including the concurrent RSVP suite: 513 assertions across 12 suites.

## Recorded local smoke checks

**August 31, 2026:** `/events` rendered at desktop and mobile sizes without horizontal overflow. The local app has no Supabase environment variables, so the deliberate unavailable-events state was shown instead of live event records. A malformed `/events` ID returned the generic 404 page, and the unauthenticated protected event editor showed its environment-not-configured fallback without exposing event data.

**September 1, 2026:** A disposable local active-member account completed the authenticated browser flow on the sanitized published members-only event. The page initially exposed the member description and exact location, required acknowledgement of built-in waiver version `phase5-member-v1`, and blocked RSVP until acknowledgement. After acknowledgement, the page showed "Acknowledgement recorded," RSVP succeeded with "You are confirmed for this event," and cancellation returned the page to "You are not currently registered." The acknowledged state and RSVP control rendered without horizontal overflow at phone (375px), tablet (768px), and desktop (1280px) widths. The public unavailable calendar and malformed-ID 404 also rendered without horizontal overflow at those widths and exposed no event or RSVP data. The corresponding organizer and executive browser acceptance was completed with disposable local Auth fixtures; results are recorded in the following entry. Existing pgTAP suites cover their sanitized database authorization behavior; the remaining un-repeated negative and privacy checks remain open.

**September 1, 2026:** The supplied provincial and national PDFs were inspected without copying their legal text into the application. Their observed 2025-2026 period, two-page structure, signature fields, and minor-guardian fields were recorded in the waiver source inventory. The migration added two `draft` `organizer_recorded` records, a private PDF bucket, path-scoped Storage policies, and the authenticated event-scoped signed-URL route; focused pgTAP coverage passed 25 assertions. The exact binaries were uploaded to the local private bucket and verified by byte count and SHA-256. The organizer evidence RPC and protected roster control now cover the approved `organizer_recorded` boundary with 28 additional assertions; the full local run passes 513 assertions across 12 suites. Production upload, UCOA approval, event applicability, evidence ownership, and retention remain open.

**August 31, 2026:** With disposable local Auth fixtures, an active host edited a hosted recurring event while preserving its series link, creator, publication state, and unresolved legacy waiver requirement; the old checkbox was absent. The host published and cancelled a draft, completed an ended event, and marked a confirmed registration attended. An executive assigned an approved built-in waiver to the legacy event and explicitly cleared it again; the UI did not expose waiver wording, and the database recorded `event.waiver_updated` audit entries. The organizer session did not receive the executive-only waiver selector. An active non-host organizer received generic 404 responses for the protected editor and attendance roster; pending and expired organizers received the same denial; pending and expired event-detail requests exposed neither private data nor RSVP controls; and an unknown event ID returned a generic 404 without fixture data. PgTAP also verifies cross-member acknowledgement and registration isolation, unsupported waiver fail-closed behavior, safe audit records, and direct-write denial; full authenticated responsive state coverage remains open for manual review.

## UCOA approval gate

- [ ] UCOA approves the final waiver wording.
- [ ] UCOA confirms the provincial and national source documents, their event applicability, and the recorded hashes.
- [ ] UCOA selects the completion method: built-in, external, or organizer-recorded.
- [ ] The approved PDFs are uploaded to the production private `waiver-documents` bucket and the signed-URL review passes for an authorized assigned member. Local object upload and hash verification are complete.
- [ ] UCOA names the operational owner for completion evidence and confirms retention.
- [ ] The executive owner records the acceptance date and any unresolved risks.