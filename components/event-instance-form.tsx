"use client";

import { Save } from "lucide-react";
import Link from "next/link";
import { useActionState } from "react";

import {
  initialEventInstanceActionState,
  updateEventInstance,
  type EventActivityType,
  type EventVisibility,
} from "@/app/protected/events/[id]/edit/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type EventInstanceFormValues = {
  title: string;
  publicSummary: string;
  startsLocal: string;
  endsLocal: string;
  timezoneName: string;
  activityType: EventActivityType;
  difficulty: string;
  visibility: EventVisibility;
  memberDescription: string;
  exactLocation: string;
  waiverRequired: boolean;
};

type EventInstanceFormProps = {
  eventId: string;
  initialValues: EventInstanceFormValues;
};

const activityOptions: Array<{ value: EventActivityType; label: string }> = [
  { value: "hike", label: "Hike" },
  { value: "scramble", label: "Scramble" },
  { value: "climbing", label: "Climbing" },
  { value: "camping", label: "Camping" },
  { value: "course", label: "Course" },
  { value: "social", label: "Social" },
  { value: "other", label: "Other" },
];

const fieldClassName =
  "mt-2 border-[#b8c8bf] bg-[#fffdf8] text-[#19352d] focus-visible:ring-[#b35f35]";
const textAreaClassName =
  "mt-2 min-h-32 w-full rounded-md border border-[#b8c8bf] bg-[#fffdf8] px-3 py-2 text-sm leading-6 text-[#19352d] shadow-sm outline-none transition-colors placeholder:text-[#8ca097] focus-visible:ring-1 focus-visible:ring-[#b35f35]";

export function EventInstanceForm({
  eventId,
  initialValues,
}: EventInstanceFormProps) {
  const [state, formAction, isPending] = useActionState(
    updateEventInstance,
    initialEventInstanceActionState,
  );

  return (
    <form action={formAction} className="grid gap-10">
      <input name="eventId" type="hidden" value={eventId} />

      <fieldset className="grid gap-6">
        <legend className="text-xl font-semibold text-[#19352d]">
          Public event information
        </legend>
        <div>
          <Label className="text-[#40574e]" htmlFor="title">
            Title
          </Label>
          <Input
            className={fieldClassName}
            defaultValue={initialValues.title}
            id="title"
            maxLength={160}
            name="title"
            required
          />
        </div>
        <div>
          <Label className="text-[#40574e]" htmlFor="publicSummary">
            Public summary
          </Label>
          <textarea
            className={textAreaClassName}
            defaultValue={initialValues.publicSummary}
            id="publicSummary"
            maxLength={2400}
            name="publicSummary"
            required
          />
        </div>
        <div className="grid gap-6 md:grid-cols-2">
          <div>
            <Label className="text-[#40574e]" htmlFor="activityType">
              Activity
            </Label>
            <select
              className={`${fieldClassName} flex h-9 w-full rounded-md border px-3 py-1 text-sm shadow-sm outline-none focus-visible:ring-1`}
              defaultValue={initialValues.activityType}
              id="activityType"
              name="activityType"
            >
              {activityOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <Label className="text-[#40574e]" htmlFor="difficulty">
              Difficulty
            </Label>
            <Input
              className={fieldClassName}
              defaultValue={initialValues.difficulty}
              id="difficulty"
              maxLength={40}
              name="difficulty"
              placeholder="Optional"
            />
          </div>
        </div>
        <div>
          <Label className="text-[#40574e]" htmlFor="visibility">
            Visibility
          </Label>
          <select
            className={`${fieldClassName} flex h-9 w-full rounded-md border px-3 py-1 text-sm shadow-sm outline-none focus-visible:ring-1`}
            defaultValue={initialValues.visibility}
            id="visibility"
            name="visibility"
          >
            <option value="public">Public summary</option>
            <option value="members_only">Members only</option>
          </select>
        </div>
      </fieldset>

      <fieldset className="grid gap-6 border-t border-[#c9d6d0] pt-8">
        <legend className="text-xl font-semibold text-[#19352d]">
          Schedule
        </legend>
        <div className="grid gap-6 md:grid-cols-2">
          <div>
            <Label className="text-[#40574e]" htmlFor="startsLocal">
              Starts in local time
            </Label>
            <Input
              className={fieldClassName}
              defaultValue={initialValues.startsLocal}
              id="startsLocal"
              name="startsLocal"
              required
              step="900"
              type="datetime-local"
            />
          </div>
          <div>
            <Label className="text-[#40574e]" htmlFor="endsLocal">
              Ends in local time
            </Label>
            <Input
              className={fieldClassName}
              defaultValue={initialValues.endsLocal}
              id="endsLocal"
              name="endsLocal"
              required
              step="900"
              type="datetime-local"
            />
          </div>
        </div>
        <div>
          <Label className="text-[#40574e]" htmlFor="timezoneName">
            Timezone (IANA)
          </Label>
          <Input
            className={fieldClassName}
            defaultValue={initialValues.timezoneName}
            id="timezoneName"
            name="timezoneName"
            required
          />
        </div>
      </fieldset>

      <fieldset className="grid gap-6 border-t border-[#c9d6d0] pt-8">
        <legend className="text-xl font-semibold text-[#19352d]">
          Member details
        </legend>
        <div>
          <Label className="text-[#40574e]" htmlFor="memberDescription">
            Member description
          </Label>
          <textarea
            className={textAreaClassName}
            defaultValue={initialValues.memberDescription}
            id="memberDescription"
            maxLength={12000}
            name="memberDescription"
            required
          />
        </div>
        <div>
          <Label className="text-[#40574e]" htmlFor="exactLocation">
            Exact location
          </Label>
          <textarea
            className={textAreaClassName}
            defaultValue={initialValues.exactLocation}
            id="exactLocation"
            maxLength={600}
            name="exactLocation"
          />
        </div>
        <label className="flex items-start gap-3 text-sm leading-6 text-[#40574e]">
          <input
            className="mt-1 size-4 accent-[#19352d]"
            defaultChecked={initialValues.waiverRequired}
            name="waiverRequired"
            type="checkbox"
            value="true"
          />
          <span>This event requires the approved waiver workflow.</span>
        </label>
      </fieldset>

      {state.result !== "idle" ? (
        <p
          aria-live="polite"
          className={
            state.result === "error"
              ? "border border-[#c9785b] bg-[#fff0e9] px-4 py-3 text-sm leading-6 text-[#9a432d]"
              : "border border-[#b8c8bf] bg-[#e8f0e9] px-4 py-3 text-sm leading-6 text-[#40574e]"
          }
          role={state.result === "error" ? "alert" : "status"}
        >
          {state.message}
        </p>
      ) : null}

      <div className="flex flex-wrap items-center gap-4 border-t border-[#c9d6d0] pt-8">
        <Button
          className="bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]"
          disabled={isPending}
          type="submit"
        >
          <Save aria-hidden="true" className="size-4" />
          {isPending ? "Saving..." : "Save event"}
        </Button>
        <Link
          className="text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4"
          href={`/events/${eventId}`}
        >
          Cancel
        </Link>
      </div>
    </form>
  );
}