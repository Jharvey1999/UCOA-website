"use client";

import { CheckCircle2, FileUp } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";

import { Button } from "@/components/ui/button";

type ExistingSubmission = {
  id: string;
  status: "submitted" | "approved" | "rejected" | "revoked";
  submitted_at: string;
} | null;

type SignedWaiverUploadProps = {
  waiverId: string;
  existingSubmission: ExistingSubmission;
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

export function SignedWaiverUpload({
  existingSubmission,
  waiverId,
}: SignedWaiverUploadProps) {
  const router = useRouter();
  const [file, setFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!file) {
      setError("Choose the signed PDF first.");
      return;
    }

    setIsUploading(true);
    setMessage(null);
    setError(null);

    const formData = new FormData();
    formData.set("waiverId", waiverId);
    formData.set("file", file);

    try {
      const response = await fetch("/api/waivers/upload", {
        body: formData,
        method: "POST",
      });
      const payload = (await response.json()) as {
        error?: string;
        previousObjectCleanupPending?: boolean;
      };

      if (!response.ok) {
        throw new Error(payload.error ?? "The signed waiver could not be uploaded.");
      }

      setFile(null);
      setMessage(
        payload.previousObjectCleanupPending
          ? "Signed waiver submitted. The previous copy needs cleanup."
          : "Signed waiver submitted.",
      );
      router.refresh();
    } catch (uploadError: unknown) {
      setError(
        uploadError instanceof Error
          ? uploadError.message
          : "The signed waiver could not be uploaded.",
      );
    } finally {
      setIsUploading(false);
    }
  }

  return (
    <div className="mt-6 border-t border-[#d8e2db] pt-5">
      {existingSubmission ? (
        <div className="flex items-start gap-3 text-sm leading-6 text-[#40574e]">
          <CheckCircle2 aria-hidden="true" className="mt-1 size-4 shrink-0 text-[#b35f35]" />
          <div>
            <p className="font-semibold capitalize text-[#19352d]">
              {existingSubmission.status} waiver on file
            </p>
            <p>Submitted {formatSubmittedAt(existingSubmission.submitted_at)}.</p>
            <a
              className="mt-1 inline-block font-semibold text-[#19352d] underline decoration-[#b35f35] underline-offset-4"
              href={`/api/waivers/signed/${existingSubmission.id}/document`}
              rel="noreferrer"
              target="_blank"
            >
              Download your submitted copy
            </a>
          </div>
        </div>
      ) : null}

      <form className="mt-5" onSubmit={handleSubmit}>
        <label className="block text-sm font-semibold text-[#40574e]" htmlFor={`waiver-file-${waiverId}`}>
          Signed PDF
        </label>
        <input
          accept="application/pdf,.pdf"
          className="mt-2 block w-full text-sm text-[#557268] file:mr-3 file:border-0 file:bg-[#19352d] file:px-3 file:py-2 file:font-semibold file:text-[#f3f0e8] hover:file:bg-[#b35f35]"
          id={`waiver-file-${waiverId}`}
          onChange={(event) => setFile(event.target.files?.[0] ?? null)}
          type="file"
        />
        <Button
          className="mt-4 bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]"
          disabled={isUploading}
          type="submit"
        >
          <FileUp aria-hidden="true" className="size-4" />
          {isUploading ? "Uploading..." : existingSubmission ? "Replace signed waiver" : "Upload signed waiver"}
        </Button>
      </form>

      {error ? (
        <p aria-live="polite" className="mt-4 text-sm leading-6 text-[#9a432d]" role="alert">
          {error}
        </p>
      ) : message ? (
        <p aria-live="polite" className="mt-4 text-sm leading-6 text-[#557268]" role="status">
          {message}
        </p>
      ) : null}
    </div>
  );
}