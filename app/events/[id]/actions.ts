"use server";

import { revalidatePath } from "next/cache";

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

export const initialEventRegistrationActionState: EventRegistrationActionState = {
  result: "idle",
  message: "",
  registrationStatus: null,
  waitlistPosition: null,
};

const eventIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type RegistrationIntent = "register" | "cancel";

type RegistrationRpcRow = {
  registration_status: EventRegistrationStatus;
  waitlist_position: number | null;
};

function errorState(message: string): EventRegistrationActionState {
  return {
    ...initialEventRegistrationActionState,
    result: "error",
    message,
  };
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