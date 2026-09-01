"use client";

import { Check, CircleOff, FileCheck2 } from "lucide-react";
import { useActionState } from "react";

import {
  recordEventAttendance,
  recordEventWaiverEvidence,
  type EventAttendanceActionState,
  type EventAttendanceStatus,
} from "@/app/protected/events/[id]/attendance/actions";
import {
  initialEventAttendanceActionState,
  initialEventWaiverEvidenceActionState,
} from "@/app/protected/events/[id]/attendance/action-state";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export type EventAttendanceRow = {
  registration_id: string;
  first_name: string | null;
  last_name_initial: string | null;
  registration_status:
    | "confirmed"
    | "waitlisted"
    | "cancelled"
    | "attended"
    | "no_show";
  attended_at: string | null;
  waiver_version: string | null;
  waiver_acknowledgement_method:
    | "built_in"
    | "external"
    | "organizer_recorded"
    | null;
  waiver_status: "draft" | "approved" | "retired" | null;
  waiver_acknowledgement_status: "acknowledged" | "revoked" | null;
};

type EventAttendanceRosterProps = {
  eventId: string;
  rows: EventAttendanceRow[];
};

function memberName(row: EventAttendanceRow) {
  if (!row.first_name) {
    return "Member without profile";
  }

  return row.last_name_initial
    ? `${row.first_name} ${row.last_name_initial}.`
    : row.first_name;
}

function statusLabel(status: EventAttendanceRow["registration_status"]) {
  if (status === "no_show") {
    return "No show";
  }

  if (status === "waitlisted") {
    return "Waitlisted";
  }

  if (status === "cancelled") {
    return "Cancelled";
  }

  if (status === "attended") {
    return "Attended";
  }

  return "Confirmed";
}

function displayStatus(
  row: EventAttendanceRow,
  state: EventAttendanceActionState,
) {
  if (state.result === "success" && state.registrationId === row.registration_id) {
    return state.attendanceStatus ?? row.registration_status;
  }

  return row.registration_status;
}

function displayWaiverStatus(
  row: EventAttendanceRow,
  state: {
    result: "idle" | "success" | "error";
    registrationId: string | null;
  },
) {
  if (state.result === "success" && state.registrationId === row.registration_id) {
    return "acknowledged" as const;
  }

  return row.waiver_acknowledgement_status;
}

