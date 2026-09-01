"use server";

import { revalidatePath } from "next/cache";

import {
  initialEventRegistrationActionState,
  initialEventWaiverAcknowledgementActionState,
} from "./action-state";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

export type EventRegistrationStatus =
  | "confirmed"
  | "waitlisted"
  | "cancelled"
  | "attended"
  | "no_show";

export type EventRegistrationActionState = {
  result: "idle" | "success" | "error";
  message: string;
  registrationStatus: EventRegistrationStatus | null;
  waitlistPosition: number | null;
};

export type EventWaiverAcknowledgementActionState = {
  result: "idle" | "success" | "error";
  message: string;
  version: string | null;
};

const eventIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type RegistrationIntent = "register" | "cancel";

type RegistrationRpcRow = {
  registration_status: EventRegistrationStatus;
  waitlist_position: number | null;
};

type WaiverAcknowledgementRpcRow = {
  acknowledgement_status: "acknowledged" | "revoked";
  version: string;
};

function errorState(message: string): EventRegistrationActionState {
  return {
    ...initialEventRegistrationActionState,
    result: "error",
    message,
  };
}

function waiverErrorState(message: string): EventWaiverAcknowledgementActionState {
  return {
    ...initialEventWaiverAcknowledgementActionState,
    result: "error",
    message,
  };
}

function mapWaiverError(message: string) {
  if (message.includes("approved waiver workflow is external")) {
    return "This event uses an approved waiver workflow outside this portal.";
  }

  if (message.includes("approved waiver unavailable")) {
    return "The approved waiver is not available for this event.";
  }

  if (message.includes("event waiver unavailable")) {
    return "Sign in with an active UCOA membership to acknowledge this waiver.";
  }

  return "We could not record your waiver acknowledgement. Please try again.";
}

function mapRegistrationError(message: string, intent: RegistrationIntent) {
  if (message.includes("approved waiver completion is required")) {
    return "Registration is waiting for the approved waiver workflow.";
  }

  if (message.includes("event is full")) {
    return "This event is full and does not have a waitlist.";
  }

  if (message.includes("event registration is closed")) {
    return "Registration is closed for this event.";
  }

  if (message.includes("event registration unavailable")) {
    return intent === "cancel"
      ? "No active registration was found for this event."
      : "This event is unavailable for registration.";
  }

  return "We could not update your registration. Please try again.";
}

export async function updateEventRegistration(
  _previousState: EventRegistrationActionState,
  formData: FormData,
): Promise<EventRegistrationActionState> {
  const eventId = formData.get("eventId");
  const intent = formData.get("intent");

  if (
    typeof eventId !== "string" ||
    !eventIdPattern.test(eventId) ||
    (intent !== "register" && intent !== "cancel")
  ) {
    return errorState("We could not update your registration. Please try again.");
  }

  if (!hasEnvVars) {
    return errorState("Event registration is not connected yet.");
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return errorState("Sign in with an active UCOA account to RSVP.");
  }

  const functionName =
    intent === "register"
      ? "register_for_event"
      : "cancel_event_registration";
  const { data, error } = await supabase.rpc(functionName, {
    p_event_id: eventId,
  });

  if (error) {
    return errorState(mapRegistrationError(error.message, intent));
  }

  const registration = (Array.isArray(data) ? data[0] : data) as
    | RegistrationRpcRow
    | undefined;

  if (!registration) {
    return errorState("We could not update your registration. Please try again.");
  }

  revalidatePath(`/events/${eventId}`);

  const isWaitlisted = registration.registration_status === "waitlisted";
  const message =
    intent === "cancel"
      ? "Your registration has been cancelled."
      : isWaitlisted
        ? `You are on the waitlist at position ${registration.waitlist_position}.`
        : "You are confirmed for this event.";

  return {
    result: "success",
    message,
    registrationStatus: registration.registration_status,
    waitlistPosition: registration.waitlist_position,
  };
}

export async function recordEventWaiverAcknowledgement(
  _previousState: EventWaiverAcknowledgementActionState,
  formData: FormData,
): Promise<EventWaiverAcknowledgementActionState> {
  const eventId = formData.get("eventId");
  const acknowledgementConsent = formData.get("acknowledge");

  if (
    typeof eventId !== "string" ||
    !eventIdPattern.test(eventId) ||
    acknowledgementConsent !== "true"
  ) {
    return waiverErrorState("We could not record your waiver acknowledgement. Please try again.");
  }

  if (!hasEnvVars) {
    return waiverErrorState("The waiver workflow is not connected yet.");
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return waiverErrorState("Sign in with an active UCOA account to acknowledge this waiver.");
  }

  const { data, error } = await supabase.rpc(
    "record_event_waiver_acknowledgement",
    { p_event_id: eventId },
  );

  if (error) {
    return waiverErrorState(mapWaiverError(error.message));
  }

  const acknowledgement = (Array.isArray(data) ? data[0] : data) as
    | WaiverAcknowledgementRpcRow
    | undefined;

  if (!acknowledgement || acknowledgement.acknowledgement_status !== "acknowledged") {
    return waiverErrorState("We could not record your waiver acknowledgement. Please try again.");
  }

  revalidatePath(`/events/${eventId}`);

  return {
    result: "success",
    message: `The approved waiver version ${acknowledgement.version} is acknowledged for this event.`,
    version: acknowledgement.version,
  };
}