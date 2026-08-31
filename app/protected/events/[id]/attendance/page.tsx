import { ArrowLeft, CalendarDays, Clock3, Mountain, Users } from "lucide-react";
import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import Link from "next/link";

import {
  EventAttendanceRoster,
  type EventAttendanceRow,
} from "@/components/event-attendance-roster";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

type EventManagementRecord = {
  id: string;
  title: string;
  starts_at: string;
  ends_at: string;
  timezone_name: string;
  status: "draft" | "published" | "cancelled" | "completed";
};

const eventIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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
  title: "Attendance | UCOA Outdoor Adventurers",
  description: "Record attendance for a hosted UCOA event.",
};

export const instant = false;

export default async function EventAttendancePage({
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
            Attendance is not connected yet.
          </h1>
          <p className="mt-3 text-sm leading-6 text-[#71847b]">
            Configure the Supabase environment to manage event attendance.
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
    .select("id, title, starts_at, ends_at, timezone_name, status")
    .eq("id", id)
    .maybeSingle();

  if (eventError || !event) {
    notFound();
  }

  const { data: attendanceRows, error: attendanceError } = await supabase.rpc(
    "list_event_attendance",
    { p_event_id: id },
  );

  const rows = attendanceError
    ? []
    : (attendanceRows as EventAttendanceRow[] | null) ?? [];
  const attendanceUnavailable = Boolean(attendanceError);
  const typedEvent = event as EventManagementRecord;

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
            Attendance
          </h1>
          <p className="mt-4 max-w-3xl text-lg leading-8 text-[#40574e]">
            {typedEvent.title}
          </p>
        </div>
      </section>

      <section className="mx-auto w-full max-w-6xl px-5 py-10 sm:px-8 lg:px-12 lg:py-14">
        <div className="grid gap-8 border-b border-[#c9d6d0] pb-10 sm:grid-cols-3">
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
          <div className="flex items-start gap-3">
            <Users aria-hidden="true" className="mt-1 size-5 shrink-0 text-[#b35f35]" />
            <div>
              <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
                Event status
              </p>
              <p className="mt-2 font-semibold capitalize text-[#19352d]">
                {typedEvent.status}
              </p>
            </div>
          </div>
        </div>

        <div className="pt-10">
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
            Registration roster
          </p>
          <h2 className="mt-3 text-3xl font-semibold leading-tight text-[#19352d]">
            Check in members after the outing
          </h2>
          <p className="mt-3 max-w-2xl text-sm leading-6 text-[#71847b]">
            Only the minimum approved name fields are shown here. Attendance changes are recorded in the event audit trail.
          </p>

          {attendanceUnavailable ? (
            <p className="mt-8 border-y border-[#c9785b] bg-[#fff0e9] px-4 py-4 text-sm leading-6 text-[#9a432d]">
              The attendance roster is temporarily unavailable.
            </p>
          ) : (
            <div className="mt-8">
              <EventAttendanceRoster eventId={typedEvent.id} rows={rows} />
            </div>
          )}
        </div>
      </section>
    </main>
  );
}