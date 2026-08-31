import {
  ArrowLeft,
  CalendarDays,
  Clock3,
  Mountain,
  Pencil,
  ShieldCheck,
  Users,
} from "lucide-react";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";

import { EventRsvpControl } from "@/components/event-rsvp-control";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

type EventRecord = {
  id: string;
  title: string;
  public_summary: string;
  starts_at: string;
  ends_at: string;
  timezone_name: string;
  activity_type: string;
  difficulty: string | null;
  visibility: "public" | "members_only";
  status: "published" | "cancelled" | "completed";
};

type PrivateEventDetails = {
  member_description: string;
  exact_location: string | null;
  waiver_required: boolean;
};

type EventRegistration = {
  status: "confirmed" | "waitlisted" | "cancelled" | "attended" | "no_show";
  waitlist_position: number | null;
};

const eventIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const activityLabels: Record<string, string> = {
  camping: "Camping",
  climbing: "Climbing",
  course: "Course",
  hike: "Hike",
  other: "Outdoor event",
  scramble: "Scramble",
  social: "Social",
};

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

async function loadEvent(eventId: string) {
  if (!hasEnvVars) {
    return {
      details: null,
      event: null,
      canManage: false,
      initialRegistrationStatus: null,
      initialWaitlistPosition: null,
      signedIn: false,
      unavailable: true,
    };
  }

  const supabase = await createClient();
  const { data: event, error } = await supabase
    .from("events")
    .select(
      "id, title, public_summary, starts_at, ends_at, timezone_name, activity_type, difficulty, visibility, status",
    )
    .eq("id", eventId)
    .maybeSingle();

  if (error || !event) {
    return {
      details: null,
      event: null,
      canManage: false,
      initialRegistrationStatus: null,
      initialWaitlistPosition: null,
      signedIn: false,
      unavailable: false,
    };
  }

  const { data: claims } = await supabase.auth.getClaims();
  const currentUserId = claims?.claims?.sub;
  const signedIn = Boolean(currentUserId);
  let canManage = false;
  let details: PrivateEventDetails | null = null;
  let registration: EventRegistration | null = null;

  if (currentUserId) {
    const { data: managedEvent } = await supabase
      .from("event_management")
      .select("id")
      .eq("id", eventId)
      .maybeSingle();
    canManage = Boolean(managedEvent);

    const { data: privateDetails } = await supabase
      .from("event_private_details")
      .select("member_description, exact_location, waiver_required")
      .eq("event_id", eventId)
      .maybeSingle();
    details = (privateDetails ?? null) as PrivateEventDetails | null;

    const { data: registrationData } = await supabase
      .from("event_registrations")
      .select("status, waitlist_position")
      .eq("event_id", eventId)
      .eq("user_id", currentUserId)
      .maybeSingle();
    registration = (registrationData ?? null) as EventRegistration | null;
  }

  return {
    details,
    event: event as EventRecord,
    canManage,
    initialRegistrationStatus: registration?.status ?? null,
    initialWaitlistPosition: registration?.waitlist_position ?? null,
    signedIn,
    unavailable: false,
  };
}

function UnavailableState() {
  return (
    <main className="min-h-screen bg-[#f3f0e8] text-[#19352d]">
      <div className="mx-auto flex min-h-screen w-full max-w-3xl flex-col justify-center px-5 py-16 sm:px-8">
        <Mountain aria-hidden="true" className="size-9 text-[#b35f35]" />
        <h1 className="mt-6 text-4xl font-semibold tracking-tight">
          Event details are not connected yet.
        </h1>
        <p className="mt-3 max-w-lg text-sm leading-6 text-[#71847b]">
          Configure the Supabase environment to load the UCOA event calendar.
        </p>
        <Link
          className="mt-7 inline-flex items-center gap-2 self-start text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4"
          href="/events"
        >
          <ArrowLeft aria-hidden="true" className="size-4" />
          Back to events
        </Link>
      </div>
    </main>
  );
}

export const metadata: Metadata = {
  title: "Event details | UCOA Outdoor Adventurers",
  description: "View a UCOA Outdoor Adventurers event.",
};

export const instant = false;

