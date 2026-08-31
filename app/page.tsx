import { ArrowUpRight, CalendarDays, Mountain, ShieldCheck } from "lucide-react";
import Link from "next/link";

export default function Home() {
  return (
    <main className="min-h-screen bg-[#f3f0e8] text-[#19352d]">
      <header className="border-b border-[#c9d6d0] bg-[#f8f6f0]">
        <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-6 px-5 py-5 sm:px-8 lg:px-12">
          <Link
            className="flex items-center gap-3 text-sm font-bold uppercase tracking-[0.16em]"
            href="/"
          >
            <span className="flex size-9 items-center justify-center bg-[#19352d] text-[#f3f0e8]">
              <Mountain aria-hidden="true" className="size-5" />
            </span>
            UCOA
          </Link>
          <nav aria-label="Primary navigation" className="flex items-center gap-4 text-sm">
            <Link
              className="font-semibold text-[#19352d] transition-colors hover:text-[#b35f35]"
              href="/events"
            >
              Events
            </Link>
            <Link
              className="hidden text-[#557268] transition-colors hover:text-[#19352d] sm:inline"
              href="/auth/login"
            >
              Member sign in
            </Link>
            <Link
              className="inline-flex items-center gap-2 bg-[#19352d] px-3 py-2 text-xs font-bold uppercase tracking-[0.12em] text-[#f3f0e8] transition-colors hover:bg-[#b35f35]"
              href="/auth/sign-up"
            >
              Join UCOA
              <ArrowUpRight aria-hidden="true" className="size-4" />
            </Link>
          </nav>
        </div>
      </header>

      <section className="border-b border-[#c9d6d0] bg-[#dfe9e1]">
        <div className="mx-auto grid w-full max-w-7xl gap-12 px-5 py-16 sm:px-8 lg:grid-cols-[1.15fr_0.85fr] lg:items-end lg:px-12 lg:py-24">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
              Calgary outdoor community
            </p>
            <h1 className="mt-5 max-w-4xl text-6xl font-semibold leading-[0.92] tracking-[-0.04em] text-[#19352d] sm:text-7xl">
              Outside is better together.
            </h1>
            <p className="mt-7 max-w-xl text-lg leading-8 text-[#40574e]">
              UCOA makes it easier to find good people, good routes, and the
              next reason to get out there.
            </p>
            <div className="mt-9 flex flex-wrap items-center gap-5">
              <Link
                className="inline-flex items-center gap-2 bg-[#b35f35] px-5 py-3 text-sm font-bold text-white transition-colors hover:bg-[#19352d]"
                href="/events"
              >
                Browse public events
                <ArrowUpRight aria-hidden="true" className="size-4" />
              </Link>
              <Link
                className="text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4 transition-colors hover:text-[#b35f35]"
                href="/auth/sign-up"
              >
                Become a member
              </Link>
            </div>
          </div>

          <aside className="border-l-2 border-[#b35f35] pl-6 text-[#40574e]">
            <CalendarDays aria-hidden="true" className="size-7 text-[#b35f35]" />
            <p className="mt-5 text-2xl font-semibold leading-tight text-[#19352d]">
              The next outing is waiting on the calendar.
            </p>
            <p className="mt-4 text-sm leading-6">
              See published dates, times, activity types, and difficulty at a
              glance. Member details stay inside the portal.
            </p>
          </aside>
        </div>
      </section>

      <section className="mx-auto grid w-full max-w-7xl gap-10 px-5 py-14 sm:px-8 lg:grid-cols-[0.8fr_1.2fr] lg:px-12 lg:py-20">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#557268]">
            A clear boundary
          </p>
          <h2 className="mt-3 max-w-sm text-4xl font-semibold leading-tight tracking-tight text-[#19352d]">
            Public enough to discover. Private enough to trust.
          </h2>
        </div>
        <div className="grid gap-6 border-t border-[#c9d6d0] pt-6 sm:grid-cols-2">
          <div>
            <ShieldCheck aria-hidden="true" className="size-6 text-[#b35f35]" />
            <h3 className="mt-4 text-lg font-semibold text-[#19352d]">
              Member-first details
            </h3>
            <p className="mt-2 text-sm leading-6 text-[#71847b]">
              Exact locations, event notes, attendee information, and media
              remain protected for eligible members.
            </p>
          </div>
          <div>
            <Mountain aria-hidden="true" className="size-6 text-[#b35f35]" />
            <h3 className="mt-4 text-lg font-semibold text-[#19352d]">
              More ways outside
            </h3>
            <p className="mt-2 text-sm leading-6 text-[#71847b]">
              Hikes, scrambles, climbing, camping, courses, and socials are all
              part of the mix.
            </p>
          </div>
        </div>
      </section>

      <footer className="border-t border-[#c9d6d0] px-5 py-8 sm:px-8 lg:px-12">
        <div className="mx-auto flex w-full max-w-7xl flex-wrap items-center justify-between gap-4 text-xs uppercase tracking-[0.12em] text-[#71847b]">
          <span>UCOA Outdoor Adventurers</span>
          <Link className="font-bold text-[#19352d] hover:text-[#b35f35]" href="/events">
            View calendar
          </Link>
        </div>
      </footer>
    </main>
  );
}
