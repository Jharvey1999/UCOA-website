import JSZip from "jszip";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const signedWaiverStatuses = ["submitted", "approved", "rejected", "revoked"] as const;
const MAX_SIGNED_WAIVER_EXPORT_FILES = 50;
const MAX_SIGNED_WAIVER_EXPORT_BYTES = 50 * 1024 * 1024;

type SignedWaiverExportRow = {
  id: string;
  waiver_id: string;
  user_id: string;
  object_path: string;
  status: string;
  submitted_at: string;
  waiver_version: string;
  first_name: string;
  last_name: string;
  email: string | null;
};

function unavailableResponse(status = 404) {
  return new Response("Signed waiver export unavailable", {
    status,
    headers: {
      "Cache-Control": "private, no-store",
      "Content-Type": "text/plain; charset=utf-8",
    },
  });
}

function safeFilePart(value: string, fallback: string) {
  const normalized = value
    .normalize("NFKD")
    .replace(/[^A-Za-z0-9._-]+/g, "_")
    .replace(/^\.+|\.+$/g, "")
    .slice(0, 80);
  return normalized || fallback;
}

export async function GET(request: Request) {
  if (!hasEnvVars) {
    return unavailableResponse();
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims?.sub) {
    return unavailableResponse(401);
  }

  const searchParams = new URL(request.url).searchParams;
  const waiverId = searchParams.get("waiverId");
  const status = searchParams.get("status");
  const confirmed = searchParams.get("confirm");

  if (
    (waiverId !== null && !uuidPattern.test(waiverId))
    || (status !== null && !signedWaiverStatuses.includes(status as (typeof signedWaiverStatuses)[number]))
    || confirmed !== "yes"
  ) {
    return unavailableResponse(400);
  }

  const { data, error } = await supabase.rpc("list_signed_waiver_exports", {
    p_waiver_id: waiverId,
    p_status: status,
  });

  if (error) {
    return unavailableResponse(error.code === "42501" ? 403 : 400);
  }

  const rows = (data ?? []) as SignedWaiverExportRow[];
  if (rows.length === 0) {
    return unavailableResponse(404);
  }
  if (rows.length > MAX_SIGNED_WAIVER_EXPORT_FILES) {
    return unavailableResponse(413);
  }

  const adminClient = createAdminClient();
  if (!adminClient) {
    return unavailableResponse(503);
  }

  const archive = new JSZip();
  let totalBytes = 0;
  for (const row of rows) {
    const { data: file, error: downloadError } = await adminClient.storage
      .from("signed-waivers")
      .download(row.object_path);

    if (downloadError || !file) {
      return unavailableResponse(502);
    }
    totalBytes += file.size;
    if (totalBytes > MAX_SIGNED_WAIVER_EXPORT_BYTES) {
      return unavailableResponse(413);
    }

    const memberName = safeFilePart(
      `${row.first_name} ${row.last_name}`.trim(),
      safeFilePart(row.user_id, "member"),
    );
    const waiverVersion = safeFilePart(row.waiver_version, "waiver");
    archive.file(
      `${waiverVersion}/${memberName}-${row.id.slice(0, 8)}.pdf`,
      await file.arrayBuffer(),
    );
  }

  const archiveBytes = await archive.generateAsync({
    compression: "DEFLATE",
    type: "uint8array",
  });
  const { error: auditError } = await adminClient.rpc("audit_signed_waiver_export", {
    p_actor_id: claims.claims.sub,
    p_signed_waiver_ids: rows.map((row) => row.id),
    p_waiver_id: waiverId,
    p_status: status,
  });
  if (auditError) {
    return unavailableResponse(500);
  }

  const archiveBuffer = new ArrayBuffer(archiveBytes.byteLength);
  new Uint8Array(archiveBuffer).set(archiveBytes);

  return new Response(archiveBuffer, {
    headers: {
      "Cache-Control": "private, no-store",
      "Content-Disposition": `attachment; filename="ucoa-signed-waivers-${new Date().toISOString().slice(0, 10)}.zip"`,
      "Content-Type": "application/zip",
    },
  });
}