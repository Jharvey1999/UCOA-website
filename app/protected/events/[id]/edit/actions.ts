"use server";

import { revalidatePath } from "next/cache";

import {
  initialEventInstanceActionState,
  initialEventStatusActionState,
  initialEventWaiverAssignmentActionState,
} from "./action-state";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

export type EventActivityType =
  | "hike"
  | "scramble"
  | "climbing"
  | "camping"
  | "course"
  | "social"
  | "other";

export type EventVisibility = "public" | "members_only";

export type EventStatus = "draft" | "published" | "cancelled" | "completed";

type EventStatusAction = Exclude<EventStatus, "draft">;

export type EventInstanceActionState = {
  result: "idle" | "success" | "error";
  message: string;
};

export type EventStatusActionState = {
  result: "idle" | "success" | "error";
  message: string;
};

export type EventWaiverAssignmentActionState = {
  result: "idle" | "success" | "error";
  message: string;
};

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const localDateTimePattern =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/;
const activityTypes: EventActivityType[] = [
  "hike",
  "scramble",
  "climbing",
  "camping",
  "course",
  "social",
  "other",
];
const visibilityTypes: EventVisibility[] = ["public", "members_only"];
const statusActions: EventStatusAction[] = ["published", "cancelled", "completed"];

function errorState(message: string): EventInstanceActionState {
  return {
    ...initialEventInstanceActionState,
    result: "error",
    message,
  };
}

function isActivityType(value: string): value is EventActivityType {
  return activityTypes.includes(value as EventActivityType);
}

function isVisibility(value: string): value is EventVisibility {
  return visibilityTypes.includes(value as EventVisibility);
}

function isStatusAction(value: string): value is EventStatusAction {
  return statusActions.includes(value as EventStatusAction);
}

export async function updateEventInstance(
  _previousState: EventInstanceActionState,
  formData: FormData,
): Promise<EventInstanceActionState> {
  const eventId = formData.get("eventId");
  const title = formData.get("title");
  const publicSummary = formData.get("publicSummary");
  const startsLocal = formData.get("startsLocal");
  const endsLocal = formData.get("endsLocal");
  const timezoneName = formData.get("timezoneName");
  const activityType = formData.get("activityType");
  const difficulty = formData.get("difficulty");
  const visibility = formData.get("visibility");
  const memberDescription = formData.get("memberDescription");
  const exactLocation = formData.get("exactLocation");

  if (
    typeof eventId !== "string" ||
    !uuidPattern.test(eventId) ||
    typeof title !== "string" ||
    title.trim().length < 1 ||
    title.trim().length > 160 ||
    typeof publicSummary !== "string" ||
    publicSummary.trim().length < 1 ||
    publicSummary.trim().length > 2400 ||
    typeof startsLocal !== "string" ||
    !localDateTimePattern.test(startsLocal) ||
    typeof endsLocal !== "string" ||
    !localDateTimePattern.test(endsLocal) ||
    typeof timezoneName !== "string" ||
    timezoneName.trim().length < 1 ||
    typeof activityType !== "string" ||
    !isActivityType(activityType) ||
    typeof visibility !== "string" ||
    !isVisibility(visibility) ||
    typeof memberDescription !== "string" ||
    memberDescription.trim().length < 1 ||
    memberDescription.trim().length > 12000 ||
    (typeof difficulty !== "string" && difficulty !== null) ||
    (typeof difficulty === "string" && difficulty.trim().length > 40) ||
    (typeof exactLocation !== "string" && exactLocation !== null) ||
    (typeof exactLocation === "string" && exactLocation.trim().length > 600)
  ) {
    return errorState("Check the event details and try again.");
  }

  if (!hasEnvVars) {
    return errorState("Event editing is not connected yet.");
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return errorState("Sign in with an active UCOA account to edit events.");
  }

  const { data, error } = await supabase.rpc("update_event_instance", {
    p_event_id: eventId,
    p_title: title,
    p_public_summary: publicSummary,
    p_starts_local: startsLocal,
    p_ends_local: endsLocal,
    p_timezone_name: timezoneName,
    p_activity_type: activityType,
    p_difficulty: typeof difficulty === "string" && difficulty.trim() ? difficulty : null,
    p_visibility: visibility,
    p_member_description: memberDescription,
    p_exact_location: typeof exactLocation === "string" && exactLocation.trim() ? exactLocation : null,
  });

  if (error) {
    if (error.message.includes("event input is invalid")) {
      return errorState("Check the event details and try again.");
    }

    if (error.message.includes("event unavailable")) {
      return errorState("This event is unavailable for editing.");
    }

    return errorState("We could not save this event. Please try again.");
  }

  const updatedEvent = (Array.isArray(data) ? data[0] : data) as
    | { event_id: string }
    | undefined;

  if (!updatedEvent) {
    return errorState("We could not save this event. Please try again.");
  }

  revalidatePath(`/protected/events/${eventId}/edit`);
  revalidatePath(`/events/${eventId}`);
  revalidatePath("/events");

  return {
    result: "success",
    message: "Event instance saved.",
  };
}

