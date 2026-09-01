"use client";

import { ExternalLink, FileCheck2, ShieldCheck } from "lucide-react";
import { useActionState } from "react";

import {
  recordEventWaiverAcknowledgement,
} from "@/app/events/[id]/actions";
import { initialEventWaiverAcknowledgementActionState } from "@/app/events/[id]/action-state";
import { Button } from "@/components/ui/button";

export type EventWaiverAcknowledgementMethod =
  | "built_in"
  | "external"
  | "organizer_recorded";

export type EventWaiverAcknowledgementStatus = "acknowledged" | "revoked";

export type EventWaiverStatus = {
  version: string | null;
  acknowledgementMethod: EventWaiverAcknowledgementMethod | null;
  documentReference: string | null;
  acknowledgementStatus: EventWaiverAcknowledgementStatus | null;
};

type EventWaiverControlProps = {
  eventId: string;
  waiverRequired: boolean;
  status: EventWaiverStatus | null;
};

function getApprovedDocumentUrl(reference: string | null, eventId: string) {
  if (!reference) {
    return null;
  }

  if (reference.startsWith("waivers/")) {
    return `/api/events/${eventId}/waiver-document`;
  }

  try {
    const url = new URL(reference);
    return url.protocol === "https:" ? url.toString() : null;
  } catch {
    return null;
  }
}

export function EventWaiverControl({
  eventId,
  status,
  waiverRequired,
}: EventWaiverControlProps) {
  const [state, formAction, isPending] = useActionState(
    recordEventWaiverAcknowledgement,
    initialEventWaiverAcknowledgementActionState,
  );

  if (!waiverRequired) {
    return null;
  }

  const acknowledgementStatus =
    state.result === "success" ? "acknowledged" : status?.acknowledgementStatus;
  const version = state.result === "success" ? state.version : status?.version;
  const method = status?.acknowledgementMethod;
  const approvedDocumentUrl = getApprovedDocumentUrl(
    status?.documentReference ?? null,
    eventId,
  );
  const isPrivateDocument = status?.documentReference?.startsWith("waivers/");
  const isAcknowledged = acknowledgementStatus === "acknowledged";
  const isBuiltIn = method === "built_in";
  const workflowAvailable = Boolean(version && method);

  return (
    <div className="mt-8 border-t border-[#c9d6d0] pt-6">
      <div className="flex items-start gap-3">
        <ShieldCheck aria-hidden="true" className="mt-0.5 size-6 shrink-0 text-[#b35f35]" />
        <div className="min-w-0">
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
            Waiver acknowledgement
          </p>
          <h3 className="mt-2 text-xl font-semibold leading-tight text-[#19352d]">
            Approved waiver required
          </h3>
        </div>
      </div>

      {workflowAvailable ? (
        <p className="mt-4 text-sm leading-6 text-[#71847b]">
          Approved version <span className="font-semibold text-[#40574e]">{version}</span>
          {isAcknowledged ? " is acknowledged for this event." : " must be acknowledged before RSVP."}
        </p>
      ) : (
        <p className="mt-4 text-sm leading-6 text-[#9a432d]">
          The approved waiver workflow is not available for this event. Registration remains closed until UCOA configures it.
        </p>
      )}

      {approvedDocumentUrl ? (
        <a
          className="mt-4 inline-flex items-center gap-2 text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4"
          href={approvedDocumentUrl}
          rel="noreferrer"
          target="_blank"
        >
          {isPrivateDocument ? "Review approved waiver document" : "Review approved waiver reference"}
          <ExternalLink aria-hidden="true" className="size-4" />
        </a>
      ) : null}

      {isAcknowledged ? (
        <p className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-[#40574e]">
          <FileCheck2 aria-hidden="true" className="size-4 text-[#b35f35]" />
          Acknowledgement recorded
        </p>
      ) : isBuiltIn && workflowAvailable ? (
        <form action={formAction} className="mt-5">
          <input name="eventId" type="hidden" value={eventId} />
          <label className="flex items-start gap-3 text-sm leading-6 text-[#40574e]">
            <input
              className="mt-1 size-4 accent-[#19352d]"
              disabled={isPending}
              name="acknowledge"
              required
              type="checkbox"
              value="true"
            />
            <span>I acknowledge the approved UCOA waiver version shown above.</span>
          </label>
          <Button
            className="mt-4 bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]"
            disabled={isPending}
            type="submit"
          >
            <FileCheck2 aria-hidden="true" className="size-4" />
            {isPending ? "Recording..." : "Acknowledge waiver"}
          </Button>
        </form>
      ) : method === "external" ? (
        <p className="mt-5 text-sm leading-6 text-[#71847b]">
          Complete this approved waiver through the external workflow before RSVP.
        </p>
      ) : method === "organizer_recorded" ? (
        <p className="mt-5 text-sm leading-6 text-[#71847b]">
          Completion for this approved waiver is recorded by the event organizer.
        </p>
      ) : null}

      {state.result === "error" ? (
        <p aria-live="polite" className="mt-4 text-sm leading-6 text-[#9a432d]" role="alert">
          {state.message}
        </p>
      ) : state.result === "success" ? (
        <p aria-live="polite" className="mt-4 text-sm leading-6 text-[#557268]" role="status">
          {state.message}
        </p>
      ) : null}
    </div>
  );
}