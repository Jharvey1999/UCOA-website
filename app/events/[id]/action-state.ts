import type {
  EventRegistrationActionState,
  EventWaiverAcknowledgementActionState,
} from "./actions";

export const initialEventRegistrationActionState: EventRegistrationActionState = {
  result: "idle",
  message: "",
  registrationStatus: null,
  waitlistPosition: null,
};

export const initialEventWaiverAcknowledgementActionState: EventWaiverAcknowledgementActionState = {
  result: "idle",
  message: "",
  version: null,
};