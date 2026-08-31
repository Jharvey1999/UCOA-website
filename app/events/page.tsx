import {
  ArrowLeft,
  ArrowUpRight,
  CalendarDays,
  Clock3,
  Mountain,
  ShieldCheck,
} from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";

import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

export const metadata: Metadata = {
  title: "Events | UCOA Outdoor Adventurers",
  description: "Browse upcoming public events from UCOA Outdoor Adventurers.",
};

type PublicEvent = {
  id: string;
  title: string;
  public_summary: string;
  starts_at: string;
  ends_at: string;
  timezone_name: string;
  activity_type: string;
  difficulty: string | null;
  status: "published" | "cancelled";
};

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
    month: "short",
    timeZone: timezone,
    weekday: "short",
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

async function loadPublicEvents() {
  if (!hasEnvVars) {
    return { events: [], unavailable: true };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("events")
    .select(
      "id, title, public_summary, starts_at, ends_at, timezone_name, activity_type, difficulty, status",
    )
    .eq("visibility", "public")
    .in("status", ["published", "cancelled"])
    .gte("ends_at", new Date().toISOString())
    .order("starts_at", { ascending: true })
    .limit(24);

  return {
    events: (data ?? []) as PublicEvent[],
    unavailable: Boolean(error),
  };
}

function EventCard({ event }: { event: PublicEvent }) {
  const isCancelled = event.status === "cancelled";

  return (
    <article className="group flex h-full flex-col border border-[#c9d6d0] bg-[#fffdf8] shadow-[4px_4px_0_#d9e3dc] transition-transform duration-200 hover:-translate-y-1">
      <div className="flex items-start justify-between gap-4 border-b border-[#dfe8e2] px-5 py-4">
        <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.12em] text-[#557268]">
          <CalendarDays aria-hidden="true" className="size-4" />
          {formatEventDate(event.starts_at, event.timezone_name)}
        </div>
        {isCancelled ? (
          <span className="border border-[#c9785b] bg-[#fff0e9] px-2 py-1 text-[0.65rem] font-bold uppercase tracking-[0.12em] text-[#9a432d]">
            Cancelled
          </span>
        ) : null}
      </div>

      <div className="flex flex-1 flex-col px-5 pb-6 pt-5">
        <div className="mb-4 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs font-semibold uppercase tracking-[0.12em] text-[#b35f35]">
          <span>{activityLabels[event.activity_type] ?? "Outdoor event"}</span>
          {event.difficulty ? (
            <>
              <span aria-hidden="true" className="text-[#b8c8bf]">
                /
              </span>
              <span className="text-[#557268]">{event.difficulty}</span>
            </>
          ) : null}
        </div>

        <h2 className="text-2xl font-semibold leading-tight tracking-tight text-[#19352d]">
          {event.title}
        </h2>
        <p className="mt-3 flex-1 text-sm leading-6 text-[#52665d]">
          {event.public_summary}
        </p>

        <div className="mt-6 border-t border-[#dfe8e2] pt-4 text-sm text-[#40574e]">
          <div className="flex items-start gap-2">
            <Clock3 aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-[#b35f35]" />
            <span>
              {formatEventTime(event.starts_at, event.timezone_name)}
              <span className="px-1 text-[#9fb2a8]">to</span>
              {formatEventTime(event.ends_at, event.timezone_name)}
            </span>
          </div>
          <p className="mt-2 pl-6 text-xs text-[#71847b]">
            Exact location and member details are shared inside the portal.
          </p>
        </div>

        <Link
          className="mt-5 inline-flex items-center gap-2 self-start text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4 transition-colors hover:text-[#b35f35]"
          href={`/events/${event.id}`}
        >
          View event
          <ArrowUpRight aria-hidden="true" className="size-4" />
        </Link>
      </div>
    </article>
  );
}

export default async function EventsPage() {
  const { events, unavailable } = await loadPublicEvents();

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
          <nav aria-label="Primary navigation" className="flex items-center gap-4 text-sm">
            <Link className="font-semibold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-8" href="/events">
              Events
            </Link>
            <Link className="text-[#557268] transition-colors hover:text-[#19352d]" href="/auth/login">
              Member sign in
            </Link>
          </nav>
        </div>
      </header>

      <section className="border-b border-[#c9d6d0] bg-[#dfe9e1]">
        <div className="mx-auto grid w-full max-w-7xl gap-10 px-5 py-14 sm:px-8 lg:grid-cols-[1fr_0.7fr] lg:items-end lg:px-12 lg:py-20">
          <div>
            <Link
              className="mb-8 inline-flex items-center gap-2 text-sm font-semibold text-[#557268] transition-colors hover:text-[#19352d]"
              href="/"
            >
              <ArrowLeft aria-hidden="true" className="size-4" />
              Back to UCOA
            </Link>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
              Public calendar
            </p>
            <h1 className="mt-4 max-w-3xl text-5xl font-semibold leading-[0.96] tracking-[-0.03em] text-[#19352d] sm:text-6xl">
              Find your next good day outside.
            </h1>
          </div>
          <div className="max-w-md border-l-2 border-[#b35f35] pl-5 text-base leading-7 text-[#40574e]">
            <p>
              UCOA brings Calgary-area outdoor adventurers together for hikes,
              scrambles, climbing, courses, camping, and the occasional social.
            </p>
            <div className="mt-6 flex items-center gap-2 text-sm font-semibold text-[#19352d]">
              <ShieldCheck aria-hidden="true" className="size-4 text-[#b35f35]" />
              Public event summaries only
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-5 py-12 sm:px-8 lg:px-12 lg:py-16">
        <div className="mb-8 flex flex-wrap items-end justify-between gap-4 border-b border-[#c9d6d0] pb-5">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#557268]">
              Upcoming
            </p>
            <h2 className="mt-2 text-3xl font-semibold tracking-tight text-[#19352d]">
              What&apos;s on the calendar
            </h2>
          </div>
          <p className="max-w-xs text-sm leading-6 text-[#71847b]">
            Dates and times are shown in each event&apos;s local timezone.
          </p>
        </div>

        {unavailable ? (
          <div className="border border-[#c9d6d0] bg-[#fffdf8] px-6 py-10 text-center shadow-[4px_4px_0_#d9e3dc]">
            <h3 className="text-xl font-semibold text-[#19352d]">
              The calendar is taking a short breather.
            </h3>
            <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[#71847b]">
              Public events are temporarily unavailable. Please check back
              soon.
            </p>
          </div>
        ) : events.length === 0 ? (
          <div className="border border-[#c9d6d0] bg-[#fffdf8] px-6 py-12 shadow-[4px_4px_0_#d9e3dc] sm:px-10">
            <Mountain aria-hidden="true" className="size-8 text-[#b35f35]" />
            <h3 className="mt-5 text-2xl font-semibold text-[#19352d]">
              The next outing is still taking shape.
            </h3>
            <p className="mt-2 max-w-lg text-sm leading-6 text-[#71847b]">
              New public events will appear here once they are published.
              Members can sign in for event details and registration access.
            </p>
            <Link
              className="mt-6 inline-flex items-center gap-2 text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4 transition-colors hover:text-[#b35f35]"
              href="/auth/login"
            >
              Member sign in
              <ArrowUpRight aria-hidden="true" className="size-4" />
            </Link>
          </div>
        ) : (
          <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
            {events.map((event) => (
              <EventCard event={event} key={event.id} />
            ))}
          </div>
        )}
      </section>
    </main>
  );
}