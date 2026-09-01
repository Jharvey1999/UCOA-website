"use client";

import { Ban, CheckCircle2, Megaphone } from "lucide-react";
import { useActionState } from "react";

import {
  setEventStatus,
  type EventStatus,
  type EventStatusActionState,
} from "@/app/protected/events/[id]/edit/actions";
import { initialEventStatusActionState } from "@/app/protected/events/[id]/edit/action-state";
import { Button } from "@/components/ui/button";

type EventStatusControlProps = {
  eventId: string;
  status: EventStatus;
  canComplete: boolean;
};

const statusLabels: Record<EventStatus, string> = {
  cancelled: "Cancelled",
  completed: "Completed",
  draft: "Draft",
  published: "Published",
};

function StatusForm({
  action,
  eventId,
  formAction,
  isPending,
}: {
  action: "published" | "cancelled" | "completed";
  eventId: string;
  formAction: (formData: FormData) => void;
  isPending: boolean;
}) {
  const actionDetails = {
    cancelled: {
      className:
        "border border-[#c9785b] bg-[#fff0e9] text-[#9a432d] hover:bg-[#f8ddd3]",
      icon: Ban,
      label: "Cancel event",
    },
    completed: {
      className:
        "border border-[#8ca097] bg-[#e8f0e9] text-[#19352d] hover:bg-[#d6e5d8]",
      icon: CheckCircle2,
      label: "Mark completed",
    },
    published: {
      className: "bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]",
      icon: Megaphone,
      label: "Publish event",
    },
  }[action];
  const Icon = actionDetails.icon;

  return (
    <form action={formAction}>
      <input name="eventId" type="hidden" value={eventId} />
      <input name="targetStatus" type="hidden" value={action} />
      <Button
        className={actionDetails.className}
        disabled={isPending}
        type="submit"
      >
        <Icon aria-hidden="true" className="size-4" />
        {isPending ? "Updating..." : actionDetails.label}
      </Button>
    </form>
  );
}

export function EventStatusControl({
  canComplete,
  eventId,
  status,
}: EventStatusControlProps) {
  const [state, formAction, isPending] = useActionState<
    EventStatusActionState,
    FormData
  >(setEventStatus, initialEventStatusActionState);

  return (
    <section className="border-y border-[#c9d6d0] py-8">
      <div className="flex flex-wrap items-start justify-between gap-5">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
            Publication and moderation
          </p>
          <h2 className="mt-3 text-3xl font-semibold leading-tight text-[#19352d]">
            Keep the event status deliberate
          </h2>
          <p className="mt-3 max-w-2xl text-sm leading-6 text-[#71847b]">
            Status changes are recorded with the manager who made them. Cancelled events close their active registration queue.
          </p>
        </div>
        <span className="border border-[#b8c8bf] bg-[#fffdf8] px-3 py-2 text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
          {statusLabels[status]}
        </span>
      </div>

      {status === "draft" ? (
        <div className="mt-6 flex flex-wrap gap-3">
          <StatusForm
            action="published"
            eventId={eventId}
            formAction={formAction}
            isPending={isPending}
          />
          <StatusForm
            action="cancelled"
            eventId={eventId}
            formAction={formAction}
            isPending={isPending}
          />
        </div>
      ) : status === "published" ? (
        <div className="mt-6 flex flex-wrap items-center gap-3">
          <StatusForm
            action="cancelled"
            eventId={eventId}
            formAction={formAction}
            isPending={isPending}
          />
          {canComplete ? (
            <StatusForm
              action="completed"
              eventId={eventId}
              formAction={formAction}
              isPending={isPending}
            />
          ) : (
            <p className="text-sm leading-6 text-[#71847b]">
              Completion becomes available after the event ends.
            </p>
          )}
        </div>
      ) : (
        <p className="mt-6 text-sm leading-6 text-[#71847b]">
          This event no longer accepts status changes.
        </p>
      )}

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
