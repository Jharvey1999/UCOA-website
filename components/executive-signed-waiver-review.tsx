"use client";

import { Check, RotateCcw, X } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";

import { Button } from "@/components/ui/button";

type ReviewStatus = "submitted" | "approved" | "rejected" | "revoked";

export type SignedWaiverReviewRecord = {
  id: string;
  status: ReviewStatus;
  submitted_at: string;
  waiver_version: string;
  first_name: string;
  last_name: string;
  email: string | null;
};

type ExecutiveSignedWaiverReviewProps = {
  submissions: SignedWaiverReviewRecord[];
};

function formatSubmittedAt(value: string) {
  const date = new Date(value);
  return Number.isNaN(date.getTime())
    ? ""
    : new Intl.DateTimeFormat("en-CA", {
        dateStyle: "medium",
        timeZone: "UTC",
      }).format(date);
}

export function ExecutiveSignedWaiverReview({ submissions }: ExecutiveSignedWaiverReviewProps) {
  const router = useRouter();
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function reviewSubmission(id: string, status: Exclude<ReviewStatus, "submitted">) {
    setBusyId(id);
    setError(null);

    try {
      const response = await fetch("/api/executive/signed-waivers/review", {
        body: JSON.stringify({
          confirm: "yes",
          signedWaiverId: id,
          status,
        }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      const payload = (await response.json()) as { error?: string };

      if (!response.ok) {
        throw new Error(payload.error ?? "The signed waiver review could not be saved.");
      }

      router.refresh();
    } catch (reviewError: unknown) {
      setError(
        reviewError instanceof Error
          ? reviewError.message
          : "The signed waiver review could not be saved.",
      );
    } finally {
      setBusyId(null);
    }
  }

  return (
    <section className="mt-8 border-t border-[#c9d6d0] pt-8">
      <div>
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">Review queue</p>
        <h2 className="mt-2 text-2xl font-semibold text-[#19352d]">Signed waiver submissions</h2>
      </div>
      {submissions.length > 0 ? (
        <div className="mt-5 divide-y divide-[#d8e2db] border-y border-[#d8e2db]">
          {submissions.map((submission) => (
            <article className="grid gap-4 py-5 lg:grid-cols-[1fr_auto] lg:items-center" key={submission.id}>
              <div>
                <p className="font-semibold text-[#19352d]">
                  {submission.first_name} {submission.last_name}
                </p>
                <p className="text-sm text-[#71847b]">
                  {submission.email ?? "No email"} | {submission.waiver_version} | submitted {formatSubmittedAt(submission.submitted_at)}
                </p>
                <p className="mt-1 text-sm font-semibold capitalize text-[#557268]">Status: {submission.status}</p>
              </div>
              <div className="flex flex-wrap gap-2">
                {submission.status === "submitted" || submission.status === "rejected" ? (
                  <Button
                    className="bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]"
                    disabled={busyId !== null}
                    onClick={() => reviewSubmission(submission.id, "approved")}
                    type="button"
                  >
                    <Check aria-hidden="true" className="size-4" />
                    Approve
                  </Button>
                ) : null}
                {submission.status === "approved" ? (
                  <Button
                    className="border border-[#b35f35] bg-transparent text-[#9a432d] hover:bg-[#f4e5dc]"
                    disabled={busyId !== null}
                    onClick={() => reviewSubmission(submission.id, "revoked")}
                    type="button"
                  >
                    <RotateCcw aria-hidden="true" className="size-4" />
                    Revoke
                  </Button>
                ) : submission.status === "submitted" ? (
                  <Button
                    className="border border-[#c9d6d0] bg-transparent text-[#557268] hover:bg-[#edf2ee]"
                    disabled={busyId !== null}
                    onClick={() => reviewSubmission(submission.id, "rejected")}
                    type="button"
                  >
                    <X aria-hidden="true" className="size-4" />
                    Reject
                  </Button>
                ) : null}
              </div>
            </article>
          ))}
        </div>
      ) : (
        <p className="mt-5 border-y border-[#d8e2db] py-5 text-sm text-[#71847b]">No signed waiver submissions are waiting for review.</p>
      )}
      {error ? (
        <p aria-live="polite" className="mt-4 text-sm leading-6 text-[#9a432d]" role="alert">
          {error}
        </p>
      ) : null}
    </section>
  );
}