function statusErrorState(message: string): EventStatusActionState {
  return {
    ...initialEventStatusActionState,
    result: "error",
    message,
  };
}

export async function setEventStatus(
  _previousState: EventStatusActionState,
  formData: FormData,
): Promise<EventStatusActionState> {
  const eventId = formData.get("eventId");
  const targetStatus = formData.get("targetStatus");

  if (
    typeof eventId !== "string" ||
    !uuidPattern.test(eventId) ||
    typeof targetStatus !== "string" ||
    !isStatusAction(targetStatus)
  ) {
    return statusErrorState("We could not change the event status. Please try again.");
  }

  if (!hasEnvVars) {
    return statusErrorState("Event moderation is not connected yet.");
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return statusErrorState("Sign in with an active UCOA account to manage events.");
  }

  const { data, error } = await supabase.rpc("set_event_status", {
    p_event_id: eventId,
    p_status: targetStatus,
  });

  if (error) {
    if (error.message.includes("event cannot be published")) {
      return statusErrorState("Add member details before publishing this event.");
    }

    if (error.message.includes("event cannot be completed")) {
      return statusErrorState("This event can be completed after it ends.");
    }

    if (error.message.includes("event status transition is invalid")) {
      return statusErrorState("That event status change is no longer available.");
    }

    if (error.message.includes("event unavailable")) {
      return statusErrorState("This event is unavailable for status changes.");
    }

    return statusErrorState("We could not change this event status. Please try again.");
  }

  const updatedEvent = (Array.isArray(data) ? data[0] : data) as
    | { status: EventStatus }
    | undefined;

  if (!updatedEvent) {
    return statusErrorState("We could not change this event status. Please try again.");
  }

  revalidatePath(`/protected/events/${eventId}/edit`);
  revalidatePath(`/events/${eventId}`);
  revalidatePath("/events");

  const statusMessages: Record<EventStatusAction, string> = {
    cancelled: "Event cancelled.",
    completed: "Event marked as completed.",
    published: "Event published.",
  };

  return {
    result: "success",
    message: statusMessages[targetStatus],
  };
}

function waiverAssignmentErrorState(
  message: string,
): EventWaiverAssignmentActionState {
  return {
    ...initialEventWaiverAssignmentActionState,
    result: "error",
    message,
  };
}

function mapWaiverAssignmentError(message: string) {
  if (message.includes("approved waiver unavailable")) {
    return "Choose an approved waiver before assigning it to this event.";
  }

  if (message.includes("event private details unavailable")) {
    return "Add the event's member details before assigning a waiver.";
  }

  if (message.includes("event unavailable")) {
    return "This event is unavailable for waiver changes.";
  }

  return "We could not update the event waiver. Please try again.";
}

export async function setEventWaiverAssignment(
  _previousState: EventWaiverAssignmentActionState,
  formData: FormData,
): Promise<EventWaiverAssignmentActionState> {
  const eventId = formData.get("eventId");
  const waiverId = formData.get("waiverId");

  if (
    typeof eventId !== "string" ||
    !uuidPattern.test(eventId) ||
    typeof waiverId !== "string" ||
    (waiverId !== "none" && !uuidPattern.test(waiverId))
  ) {
    return waiverAssignmentErrorState("We could not update the event waiver. Please try again.");
  }

  if (!hasEnvVars) {
    return waiverAssignmentErrorState("Waiver management is not connected yet.");
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return waiverAssignmentErrorState("Sign in with an authorized UCOA account to manage waivers.");
  }

  const { data, error } = await supabase.rpc("set_event_waiver", {
    p_event_id: eventId,
    p_waiver_id: waiverId === "none" ? null : waiverId,
  });

  if (error) {
    return waiverAssignmentErrorState(mapWaiverAssignmentError(error.message));
  }

  const assignment = (Array.isArray(data) ? data[0] : data) as
    | { waiver_required: boolean }
    | undefined;

  if (!assignment) {
    return waiverAssignmentErrorState("We could not update the event waiver. Please try again.");
  }

  revalidatePath(`/protected/events/${eventId}/edit`);
  revalidatePath(`/events/${eventId}`);

  return {
    result: "success",
    message: assignment.waiver_required
      ? "Approved waiver assigned to this event."
      : "Waiver requirement cleared for this event.",
  };
}