export default async function EventDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  if (!eventIdPattern.test(id)) {
    notFound();
  }

  const {
    details,
    event,
    canManage,
    initialRegistrationStatus,
    initialWaitlistPosition,
    signedIn,
    unavailable,
  } = await loadEvent(id);

  if (unavailable) {
    return <UnavailableState />;
  }

  if (!event) {
    notFound();
  }

  const isCancelled = event.status === "cancelled";
  const isMemberOnly = event.visibility === "members_only";

  return (
    <main className="min-h-screen bg-[#f3f0e8] text-[#19352d]">
      <header className="border-b border-[#c9d6d0] bg-[#f8f6f0]">
        <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-6 px-5 py-5 sm:px-8 lg:px-12">
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
            href="/events"
          >
            All events
          </Link>
        </div>
      </header>

      <section className="border-b border-[#c9d6d0] bg-[#dfe9e1]">
        <div className="mx-auto w-full max-w-5xl px-5 py-12 sm:px-8 lg:px-12 lg:py-20">
          <Link
            className="inline-flex items-center gap-2 text-sm font-semibold text-[#557268] transition-colors hover:text-[#19352d]"
            href="/events"
          >
            <ArrowLeft aria-hidden="true" className="size-4" />
            Back to events
          </Link>
          <div className="mt-10 flex flex-wrap items-center gap-x-3 gap-y-2 text-xs font-bold uppercase tracking-[0.16em] text-[#b35f35]">
            <span>{activityLabels[event.activity_type] ?? "Outdoor event"}</span>
            {event.difficulty ? (
              <>
                <span aria-hidden="true" className="text-[#9fb2a8]">
                  /
                </span>
                <span className="text-[#557268]">{event.difficulty}</span>
              </>
            ) : null}
            {isCancelled ? (
              <span className="border border-[#c9785b] bg-[#fff0e9] px-2 py-1 text-[0.65rem] tracking-[0.12em] text-[#9a432d]">
                Cancelled
              </span>
            ) : null}
          </div>
          <h1 className="mt-5 max-w-4xl text-5xl font-semibold leading-[0.96] tracking-[-0.03em] text-[#19352d] sm:text-7xl">
            {event.title}
          </h1>
          <p className="mt-7 max-w-3xl text-lg leading-8 text-[#40574e]">
            {event.public_summary}
          </p>
        </div>
      </section>

      <section className="mx-auto grid w-full max-w-5xl gap-10 px-5 py-12 sm:px-8 lg:grid-cols-[1.2fr_0.8fr] lg:px-12 lg:py-16">
        <div>
          <div className="border-y border-[#c9d6d0] py-5">
            <div className="flex items-start gap-3 text-[#40574e]">
              <CalendarDays aria-hidden="true" className="mt-1 size-5 shrink-0 text-[#b35f35]" />
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
                  Date
                </p>
                <time className="mt-2 block text-lg font-semibold text-[#19352d]" dateTime={event.starts_at}>
                  {formatEventDate(event.starts_at, event.timezone_name)}
                </time>
              </div>
            </div>
            <div className="mt-6 flex items-start gap-3 text-[#40574e]">
              <Clock3 aria-hidden="true" className="mt-1 size-5 shrink-0 text-[#b35f35]" />
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
                  Time
                </p>
                <p className="mt-2 text-lg font-semibold text-[#19352d]">
                  {formatEventTime(event.starts_at, event.timezone_name)}
                  <span className="px-2 text-[#9fb2a8]">to</span>
                  {formatEventTime(event.ends_at, event.timezone_name)}
                </p>
              </div>
            </div>
          </div>

          {details ? (
            <div className="pt-10">
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
                Member details
              </p>
              <p className="mt-4 whitespace-pre-line text-base leading-8 text-[#40574e]">
                {details.member_description}
              </p>
            </div>
          ) : (
            <div className="pt-10">
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
                Member access
              </p>
              <h2 className="mt-4 text-3xl font-semibold leading-tight text-[#19352d]">
                The route is public. The outing details are not.
              </h2>
              <p className="mt-4 max-w-xl text-base leading-7 text-[#71847b]">
                {isMemberOnly
                  ? "This event is available to eligible UCOA members after sign-in."
                  : "Sign in to see the organizer's event notes and exact location when your membership allows access."}
              </p>
            </div>
          )}
        </div>

        <aside className="self-start border-l-2 border-[#b35f35] pl-6 text-[#40574e]">
          <ShieldCheck aria-hidden="true" className="size-7 text-[#b35f35]" />
          <h2 className="mt-5 text-2xl font-semibold leading-tight text-[#19352d]">
            Member-first event details
          </h2>
          {details ? (
            <>
              <p className="mt-4 text-sm leading-6">
                Exact location
              </p>
              <p className="mt-1 text-lg font-semibold text-[#19352d]">
                {details.exact_location ?? "Shared by the organizer"}
              </p>
              {details.waiver_required ? (
                <p className="mt-6 border-t border-[#c9d6d0] pt-5 text-sm leading-6 text-[#71847b]">
                  This event requires the approved UCOA waiver workflow before
                  registration can open.
                </p>
              ) : null}
            </>
          ) : (
            <p className="mt-4 text-sm leading-6 text-[#71847b]">
              Exact location, attendee information, waiver status, and private
              media are protected by the member portal.
            </p>
          )}
          <EventRsvpControl
            eventId={event.id}
            eventStatus={event.status}
            initialRegistrationStatus={initialRegistrationStatus}
            initialWaitlistPosition={initialWaitlistPosition}
            memberDetailsAvailable={Boolean(details)}
            signedIn={signedIn}
          />
          {canManage ? (
            <div className="mt-6 flex flex-wrap items-center gap-4">
              <Link
                className="inline-flex items-center gap-2 text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4"
                href={`/protected/events/${event.id}/edit`}
              >
                <Pencil aria-hidden="true" className="size-4" />
                Edit event
              </Link>
              <Link
                className="inline-flex items-center gap-2 text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4"
                href={`/protected/events/${event.id}/attendance`}
              >
                <Users aria-hidden="true" className="size-4" />
                Manage attendance
              </Link>
            </div>
          ) : null}
        </aside>
      </section>
    </main>
  );
}
