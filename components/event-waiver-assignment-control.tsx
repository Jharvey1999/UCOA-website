"use client";

import { FileCheck2 } from "lucide-react";
import { useActionState } from "react";

import {
  setEventWaiverAssignment,
} from "@/app/protected/events/[id]/edit/actions";
import { initialEventWaiverAssignmentActionState } from "@/app/protected/events/[id]/edit/action-state";
import { Button } from "@/components/ui/button";

export type EventWaiverOption = {
  id: string;
  version: string;
  acknowledgement_method: "built_in" | "external" | "organizer_recorded";
};

type EventWaiverAssignmentControlProps = {
  eventId: string;
  currentWaiverId: string | null;
  options: EventWaiverOption[];
};

export function EventWaiverAssignmentControl({
  currentWaiverId,
  eventId,
  options,
}: EventWaiverAssignmentControlProps) {
  const [state, formAction, isPending] = useActionState(
    setEventWaiverAssignment,
    initialEventWaiverAssignmentActionState,
  );

  return (
    <section className="border-y border-[#c9d6d0] py-8">
      <div className="flex items-start gap-3">
        <FileCheck2 aria-hidden="true" className="mt-0.5 size-6 shrink-0 text-[#b35f35]" />
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
            Executive waiver assignment
          </p>
          <h2 className="mt-3 text-3xl font-semibold leading-tight text-[#19352d]">
            Choose the approved version for this event
          </h2>
          <p className="mt-3 max-w-2xl text-sm leading-6 text-[#71847b]">
            Assignment stores the approved version and method. It does not store or display waiver wording.
          </p>
        </div>
      </div>

      <form action={formAction} className="mt-6 grid gap-4 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end">
        <div>
          <label className="text-sm font-semibold text-[#40574e]" htmlFor="waiverId">
            Approved waiver
          </label>
          <select
            className="mt-2 flex h-10 w-full rounded-md border border-[#b8c8bf] bg-[#fffdf8] px-3 py-2 text-sm text-[#19352d] shadow-sm outline-none focus-visible:ring-1 focus-visible:ring-[#b35f35]"
            defaultValue={currentWaiverId ?? "none"}
            disabled={isPending}
            id="waiverId"
            name="waiverId"
          >
            <option value="none">No waiver requirement</option>
            {options.map((option) => (
              <option key={option.id} value={option.id}>
                {option.version} ({option.acknowledgement_method.replaceAll("_", " ")})
              </option>
            ))}
          </select>
        </div>
        <input name="eventId" type="hidden" value={eventId} />
        <Button
          className="bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]"
          disabled={isPending}
          type="submit"
        >
          <FileCheck2 aria-hidden="true" className="size-4" />
          {isPending ? "Saving..." : "Save assignment"}
        </Button>
      </form>

      {state.result !== "idle" ? (
        <p
          aria-live="polite"
          className={
            state.result === "error"
              ? "mt-5 border border-[#c9785b] bg-[#fff0e9] px-4 py-3 text-sm leading-6 text-[#9a432d]"
              : "mt-5 border border-[#b8c8bf] bg-[#e8f0e9] px-4 py-3 text-sm leading-6 text-[#40574e]"
          }
          role={state.result === "error" ? "alert" : "status"}
        >
          {state.message}
        </p>
      ) : null}
    </section>
  );
}