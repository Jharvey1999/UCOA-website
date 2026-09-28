import { Download, ShieldCheck } from "lucide-react";
import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { ExecutiveExportTools } from "@/components/executive-export-tools";
import {
  ExecutiveSignedWaiverReview,
  type SignedWaiverReviewRecord,
} from "@/components/executive-signed-waiver-review";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

type WaiverOption = {
  id: string;
  version: string;
};

export const metadata: Metadata = {
  title: "Executive exports | UCOA Outdoor Adventurers",
  description: "Executive-only member and signed-waiver exports.",
};

export const instant = false;

export default async function ExecutivePage() {
  if (!hasEnvVars) {
    return (
      <section className="py-16">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">Executive workspace</p>
        <h1 className="mt-4 text-5xl font-semibold leading-[0.96] text-[#19352d]">Exports are not connected yet.</h1>
      </section>
    );
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims?.sub) {
    redirect("/auth/login");
  }

  const { data: executiveRole } = await supabase
    .from("user_roles")
    .select("role")
    .eq("user_id", claims.claims.sub)
    .eq("role", "executive")
    .maybeSingle();

  if (!executiveRole) {
    redirect("/protected");
  }

  const { data: waiverData } = await supabase
    .from("waivers")
    .select("id, version")
    .order("created_at", { ascending: false });
  const { data: signedWaiverData } = await supabase.rpc("list_signed_waiver_exports", {
    p_status: null,
    p_waiver_id: null,
  });

  return (
    <section className="py-12 lg:py-16">
      <div className="border-b border-[#c9d6d0] pb-10">
        <div className="flex items-start gap-4">
          <ShieldCheck aria-hidden="true" className="mt-1 size-8 text-[#b35f35]" />
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#b35f35]">Executive workspace</p>
            <h1 className="mt-4 max-w-4xl text-5xl font-semibold leading-[0.96] tracking-[-0.03em] text-[#19352d] sm:text-6xl">
              Operational exports
            </h1>
            <p className="mt-5 max-w-2xl text-base leading-7 text-[#52665d]">
              Export a filtered Supabase snapshot for manual transfer to the Google Drive member master, or download signed waiver PDFs separately.
            </p>
          </div>
        </div>
      </div>
      <div className="py-10">
        <ExecutiveExportTools waiverOptions={(waiverData ?? []) as WaiverOption[]} />
        <ExecutiveSignedWaiverReview submissions={(signedWaiverData ?? []) as SignedWaiverReviewRecord[]} />
      </div>
      <div className="flex items-center gap-2 border-t border-[#c9d6d0] pt-6 text-sm text-[#71847b]">
        <Download aria-hidden="true" className="size-4 text-[#b35f35]" />
        <span>Exports are generated on demand and are not stored in the website.</span>
      </div>
    </section>
  );
}