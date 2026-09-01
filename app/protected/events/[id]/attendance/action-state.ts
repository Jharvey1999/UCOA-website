import type {
  EventAttendanceActionState,
  EventWaiverEvidenceActionState,
} from "./actions";

export const initialEventAttendanceActionState: EventAttendanceActionState = {
  result: "idle",
  message: "",
  registrationId: null,
  attendanceStatus: null,
};

export const initialEventWaiverEvidenceActionState: EventWaiverEvidenceActionState = {
  result: "idle",
  message: "",
  registrationId: null,
  version: null,
};