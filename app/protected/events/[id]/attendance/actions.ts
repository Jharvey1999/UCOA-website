"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

export type EventAttendanceStatus = "attended" | "no_show";

export type EventAttendanceActionState = {
  result: "idle" | "success" | "error";
  message: string;
  registrationId: string | null;
  attendanceStatus: EventAttendanceStatus | null;
};

export const initialEventAttendanceActionState: EventAttendanceActionState = {
  result: "idle",
  message: "",
  registrationId: null,
  attendanceStatus: null,
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