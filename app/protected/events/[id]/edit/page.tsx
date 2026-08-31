import { ArrowLeft, CalendarDays, Clock3, Mountain } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";

import { EventInstanceForm } from "@/components/event-instance-form";
import type {
  EventActivityType,
  EventStatus,
  EventVisibility,
} from "@/app/protected/events/[id]/edit/actions";
import { EventStatusControl } from "@/components/event-status-control";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

type EventManagementRecord = {
  id: string;
  series_id: string | null;
  title: string;
  public_summary: string;
  starts_at: string;
  ends_at: string;
  timezone_name: string;
  activity_type: EventActivityType;
  difficulty: string | null;
  visibility: EventVisibility;
  status: EventStatus;
};

type PrivateEventDetails = {
  member_description: string;
  exact_location: string | null;
  waiver_required: boolean;
};

const eventIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function formatLocalDateTime(isoDate: string, timezone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    day: "2-digit",
    hour: "2-digit",
    hourCycle: "h23",
    minute: "2-digit",
    month: "2-digit",
    timeZone: timezone,
    year: "numeric",
  }).formatToParts(new Date(isoDate));
  const values = Object.fromEntries(
    parts.map(({ type, value }) => [type, value]),
  );

  return `${values.year}-${values.month}-${values.day}T${values.hour}:${values.minute}`;
}

function formatEventDate(isoDate: string, timezone: string) {
  return new Intl.DateTimeFormat("en-CA", {
    day: "numeric",
    month: "long",
    timeZone: timezone,
    weekday: "long",
  }).format(new Date(isoDate));
}

function formatEventTime(isoDate: string, timezone: string) {
  return new Intl.DateTimeFormat("en-CA", {
    hour: "numeric",
    minute: "2-digit",
    timeZone: timezone,
    timeZoneName: "short",
  }).format(new Date(isoDate));
}

export const metadata: Metadata = {
  title: "Edit event | UCOA Outdoor Adventurers",
  description: "Edit a hosted UCOA event instance.",
};

export const instant = false;

