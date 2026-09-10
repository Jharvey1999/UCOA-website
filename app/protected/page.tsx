import { CalendarDays, CheckCircle2, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

export const instant = false;

type ProfileRecord = {
  first_name: string;
  last_name_initial: string | null;
  display_name: string | null;
};

type MembershipRecord = {
  status: string;
  membership_year_start: string | null;
  membership_year_end: string | null;
};

type DashboardData = {
  unavailable: boolean;
  signedIn: boolean;
  email: string | null;
  profile: ProfileRecord | null;
  membership: MembershipRecord | null;
};

function formatDate(value: string | null) {
  if (!value) {
    return null;
  }

  return new Intl.DateTimeFormat("en-CA", {
    day: "numeric",
    month: "short",
    timeZone: "UTC",
    year: "numeric",
  }).format(new Date(`${value}T12:00:00Z`));
}

function formatStatus(value: string | undefined) {
  if (!value) {
    return "Not submitted";
  }

  return value.replaceAll("_", " ");
}

async function loadDashboard(): Promise<DashboardData> {
  if (!hasEnvVars) {
    return {
      unavailable: true,
      signedIn: false,
      email: null,
      profile: null,
      membership: null,
    };
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims) {
    return {
      unavailable: false,
      signedIn: false,
      email: null,
      profile: null,
      membership: null,
    };
  }

  const userId = claims.claims.sub;
  const [{ data: profile }, { data: membership }] = await Promise.all([
    supabase
      .from("profiles")
      .select("first_name, last_name_initial, display_name")
      .eq("id", userId)
      .maybeSingle(),
    supabase
      .from("memberships")
      .select("status, membership_year_start, membership_year_end")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);

  return {
    unavailable: false,
    signedIn: true,
    email: typeof claims.claims.email === "string" ? claims.claims.email : null,
    profile: (profile ?? null) as ProfileRecord | null,
    membership: (membership ?? null) as MembershipRecord | null,
  };
}

function UnavailableState() {
  return (
    <section className="flex min-h-[60vh] flex-col justify-center py-16">
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
        Member portal
      </p>
      <h1 className="mt-4 max-w-2xl text-5xl font-semibold leading-[0.96] tracking-[-0.03em]">
        The member workspace is not connected yet.
      </h1>
      <p className="mt-5 max-w-xl text-base leading-7 text-[#71847b]">
        Configure the Supabase environment to load account and membership data.
      </p>
    </section>
  );
}

export default async function ProtectedPage() {
  const dashboard = await loadDashboard();

  if (dashboard.unavailable) {
    return <UnavailableState />;
  }

  if (!dashboard.signedIn) {
    redirect("/auth/login");
  }

  const displayName = dashboard.profile?.display_name ?? dashboard.profile?.first_name ?? "Member";
  const membershipStatus = formatStatus(dashboard.membership?.status);
  const membershipStart = formatDate(dashboard.membership?.membership_year_start ?? null);
  const membershipEnd = formatDate(dashboard.membership?.membership_year_end ?? null);
  const isActive = dashboard.membership?.status === "active";

  return (
    <section className="py-12 lg:py-16">
      <div className="grid gap-10 border-b border-[#c9d6d0] pb-12 lg:grid-cols-[1.2fr_0.8fr] lg:items-end">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">
            Member workspace
          </p>
          <h1 className="mt-4 max-w-3xl text-5xl font-semibold leading-[0.96] tracking-[-0.03em] sm:text-6xl">
            Welcome back, {displayName}.
          </h1>
          <p className="mt-6 max-w-xl text-base leading-7 text-[#52665d]">
            Your UCOA account is connected to the member portal. Browse the calendar to find your next outing.
          </p>
          <Link
            className="mt-7 inline-flex items-center gap-2 bg-[#19352d] px-4 py-3 text-sm font-bold text-[#f3f0e8] transition-colors hover:bg-[#b35f35]"
            href="/events"
          >
            <CalendarDays aria-hidden="true" className="size-4" />
            Browse events
          </Link>
        </div>
        <div className="border-l-2 border-[#b35f35] pl-5 text-[#40574e]">
          <ShieldCheck aria-hidden="true" className="size-7 text-[#b35f35]" />
          <p className="mt-4 text-2xl font-semibold leading-tight text-[#19352d]">
            Member details stay inside the portal.
          </p>
          <p className="mt-3 text-sm leading-6 text-[#71847b]">
            Exact locations and event notes are available only when your membership allows access.
          </p>
        </div>
      </div>

      <div className="grid gap-6 py-10 md:grid-cols-2">
        <article className="border border-[#c9d6d0] bg-[#fffdf8] p-6 shadow-[4px_4px_0_#d9e3dc]">
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
            Membership
          </p>
          <div className="mt-4 flex items-center gap-3">
            <CheckCircle2 aria-hidden="true" className={isActive ? "size-6 text-[#b35f35]" : "size-6 text-[#71847b]"} />
            <p className="text-2xl font-semibold capitalize text-[#19352d]">{membershipStatus}</p>
          </div>
          {membershipStart && membershipEnd ? (
            <p className="mt-3 text-sm leading-6 text-[#71847b]">
              Membership year: {membershipStart} to {membershipEnd}
            </p>
          ) : (
            <p className="mt-3 text-sm leading-6 text-[#71847b]">
              Your membership record is waiting for executive review.
            </p>
          )}
        </article>

        <article className="border border-[#c9d6d0] bg-[#fffdf8] p-6 shadow-[4px_4px_0_#d9e3dc]">
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
            Account
          </p>
          <p className="mt-4 break-words text-xl font-semibold text-[#19352d]">
            {dashboard.email ?? "Authenticated UCOA account"}
          </p>
          <p className="mt-3 text-sm leading-6 text-[#71847b]">
            Keep this address current so UCOA can reach you about your account.
          </p>
        </article>
      </div>

      <div className="border-t border-[#c9d6d0] pt-8">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#557268]">
          Next step
        </p>
        <h2 className="mt-3 text-3xl font-semibold tracking-tight text-[#19352d]">
          Find a good day outside.
        </h2>
        <p className="mt-3 max-w-xl text-sm leading-6 text-[#71847b]">
          Public summaries are open to everyone. Sign in as an active member to see protected event details and use RSVP when a waiver workflow is available.
        </p>
      </div>
    </section>
  );
}
