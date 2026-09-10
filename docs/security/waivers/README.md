# UCOA Waiver Source Documents

**Status:** source inventory and draft application mapping; not approved for production use

These are the waiver sources supplied for the Phase 5 integration. This inventory records observed document facts and implementation assumptions without reproducing the legal text.

## Observed source facts

| Application version | Source document | Pages | Effective period | Observed completion fields | SHA-256 |
| --- | --- | ---: | --- | --- | --- |
| `2025-2026-provincial` | Copy of 25_26 Provincial Waiver.pdf (not present in the current tree) | 2 | September 1, 2025 to August 31, 2026 | Participant name, signature, email, address, date; parent/legal-guardian fields for minors | `B32BFCB5A6AE32DBA02B1D8DEFD6E6C8C4F3EB0E5399434265B6BC6F3F2306DB` |
| `2025-2026-national` | Copy of 25_26 National Waiver.pdf (not present in the current tree) | 2 | September 1, 2025 to August 31, 2026 | Participant name, signature, email, address, date; parent/legal-guardian fields for minors | `E7BED4D23E5598EA834B5D0B2E948FE58CC32BFBA02B6F5DB3B3D301E5FF8028` |
| `2026-2027-club-approved-activities` | [UC Outdoors Adventures Blanket Waiver.pdf](UC_Outdoors_Adventures_Blanket_Waiver.pdf) | 2 | September 1, 2026 to August 31, 2027 | Participant name, signature, email, date; parent/legal-guardian fields for minors | `2EF5BD85B0B7AA4735ADC58FE9CDEA1393909E6BDBBB858F0F800F61B18D6FC6` |

The filenames and document text distinguish provincial and national park activity coverage. The forms require a participant signature and do not provide evidence that a portal checkbox is an approved substitute.

The new 2026-2027 source identifies UC Outdoor Adventures club-approved activities and describes campus, city, provincial, and national park activities including out-of-city travel, camping, climbing, hiking, skiing, and swimming. The supplied local PDF artifact is 63,392 bytes and has the SHA-256 value recorded above. Its page count is retained as two pages from the supplied source description and has not been independently checked in this environment.

## Application mapping

The current implementation maps the supplied source forms to `organizer_recorded` as an assumption based on their signature fields. All three database records remain `draft` with no approval actor or approval timestamp until UCOA confirms the wording, event applicability, and operating decision.

When approved, the records use these private Storage object paths:

| Version | Bucket | Object path |
| --- | --- | --- |
| `2025-2026-provincial` | `waiver-documents` | `waivers/2025-2026/provincial.pdf` |
| `2025-2026-national` | `waiver-documents` | `waivers/2025-2026/national.pdf` |
| `2026-2027-club-approved-activities` | `waiver-documents` | `waivers/2026-2027/club-approved-activities.pdf` |

The member event page reaches an approved assigned document through an authenticated event-scoped route that issues a five-minute signed URL. The PDFs are not copied into a public directory, and the database migration does not upload binary objects.

The protected organizer attendance roster can record an opaque `evidence_reference` for a confirmed, attended, or no-show registration when an approved `organizer_recorded` waiver is assigned. The database derives the participant from the event registration, restricts the operation to an active event host or executive, and keeps direct acknowledgement writes denied. This records a reference only; it does not upload signed evidence, verify legal validity, or choose retention and deletion rules.

The 2025-2026 source binaries were previously validated in the local development `waiver-documents` bucket at the canonical paths above. The new 2026-2027 PDF is present in this source inventory but has not been uploaded to that bucket. Local artifact validation does not constitute a production upload or UCOA approval.

## Approval and upload gate

Before either record is approved or assigned to a member event, UCOA must:

- Confirm that each PDF is the current approved wording and select its event applicability.
- Confirm that `organizer_recorded` is the intended completion method, including how signed participant and minor-guardian evidence is recorded.
- Name the evidence owner, retention period, correction process, and deletion process.
- Confirm the local artifact verification, then upload each exact source artifact to its production private object path and verify the SHA-256 value above.
- Assign only the approved version to events; unresolved, unsupported, or missing-document paths remain fail-closed.