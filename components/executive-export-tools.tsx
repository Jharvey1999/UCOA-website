"use client";

import { Archive, Download, FileSpreadsheet, Trash2 } from "lucide-react";
import { useState } from "react";

import {
  MEMBER_ROLES,
  MEMBERSHIP_STATUSES,
} from "@/lib/member-export";
import { Button } from "@/components/ui/button";

type WaiverOption = {
  id: string;
  version: string;
};

type ExecutiveExportToolsProps = {
  waiverOptions: WaiverOption[];
};

function buildUrl(path: string, formData: FormData, fields: string[]) {
  const params = new URLSearchParams();
  for (const field of fields) {
    const value = formData.get(field);
    if (typeof value === "string" && value) {
      params.set(field, value);
    }
  }

  const query = params.toString();
  return query ? `${path}?${query}` : path;
}

export function ExecutiveExportTools({ waiverOptions }: ExecutiveExportToolsProps) {
  const [memberExporting, setMemberExporting] = useState(false);
  const [waiverExporting, setWaiverExporting] = useState(false);
  const [cleanupRunning, setCleanupRunning] = useState(false);
  const [memberExportMessage, setMemberExportMessage] = useState<string | null>(null);
  const [cleanupMessage, setCleanupMessage] = useState<string | null>(null);

  function handleMemberExport(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMemberExporting(true);
    setMemberExportMessage(null);

    const formData = new FormData(event.currentTarget);
    void (async () => {
      try {
        const response = await fetch("/api/executive/member-export", {
          body: JSON.stringify({
            confirm: formData.get("confirm"),
            role: formData.get("role"),
            search: formData.get("search"),
            signedWaiver: formData.get("signedWaiver"),
            status: formData.get("status"),
          }),
          headers: { "Content-Type": "application/json" },
          method: "POST",
        });

        if (!response.ok) {
          throw new Error("The member export could not be generated.");
        }

        const blobUrl = URL.createObjectURL(await response.blob());
        const link = document.createElement("a");
        link.href = blobUrl;
        link.download = `ucoa-members-${new Date().toISOString().slice(0, 10)}.xlsx`;
        document.body.appendChild(link);
        link.click();
        link.remove();
        window.setTimeout(() => URL.revokeObjectURL(blobUrl), 1000);
      } catch (exportError: unknown) {
        setMemberExportMessage(
          exportError instanceof Error
            ? exportError.message
            : "The member export could not be generated.",
        );
      } finally {
        setMemberExporting(false);
      }
    })();
  }

  function handleWaiverExport(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setWaiverExporting(true);
    window.location.assign(
      buildUrl("/api/executive/signed-waivers", new FormData(event.currentTarget), [
        "waiverId",
        "status",
        "confirm",
      ]),
    );
  }

  async function handleCleanup(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setCleanupRunning(true);
    setCleanupMessage(null);

    const formData = new FormData(event.currentTarget);
    const before = formData.get("cleanupBefore");

    if (typeof before !== "string" || !before) {
      setCleanupMessage("Choose a cleanup cutoff first.");
      setCleanupRunning(false);
      return;
    }

    try {
      const response = await fetch("/api/executive/signed-waivers/cleanup", {
        body: JSON.stringify({ before: new Date(before).toISOString(), confirm: "yes" }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      const payload = (await response.json()) as { deleted?: number; error?: string };

      if (!response.ok) {
        throw new Error(payload.error ?? "The signed waiver cleanup could not be completed.");
      }

      setCleanupMessage(`${payload.deleted ?? 0} unreferenced PDF(s) removed.`);
      event.currentTarget.reset();
    } catch (cleanupError: unknown) {
      setCleanupMessage(
        cleanupError instanceof Error
          ? cleanupError.message
          : "The signed waiver cleanup could not be completed.",
      );
    } finally {
      setCleanupRunning(false);
    }
  }

  return (
    <div className="grid gap-8 lg:grid-cols-2">
      <section className="border border-[#c9d6d0] bg-[#fffdf8] p-6 shadow-[4px_4px_0_#d9e3dc]">
        <div className="flex items-start gap-3">
          <FileSpreadsheet aria-hidden="true" className="mt-1 size-6 text-[#b35f35]" />
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
              Member directory
            </p>
            <h2 className="mt-2 text-2xl font-semibold text-[#19352d]">Export an Excel workbook</h2>
          </div>
        </div>
        <form className="mt-6 space-y-5" onSubmit={handleMemberExport}>
          <div className="grid gap-5 sm:grid-cols-2">
            <label className="grid gap-2 text-sm font-semibold text-[#40574e]" htmlFor="member-export-status">
              Status
              <select className="h-10 border border-[#c9d6d0] bg-[#f8f6f0] px-3 font-normal" defaultValue="" id="member-export-status" name="status">
                <option value="">All accounts</option>
                {MEMBERSHIP_STATUSES.map((status) => (
                  <option key={status} value={status}>{status.replaceAll("_", " ")}</option>
                ))}
              </select>
            </label>
            <label className="grid gap-2 text-sm font-semibold text-[#40574e]" htmlFor="member-export-role">
              Role
              <select className="h-10 border border-[#c9d6d0] bg-[#f8f6f0] px-3 font-normal" defaultValue="" id="member-export-role" name="role">
                <option value="">All roles</option>
                {MEMBER_ROLES.map((role) => (
                  <option key={role} value={role}>{role}</option>
                ))}
              </select>
            </label>
          </div>
          <div className="grid gap-5 sm:grid-cols-2">
            <label className="grid gap-2 text-sm font-semibold text-[#40574e]" htmlFor="member-export-search">
              Search
              <input className="h-10 border border-[#c9d6d0] bg-[#f8f6f0] px-3 font-normal" id="member-export-search" maxLength={100} name="search" placeholder="Name, email, or student ID" type="search" />
            </label>
            <label className="grid gap-2 text-sm font-semibold text-[#40574e]" htmlFor="member-export-waiver">
              Blanket waiver
              <select className="h-10 border border-[#c9d6d0] bg-[#f8f6f0] px-3 font-normal" defaultValue="" id="member-export-waiver" name="signedWaiver">
                <option value="">All waiver states</option>
                <option value="yes">Signed waiver on file</option>
                <option value="no">No signed waiver on file</option>
              </select>
            </label>
          </div>
          <label className="flex items-start gap-3 text-sm leading-6 text-[#40574e]">
            <input className="mt-1 size-4 accent-[#19352d]" required name="confirm" type="checkbox" value="yes" />
            <span>I confirm this export is for approved UCOA executive operations.</span>
          </label>
          <Button className="bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]" disabled={memberExporting} type="submit">
            <Download aria-hidden="true" className="size-4" />
            {memberExporting ? "Preparing workbook..." : "Download member Excel"}
          </Button>
          {memberExportMessage ? <p aria-live="polite" className="text-sm text-[#9a432d]" role="alert">{memberExportMessage}</p> : null}
        </form>
      </section>

      <section className="border border-[#c9d6d0] bg-[#fffdf8] p-6 shadow-[4px_4px_0_#d9e3dc]">
        <div className="flex items-start gap-3">
          <Archive aria-hidden="true" className="mt-1 size-6 text-[#b35f35]" />
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">
              Signed waivers
            </p>
            <h2 className="mt-2 text-2xl font-semibold text-[#19352d]">Download PDFs as a ZIP</h2>
          </div>
        </div>
        <form className="mt-6 space-y-5" onSubmit={handleWaiverExport}>
          <label className="grid gap-2 text-sm font-semibold text-[#40574e]" htmlFor="signed-waiver-version">
            Waiver version
            <select className="h-10 border border-[#c9d6d0] bg-[#f8f6f0] px-3 font-normal" defaultValue="" id="signed-waiver-version" name="waiverId">
              <option value="">All waiver versions</option>
              {waiverOptions.map((waiver) => (
                <option key={waiver.id} value={waiver.id}>{waiver.version}</option>
              ))}
            </select>
          </label>
          <label className="grid gap-2 text-sm font-semibold text-[#40574e]" htmlFor="signed-waiver-status">
            Submission status
            <select className="h-10 border border-[#c9d6d0] bg-[#f8f6f0] px-3 font-normal" defaultValue="submitted" id="signed-waiver-status" name="status">
              <option value="submitted">Submitted</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
              <option value="revoked">Revoked</option>
              <option value="">All statuses</option>
            </select>
          </label>
          <label className="flex items-start gap-3 text-sm leading-6 text-[#40574e]">
            <input className="mt-1 size-4 accent-[#19352d]" required name="confirm" type="checkbox" value="yes" />
            <span>I confirm this download is for approved UCOA waiver administration.</span>
          </label>
          <Button className="bg-[#19352d] text-[#f3f0e8] hover:bg-[#b35f35]" disabled={waiverExporting} type="submit">
            <Download aria-hidden="true" className="size-4" />
            {waiverExporting ? "Preparing ZIP..." : "Download signed waivers"}
          </Button>
        </form>
        <div className="mt-8 border-t border-[#d8e2db] pt-6">
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#557268]">Storage cleanup</p>
          <p className="mt-2 text-sm leading-6 text-[#71847b]">Remove unreferenced route-created PDFs older than an approved cutoff.</p>
          <form className="mt-4 space-y-4" onSubmit={handleCleanup}>
            <label className="grid gap-2 text-sm font-semibold text-[#40574e]" htmlFor="signed-waiver-cleanup-before">
              Cutoff
              <input className="h-10 border border-[#c9d6d0] bg-[#f8f6f0] px-3 font-normal" id="signed-waiver-cleanup-before" name="cleanupBefore" required type="datetime-local" />
            </label>
            <label className="flex items-start gap-3 text-sm leading-6 text-[#40574e]">
              <input className="mt-1 size-4 accent-[#19352d]" required type="checkbox" />
              <span>I confirm these unreferenced PDFs are past the approved retention cutoff.</span>
            </label>
            <Button className="border border-[#b35f35] bg-transparent text-[#9a432d] hover:bg-[#f4e5dc]" disabled={cleanupRunning} type="submit">
              <Trash2 aria-hidden="true" className="size-4" />
              {cleanupRunning ? "Cleaning up PDFs..." : "Clean up old PDFs"}
            </Button>
          </form>
          {cleanupMessage ? <p aria-live="polite" className="mt-3 text-sm text-[#557268]">{cleanupMessage}</p> : null}
        </div>
      </section>
    </div>
  );
}