export function EventAttendanceRoster({
  eventId,
  rows,
}: EventAttendanceRosterProps) {
  const [state, formAction, isPending] = useActionState(
    recordEventAttendance,
    initialEventAttendanceActionState,
  );
  const [evidenceState, evidenceFormAction, isEvidencePending] = useActionState(
    recordEventWaiverEvidence,
    initialEventWaiverEvidenceActionState,
  );

  if (rows.length === 0) {
    return (
      <div className="border-y border-[#c9d6d0] py-8 text-sm leading-6 text-[#71847b]">
        No registrations are recorded for this event.
      </div>
    );
  }

  return (
    <div>
      {state.result !== "idle" ? (
        <p
          aria-live="polite"
          className={`mb-5 text-sm leading-6 ${
            state.result === "error" ? "text-[#9a432d]" : "text-[#557268]"
          }`}
          role={state.result === "error" ? "alert" : undefined}
        >
          {state.message}
        </p>
      ) : null}
      {evidenceState.result !== "idle" ? (
        <p
          aria-live="polite"
          className={`mb-5 text-sm leading-6 ${
            evidenceState.result === "error" ? "text-[#9a432d]" : "text-[#557268]"
          }`}
          role={evidenceState.result === "error" ? "alert" : undefined}
        >
          {evidenceState.message}
        </p>
      ) : null}

      <div className="border-y border-[#c9d6d0]">
        {rows.map((row) => {
          const currentStatus = displayStatus(row, state);
          const currentWaiverStatus = displayWaiverStatus(row, evidenceState);
          const canRecord =
            currentStatus === "confirmed" ||
            currentStatus === "attended" ||
            currentStatus === "no_show";
          const canRecordWaiverEvidence =
            canRecord &&
            row.waiver_acknowledgement_method === "organizer_recorded" &&
            row.waiver_status === "approved" &&
            Boolean(row.waiver_version) &&
            currentWaiverStatus !== "acknowledged";

          return (
            <div
              className="grid gap-4 border-b border-[#c9d6d0] py-5 last:border-b-0 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center"
              key={row.registration_id}
            >
              <div>
                <p className="font-semibold text-[#19352d]">{memberName(row)}</p>
                <p className="mt-1 text-xs font-bold uppercase tracking-[0.14em] text-[#71847b]">
                  {statusLabel(currentStatus)}
                </p>

                {row.waiver_version ? (
                  <div className="mt-4 border-t border-[#dfe9e1] pt-3">
                    <p className="text-xs font-bold uppercase tracking-[0.14em] text-[#557268]">
                      Assigned waiver
                    </p>
                    <p className="mt-1 text-sm font-semibold text-[#40574e]">
                      {row.waiver_version}
                    </p>

                    {currentWaiverStatus === "acknowledged" ? (
                      <p className="mt-2 inline-flex items-center gap-2 text-sm font-semibold text-[#40574e]">
                        <FileCheck2 aria-hidden="true" className="size-4 text-[#b35f35]" />
                        Evidence recorded
                      </p>
                    ) : row.waiver_acknowledgement_method === "organizer_recorded" ? (
                      row.waiver_status === "approved" ? (
                        canRecordWaiverEvidence ? (
                          <form action={evidenceFormAction} className="mt-3 max-w-md">
                            <input name="eventId" type="hidden" value={eventId} />
                            <input
                              name="registrationId"
                              type="hidden"
                              value={row.registration_id}
                            />
                            <label
                              className="text-sm font-semibold text-[#40574e]"
                              htmlFor={`evidence-reference-${row.registration_id}`}
                            >
                              Evidence reference
                            </label>
                            <Input
                              aria-describedby={`evidence-reference-help-${row.registration_id}`}
                              className="mt-2 bg-[#f8f6f0]"
                              disabled={isEvidencePending}
                              id={`evidence-reference-${row.registration_id}`}
                              maxLength={600}
                              name="evidenceReference"
                              required
                            />
                            <p
                              className="mt-2 text-xs leading-5 text-[#71847b]"
                              id={`evidence-reference-help-${row.registration_id}`}
                            >
                              Enter the approved reference for the signed form. Do not enter form contents.
                            </p>
                            <Button
                              className="mt-3 bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]"
                              disabled={isEvidencePending}
                              size="sm"
                              type="submit"
                            >
                              <FileCheck2 aria-hidden="true" className="size-4" />
                              {isEvidencePending ? "Recording..." : "Record evidence"}
                            </Button>
                          </form>
                        ) : (
                          <p className="mt-2 text-sm leading-6 text-[#71847b]">
                            Evidence can be recorded after the registration is confirmed.
                          </p>
                        )
                      ) : (
                        <p className="mt-2 text-sm leading-6 text-[#9a432d]">
                          This assigned waiver is not approved for recording.
                        </p>
                      )
                    ) : row.waiver_acknowledgement_method === "built_in" ? (
                      <p className="mt-2 text-sm leading-6 text-[#71847b]">
                        The member must complete the in-portal acknowledgement.
                      </p>
                    ) : (
                      <p className="mt-2 text-sm leading-6 text-[#71847b]">
                        Completion is handled through the approved external workflow.
                      </p>
                    )}
                  </div>
                ) : null}
              </div>

              {canRecord ? (
                <div className="flex flex-wrap gap-2">
                  {(["attended", "no_show"] as EventAttendanceStatus[]).map(
                    (attendance) => (
                      <form action={formAction} key={attendance}>
                        <input name="eventId" type="hidden" value={eventId} />
                        <input
                          name="registrationId"
                          type="hidden"
                          value={row.registration_id}
                        />
                        <input name="attendance" type="hidden" value={attendance} />
                        <Button
                          className={
                            attendance === currentStatus
                              ? "border-[#19352d] bg-[#19352d] text-[#f3f0e8] hover:bg-[#19352d]"
                              : "border-[#9fb2a8] bg-transparent text-[#19352d] hover:border-[#19352d] hover:bg-[#dfe9e1]"
                          }
                          disabled={isPending}
                          size="sm"
                          type="submit"
                          variant="outline"
                        >
                          {attendance === "attended" ? (
                            <Check aria-hidden="true" />
                          ) : (
                            <CircleOff aria-hidden="true" />
                          )}
                          {attendance === "attended" ? "Attended" : "No show"}
                        </Button>
                      </form>
                    ),
                  )}
                </div>
              ) : (
                <span className="text-sm text-[#71847b]">
                  Attendance unavailable
                </span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}