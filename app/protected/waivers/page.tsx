import { ExternalLink, FileCheck2, FileSignature, Mountain } from "lucide-react";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import Link from "next/link";

import { SignedWaiverUpload } from "@/components/signed-waiver-upload";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

type WaiverRecord = {
  id: string;
  version: string;
  document_reference: string;
};

type SubmissionRecord = {
  id: string;
  waiver_id: string;
  status: "submitted" | "approved" | "rejected" | "revoked";
  submitted_at: string;
};

export const metadata: Metadata = {
  title: "Waivers | UCOA Outdoor Adventurers",
  description: "Review and submit approved UCOA waiver documents.",
};

export const instant = false;

export default async function WaiversPage() {
  if (!hasEnvVars) {
    return (
      <section className="py-16">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">Waivers</p>
        <h1 className="mt-4 text-5xl font-semibold leading-[0.96] text-[#19352d]">Waivers are not connected yet.</h1>
      </section>
    );
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims?.sub) {
    redirect("/auth/login");
  }

  const userId = claims.claims.sub;
  const [{ data: waivers }, { data: submissions }] = await Promise.all([
    supabase
      .from("waivers")
      .select("id, version, document_reference")
      .eq("status", "approved")
      .eq("member_downloadable", true)
      .order("approved_at", { ascending: false }),
    supabase
      .from("signed_waivers")
      .select("id, waiver_id, status, submitted_at")
      .eq("user_id", userId)
      .order("submitted_at", { ascending: false }),
  ]);

  const submissionByWaiver = new Map<string, SubmissionRecord>();
  for (const submission of (submissions ?? []) as SubmissionRecord[]) {
    if (!submissionByWaiver.has(submission.waiver_id)) {
      submissionByWaiver.set(submission.waiver_id, submission);
    }
  }

  return (
    <section className="py-12 lg:py-16">
      <div className="flex flex-wrap items-end justify-between gap-6 border-b border-[#c9d6d0] pb-10">
        <div>
          <Link className="inline-flex items-center gap-2 text-sm font-semibold text-[#557268] hover:text-[#19352d]" href="/protected">
            <Mountain aria-hidden="true" className="size-4" />
            Member workspace
          </Link>
          <p className="mt-8 text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">Document centre</p>
          <h1 className="mt-4 max-w-3xl text-5xl font-semibold leading-[0.96] tracking-[-0.03em] text-[#19352d] sm:text-6xl">
            Approved waivers
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-7 text-[#52665d]">
            Download the approved PDF, sign it, and submit the completed copy to UCOA.
          </p>
        </div>
        <FileSignature aria-hidden="true" className="size-12 text-[#b35f35]" />
      </div>

      {waivers && waivers.length > 0 ? (
        <div className="grid gap-6 py-10 lg:grid-cols-2">
          {(waivers as WaiverRecord[]).map((waiver) => {
            const submission = submissionByWaiver.get(waiver.id) ?? null;
            return (
              <article className="border border-[#c9d6d0] bg-[#fffdf8] p-6 shadow-[4px_4px_0_#d9e3dc]" key={waiver.id}>
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">Approved version</p>
                <h2 className="mt-3 text-2xl font-semibold text-[#19352d]">{waiver.version}</h2>
                <a
                  className="mt-5 inline-flex items-center gap-2 text-sm font-bold text-[#19352d] underline decoration-[#b35f35] decoration-2 underline-offset-4"
                  href={`/api/waivers/${waiver.id}/document`}
                  rel="noreferrer"
                  target="_blank"
                >
                  Download blank PDF
                  <ExternalLink aria-hidden="true" className="size-4" />
                </a>
                <SignedWaiverUpload existingSubmission={submission} waiverId={waiver.id} />
              </article>
            );
          })}
        </div>
      ) : (
        <div className="border-y border-[#c9d6d0] py-12">
          <FileCheck2 aria-hidden="true" className="size-8 text-[#b35f35]" />
          <h2 className="mt-4 text-2xl font-semibold text-[#19352d]">No approved waiver is available.</h2>
          <p className="mt-3 max-w-xl text-sm leading-6 text-[#71847b]">
            UCOA will publish the approved document here when the executive workflow is ready.
          </p>
        </div>
      )}
    </section>
  );
}