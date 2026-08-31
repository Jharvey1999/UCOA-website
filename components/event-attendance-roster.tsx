"use client";

import { Check, CircleOff } from "lucide-react";
import { useActionState } from "react";

import {
  initialEventAttendanceActionState,
  recordEventAttendance,
  type EventAttendanceActionState,
  type EventAttendanceStatus,
} from "@/app/protected/events/[id]/attendance/actions";
import { Button } from "@/components/ui/button";

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

export function EventAttendanceRoster({
  eventId,
  rows,
}: EventAttendanceRosterProps) {
  const [state, formAction, isPending] = useActionState(
    recordEventAttendance,
    initialEventAttendanceActionState,
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

      <div className="border-y border-[#c9d6d0]">
        {rows.map((row) => {
          const currentStatus = displayStatus(row, state);
          const canRecord =
            currentStatus === "confirmed" ||
            currentStatus === "attended" ||
            currentStatus === "no_show";

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