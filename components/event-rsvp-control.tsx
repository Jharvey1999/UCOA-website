"use client";

import {
  ArrowUpRight,
  Check,
  Clock3,
  LogIn,
  UserRoundCheck,
  X,
} from "lucide-react";
import Link from "next/link";
import { useActionState } from "react";

import {
  initialEventRegistrationActionState,
  updateEventRegistration,
  type EventRegistrationStatus,
} from "@/app/events/[id]/actions";
import { Button } from "@/components/ui/button";

type EventRsvpControlProps = {
  eventId: string;
  eventStatus: "published" | "cancelled" | "completed";
  signedIn: boolean;
  memberDetailsAvailable: boolean;
  initialRegistrationStatus: EventRegistrationStatus | null;
  initialWaitlistPosition: number | null;
};

function StatusIcon({ status }: { status: EventRegistrationStatus }) {
  if (status === "confirmed") {
    return <Check aria-hidden="true" className="size-5" />;
  }

  if (status === "waitlisted") {
    return <Clock3 aria-hidden="true" className="size-5" />;
  }

  if (status === "cancelled") {
    return <X aria-hidden="true" className="size-5" />;
  }

  return <UserRoundCheck aria-hidden="true" className="size-5" />;
}

export function EventRsvpControl({
  eventId,
  eventStatus,
  signedIn,
  memberDetailsAvailable,
  initialRegistrationStatus,
  initialWaitlistPosition,
}: EventRsvpControlProps) {
  const [state, formAction, isPending] = useActionState(
    updateEventRegistration,
    initialEventRegistrationActionState,
  );
  const registrationStatus =
    state.result === "success"
      ? state.registrationStatus
      : initialRegistrationStatus;
  const waitlistPosition =
    state.result === "success"
      ? state.waitlistPosition
      : initialWaitlistPosition;

  if (eventStatus !== "published") {
    return (
      <div className="mt-8 border-t border-[#c9d6d0] pt-6">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
          Registration
        </p>
        <p className="mt-3 text-sm leading-6 text-[#71847b]">
          Registration is closed for this event.
        </p>
      </div>
    );
  }

  if (!signedIn) {
    return (
      <div className="mt-8 border-t border-[#c9d6d0] pt-6">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
          Registration
        </p>
        <p className="mt-3 text-sm leading-6 text-[#71847b]">
          Sign in with an active UCOA membership to RSVP.
        </p>
        <Link
          className="mt-5 inline-flex items-center gap-2 bg-[#19352d] px-4 py-3 text-sm font-bold text-[#f3f0e8] transition-colors hover:bg-[#b35f35]"
          href="/auth/login"
        >
          <LogIn aria-hidden="true" className="size-4" />
          Member sign in
        </Link>
      </div>
    );
  }

  if (!memberDetailsAvailable) {
    return (
      <div className="mt-8 border-t border-[#c9d6d0] pt-6">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
          Registration
        </p>
        <p className="mt-3 text-sm leading-6 text-[#71847b]">
          An active UCOA membership is required to RSVP for events.
        </p>
      </div>
    );
  }

  const isConfirmed = registrationStatus === "confirmed";
  const isWaitlisted = registrationStatus === "waitlisted";
  const isClosed = registrationStatus === "attended" || registrationStatus === "no_show";
  const intent = isConfirmed || isWaitlisted ? "cancel" : "register";

  return (
    <div className="mt-8 border-t border-[#c9d6d0] pt-6">
      <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
        Registration
      </p>

      {isConfirmed || isWaitlisted || registrationStatus === "cancelled" ? (
        <div className="mt-4 flex items-start gap-3 text-[#40574e]">
          <span className="mt-0.5 text-[#b35f35]">
            <StatusIcon status={registrationStatus} />
          </span>
          <div>
            <p className="font-semibold text-[#19352d]">
              {isConfirmed
                ? "You are confirmed for this event."
                : isWaitlisted
                  ? `You are on the waitlist at position ${waitlistPosition}.`
                  : "You are not currently registered."}
            </p>
            {isWaitlisted ? (
              <p className="mt-1 text-sm leading-6 text-[#71847b]">
                Your position updates automatically as places open.
              </p>
            ) : null}
          </div>
        </div>
      ) : isClosed ? (
        <p className="mt-3 text-sm leading-6 text-[#71847b]">
          Attendance has closed registration for this event.
        </p>
      ) : (
        <p className="mt-3 text-sm leading-6 text-[#71847b]">
          Reserve your place through the UCOA event system.
        </p>
      )}

      {isClosed ? null : (
        <form action={formAction} className="mt-5">
          <input name="eventId" type="hidden" value={eventId} />
          <input name="intent" type="hidden" value={intent} />
          <Button
            className="bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]"
            disabled={isPending}
            type="submit"
          >
            {isPending ? "Updating..." : intent === "cancel" ? "Cancel RSVP" : "RSVP for this event"}
            <ArrowUpRight aria-hidden="true" className="size-4" />
          </Button>
        </form>
      )}

      {state.result === "error" ? (
        <p aria-live="polite" className="mt-4 text-sm leading-6 text-[#9a432d]" role="alert">
          {state.message}
        </p>
      ) : state.result === "success" ? (
        <p aria-live="polite" className="mt-4 text-sm leading-6 text-[#557268]">
          {state.message}
        </p>
      ) : null}
    </div>
  );
}