export default async function EventInstanceEditPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  if (!eventIdPattern.test(id)) {
    notFound();
  }

  if (!hasEnvVars) {
    return (
      <main className="min-h-screen bg-[#f3f0e8] text-[#19352d]">
        <div className="mx-auto max-w-3xl px-5 py-16 sm:px-8">
          <Mountain aria-hidden="true" className="size-9 text-[#b35f35]" />
          <h1 className="mt-6 text-4xl font-semibold tracking-tight">
            Event editing is not connected yet.
          </h1>
          <p className="mt-3 text-sm leading-6 text-[#71847b]">
            Configure the Supabase environment to edit UCOA event instances.
          </p>
        </div>
      </main>
    );
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    redirect("/auth/login");
  }

  const { data: event, error: eventError } = await supabase
    .from("event_management")
    .select(
      "id, series_id, title, public_summary, starts_at, ends_at, timezone_name, activity_type, difficulty, visibility, status",
    )
    .eq("id", id)
    .maybeSingle();

  if (eventError || !event) {
    notFound();
  }

  const { data: privateDetails, error: detailsError } = await supabase
    .from("event_private_details")
    .select("member_description, exact_location, waiver_required")
    .eq("event_id", id)
    .maybeSingle();

  if (detailsError) {
    notFound();
  }

  const typedEvent = event as EventManagementRecord;
  const typedDetails = privateDetails as PrivateEventDetails | null;

  return (
    <main className="min-h-screen bg-[#f3f0e8] text-[#19352d]">
      <header className="border-b border-[#c9d6d0] bg-[#f8f6f0]">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-6 px-5 py-5 sm:px-8 lg:px-12">
          <Link
            className="flex items-center gap-3 text-sm font-bold uppercase tracking-[0.16em] text-[#19352d]"
            href="/"
          >
            <span className="flex size-9 items-center justify-center bg-[#19352d] text-[#f3f0e8]">
              <Mountain aria-hidden="true" className="size-5" />
            </span>
            UCOA
          </Link>
          <Link
            className="text-sm font-semibold text-[#557268] transition-colors hover:text-[#19352d]"
            href={`/events/${typedEvent.id}`}
          >
            Event details
          </Link>
        </div>
      </header>

      <section className="border-b border-[#c9d6d0] bg-[#dfe9e1]">
        <div className="mx-auto w-full max-w-6xl px-5 py-12 sm:px-8 lg:px-12 lg:py-16">
          <Link
            className="inline-flex items-center gap-2 text-sm font-semibold text-[#557268] transition-colors hover:text-[#19352d]"
            href={`/events/${typedEvent.id}`}
          >
            <ArrowLeft aria-hidden="true" className="size-4" />
            Back to event
          </Link>
          <p className="mt-10 text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
            Organizer workspace
          </p>
          <h1 className="mt-4 max-w-4xl text-4xl font-semibold leading-tight tracking-[-0.03em] text-[#19352d] sm:text-6xl">
            Edit event instance
          </h1>
          <p className="mt-4 max-w-3xl text-lg leading-8 text-[#40574e]">
            {typedEvent.title}
          </p>
        </div>
      </section>

      <section className="mx-auto w-full max-w-6xl px-5 py-10 sm:px-8 lg:px-12 lg:py-14">
        <div className="grid gap-8 border-b border-[#c9d6d0] pb-10 md:grid-cols-3">
          <div className="flex items-start gap-3">
            <CalendarDays aria-hidden="true" className="mt-1 size-5 shrink-0 text-[#b35f35]" />
            <div>
              <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
                Date
              </p>
              <p className="mt-2 font-semibold text-[#19352d]">
                {formatEventDate(typedEvent.starts_at, typedEvent.timezone_name)}
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <Clock3 aria-hidden="true" className="mt-1 size-5 shrink-0 text-[#b35f35]" />
            <div>
              <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
                Time
              </p>
              <p className="mt-2 font-semibold text-[#19352d]">
                {formatEventTime(typedEvent.starts_at, typedEvent.timezone_name)}
                <span className="px-2 text-[#9fb2a8]">to</span>
                {formatEventTime(typedEvent.ends_at, typedEvent.timezone_name)}
              </p>
            </div>
          </div>
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
              Publication
            </p>
            <p className="mt-2 font-semibold capitalize text-[#19352d]">
              {typedEvent.status}
            </p>
            <p className="mt-1 text-sm leading-6 text-[#71847b]">
              Editing leaves publication status unchanged.
            </p>
          </div>
        </div>

        <EventStatusControl
          canComplete={
            typedEvent.status === "published" &&
            new Date(typedEvent.ends_at).getTime() <= Date.now()
          }
          eventId={typedEvent.id}
          status={typedEvent.status}
        />

        <div className="grid gap-10 pt-10 lg:grid-cols-[0.75fr_1.25fr] lg:items-start">
          <div className="border-l-2 border-[#b35f35] pl-5 text-[#40574e]">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
              One instance at a time
            </p>
            <h2 className="mt-3 text-3xl font-semibold leading-tight text-[#19352d]">
              Keep the series intact
            </h2>
            <p className="mt-3 text-sm leading-6 text-[#71847b]">
              This editor changes only this concrete event. Its recurring-series link and original creator stay fixed.
            </p>
            {typedEvent.series_id ? (
              <p className="mt-6 border-t border-[#c9d6d0] pt-5 text-sm leading-6 text-[#71847b]">
                This event belongs to a recurring series. Schedule changes are saved using the timezone shown in the form.
              </p>
            ) : null}
          </div>
          <EventInstanceForm
            eventId={typedEvent.id}
            initialValues={{
              activityType: typedEvent.activity_type,
              difficulty: typedEvent.difficulty ?? "",
              endsLocal: formatLocalDateTime(
                typedEvent.ends_at,
                typedEvent.timezone_name,
              ),
              exactLocation: typedDetails?.exact_location ?? "",
              memberDescription: typedDetails?.member_description ?? "",
              publicSummary: typedEvent.public_summary,
              startsLocal: formatLocalDateTime(
                typedEvent.starts_at,
                typedEvent.timezone_name,
              ),
              title: typedEvent.title,
              timezoneName: typedEvent.timezone_name,
              visibility: typedEvent.visibility,
              waiverRequired: typedDetails?.waiver_required ?? false,
            }}
          />
        </div>
      </section>
    </main>
  );
}