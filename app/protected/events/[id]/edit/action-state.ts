import type {
  EventInstanceActionState,
  EventStatusActionState,
  EventWaiverAssignmentActionState,
} from "./actions";

export const initialEventInstanceActionState: EventInstanceActionState = {
  result: "idle",
  message: "",
};

export const initialEventStatusActionState: EventStatusActionState = {
  result: "idle",
  message: "",
};

export const initialEventWaiverAssignmentActionState: EventWaiverAssignmentActionState = {
  result: "idle",
  message: "",
};