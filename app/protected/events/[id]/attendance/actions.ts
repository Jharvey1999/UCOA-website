"use server";

import { revalidatePath } from "next/cache";

import {
  initialEventAttendanceActionState,
  initialEventWaiverEvidenceActionState,
} from "./action-state";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

export type EventAttendanceStatus = "attended" | "no_show";

export type EventAttendanceActionState = {
  result: "idle" | "success" | "error";
  message: string;
  registrationId: string | null;
  attendanceStatus: EventAttendanceStatus | null;
};

export type EventWaiverEvidenceActionState = {
  result: "idle" | "success" | "error";
  message: string;
  registrationId: string | null;
  version: string | null;
};

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function errorState(message: string): EventAttendanceActionState {
  return {
    ...initialEventAttendanceActionState,
    result: "error",
    message,
  };
}

function evidenceErrorState(message: string): EventWaiverEvidenceActionState {
  return {
    ...initialEventWaiverEvidenceActionState,
    result: "error",
    message,
  };
}

function mapWaiverEvidenceError(message: string) {
  if (message.includes("not organizer-recorded")) {
    return "This event is not using an organizer-recorded waiver workflow.";
  }

  if (message.includes("approved waiver unavailable")) {
    return "The approved waiver is not available for this event.";
  }

  if (message.includes("waiver evidence unavailable")) {
    return "Waiver evidence is unavailable for this registration.";
  }

  if (message.includes("event waiver unavailable")) {
    return "Waiver evidence is unavailable for this event.";
  }

  if (message.includes("waiver evidence reference is invalid")) {
    return "Enter a valid waiver evidence reference.";
  }

  return "We could not record waiver evidence. Please try again.";
}

export async function recordEventAttendance(
  _previousState: EventAttendanceActionState,
  formData: FormData,
): Promise<EventAttendanceActionState> {
  const eventId = formData.get("eventId");
  const registrationId = formData.get("registrationId");
  const attendance = formData.get("attendance");

  if (
    typeof eventId !== "string" ||
    !uuidPattern.test(eventId) ||
    typeof registrationId !== "string" ||
    !uuidPattern.test(registrationId) ||
    (attendance !== "attended" && attendance !== "no_show")
  ) {
    return errorState("We could not update attendance. Please try again.");
  }

  if (!hasEnvVars) {
    return errorState("Attendance is not connected yet.");
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return errorState("Sign in with an active UCOA account to manage attendance.");
  }

  const { data: registration, error: registrationError } = await supabase
    .from("event_registrations")
    .select("user_id")
    .eq("id", registrationId)
    .eq("event_id", eventId)
    .maybeSingle();

  if (registrationError || !registration) {
    return errorState("Attendance is unavailable for this event.");
  }

  const { data, error } = await supabase.rpc("record_event_attendance", {
    p_event_id: eventId,
    p_user_id: registration.user_id,
    p_attendance: attendance,
  });

  if (error) {
    if (error.message.includes("attendance is invalid")) {
      return errorState("We could not update attendance. Please try again.");
    }

    return errorState("Attendance is unavailable for this event.");
  }

  const result = (Array.isArray(data) ? data[0] : data) as
    | { registration_status: EventAttendanceStatus }
    | undefined;

  if (!result) {
    return errorState("We could not update attendance. Please try again.");
  }

  revalidatePath(`/protected/events/${eventId}/attendance`);
  revalidatePath(`/events/${eventId}`);

  return {
    result: "success",
    message:
      attendance === "attended"
        ? "Attendance marked as attended."
        : "Attendance marked as no show.",
    registrationId,
    attendanceStatus: result.registration_status,
  };
}

export async function recordEventWaiverEvidence(
  _previousState: EventWaiverEvidenceActionState,
  formData: FormData,
): Promise<EventWaiverEvidenceActionState> {
  const eventId = formData.get("eventId");
  const registrationId = formData.get("registrationId");
  const evidenceReference = formData.get("evidenceReference");

  if (
    typeof eventId !== "string" ||
    !uuidPattern.test(eventId) ||
    typeof registrationId !== "string" ||
    !uuidPattern.test(registrationId) ||
    typeof evidenceReference !== "string" ||
    evidenceReference.trim().length < 1 ||
    evidenceReference.trim().length > 600
  ) {
    return evidenceErrorState("Enter a valid waiver evidence reference.");
  }

  if (!hasEnvVars) {
    return evidenceErrorState("The waiver workflow is not connected yet.");
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return evidenceErrorState("Sign in with an active UCOA account to record waiver evidence.");
  }

  const { data, error } = await supabase.rpc("record_event_waiver_evidence", {
    p_event_id: eventId,
    p_registration_id: registrationId,
    p_evidence_reference: evidenceReference.trim(),
  });

  if (error) {
    return evidenceErrorState(mapWaiverEvidenceError(error.message));
  }

  const evidence = (Array.isArray(data) ? data[0] : data) as
    | {
        acknowledgement_status: "acknowledged" | "revoked";
        version: string;
      }
    | undefined;

  if (!evidence || evidence.acknowledgement_status !== "acknowledged") {
    return evidenceErrorState("We could not record waiver evidence. Please try again.");
  }

  revalidatePath(`/protected/events/${eventId}/attendance`);
  revalidatePath(`/events/${eventId}`);

  return {
    result: "success",
    message: `Waiver evidence recorded for ${evidence.version}.`,
    registrationId,
    version: evidence.version,
  };
}