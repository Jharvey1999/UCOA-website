import { randomUUID } from "node:crypto";
import { PDFDocument } from "pdf-lib";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

const MAX_FILE_SIZE = 10 * 1024 * 1024;
const MAX_MULTIPART_REQUEST_SIZE = MAX_FILE_SIZE + 1024 * 1024;
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function readBoundedBody(request: Request, maxBytes: number): Promise<ArrayBuffer | null> {
  const reader = request.body?.getReader();
  if (!reader) {
    return new ArrayBuffer(0);
  }

  const chunks: Uint8Array[] = [];
  let totalBytes = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }

      totalBytes += value.byteLength;
      if (totalBytes > maxBytes) {
        await reader.cancel().catch(() => undefined);
        return null;
      }

      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  const body = new ArrayBuffer(totalBytes);
  const bodyBytes = new Uint8Array(body);
  let offset = 0;
  for (const chunk of chunks) {
    bodyBytes.set(chunk, offset);
    offset += chunk.byteLength;
  }

  return body;
}

function errorResponse(message: string, status: number) {
  return Response.json(
    { error: message },
    {
      status,
      headers: {
        "Cache-Control": "private, no-store",
      },
    },
  );
}

export async function POST(request: Request) {
  if (!hasEnvVars) {
    return errorResponse("Waiver uploads are unavailable.", 404);
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;

  if (claimsError || !userId) {
    return errorResponse("Sign in before uploading a signed waiver.", 401);
  }

  const { data: canSubmit, error: membershipError } = await supabase.rpc(
    "can_current_user_submit_signed_waiver",
  );
  if (membershipError || !canSubmit) {
    return errorResponse("An active membership is required to upload a signed waiver.", 403);
  }

  const contentLength = request.headers.get("content-length");
  if (
    contentLength !== null
    && Number.isFinite(Number(contentLength))
    && Number(contentLength) > MAX_MULTIPART_REQUEST_SIZE
  ) {
    return errorResponse("Signed waivers must be valid PDF files up to 10 MB.", 413);
  }

  const adminClient = createAdminClient();
  if (!adminClient) {
    return errorResponse("Waiver uploads are unavailable.", 503);
  }

  let requestBody: ArrayBuffer | null;
  try {
    requestBody = await readBoundedBody(request, MAX_MULTIPART_REQUEST_SIZE);
  } catch {
    return errorResponse("Choose a PDF file to upload.", 400);
  }

  if (requestBody === null) {
    return errorResponse("Signed waivers must be valid PDF files up to 10 MB.", 413);
  }

  let formData: FormData;
  try {
    const headers = new Headers();
    const contentType = request.headers.get("content-type");
    if (contentType) {
      headers.set("content-type", contentType);
    }
    const boundedRequest = new Request(request.url, {
      method: request.method,
      headers,
      body: requestBody,
    });
    formData = await boundedRequest.formData();
  } catch {
    return errorResponse("Choose a PDF file to upload.", 400);
  }

  const waiverId = formData.get("waiverId");
  const file = formData.get("file");

  if (typeof waiverId !== "string" || !uuidPattern.test(waiverId)) {
    return errorResponse("The selected waiver is unavailable.", 400);
  }

  if (!(file instanceof File)) {
    return errorResponse("Choose a PDF file to upload.", 400);
  }

  const headerBytes = new Uint8Array(await file.slice(0, 5).arrayBuffer());
  const isPdf =
    headerBytes.length === 5
    && headerBytes[0] === 0x25
    && headerBytes[1] === 0x50
    && headerBytes[2] === 0x44
    && headerBytes[3] === 0x46
    && headerBytes[4] === 0x2d;

  if (file.size < 5 || file.size > MAX_FILE_SIZE || file.type !== "application/pdf" || !isPdf) {
    return errorResponse("Signed waivers must be valid PDF files up to 10 MB.", 400);
  }

  try {
    await PDFDocument.load(await file.arrayBuffer(), {
      ignoreEncryption: false,
      throwOnInvalidObject: true,
    });
  } catch {
    return errorResponse("Signed waivers must be valid PDF files up to 10 MB.", 400);
  }

  const { data: waiver, error: waiverError } = await supabase
    .from("waivers")
    .select("id")
    .eq("id", waiverId)
    .eq("status", "approved")
    .eq("member_downloadable", true)
    .maybeSingle();

  if (waiverError || !waiver) {
    return errorResponse("The selected waiver is unavailable.", 404);
  }

  const objectPath = `signed-waivers/${userId}/${waiver.id}/${randomUUID()}.pdf`;
  const { error: uploadError } = await adminClient.storage
    .from("signed-waivers")
    .upload(objectPath, file, {
      contentType: "application/pdf",
      metadata: { ucoa_user_id: userId },
      upsert: false,
    });

  if (uploadError) {
    return errorResponse("The signed waiver could not be uploaded.", 400);
  }

  const { data: submission, error: submissionError } = await supabase.rpc(
    "submit_signed_waiver",
    {
      p_waiver_id: waiver.id,
      p_object_path: objectPath,
    },
  );

  if (submissionError) {
    const { error: compensationError } = await adminClient.storage
      .from("signed-waivers")
      .remove([objectPath]);

    if (compensationError) {
      const { error: auditError } = await adminClient.rpc(
        "audit_signed_waiver_upload_compensation_failure",
        {
          p_actor_id: userId,
          p_waiver_id: waiver.id,
          p_object_path: objectPath,
        },
      );

      if (auditError) {
        return errorResponse("The signed waiver could not be recorded or safely cleaned up.", 500);
      }

      return errorResponse("Cleanup was logged for follow-up. The signed waiver was not recorded.", 500);
    }

    return errorResponse("The signed waiver could not be recorded.", 400);
  }

  const submissionRecord = Array.isArray(submission) ? submission[0] : submission;
  const previousObjectPath =
    submissionRecord && typeof submissionRecord.previous_object_path === "string"
      ? submissionRecord.previous_object_path
      : null;
  let previousObjectCleanupPending = false;

  if (previousObjectPath && previousObjectPath !== objectPath) {
    const { error: previousObjectCleanupError } = await adminClient.storage
      .from("signed-waivers")
      .remove([previousObjectPath]);

    if (previousObjectCleanupError) {
      previousObjectCleanupPending = true;
      const { error: auditError } = await adminClient.rpc(
        "audit_signed_waiver_replacement_cleanup_failure",
        {
          p_actor_id: userId,
          p_waiver_id: waiver.id,
          p_object_path: previousObjectPath,
        },
      );

      if (auditError) {
        console.error("Failed to audit signed waiver replacement cleanup", {
          auditError,
          objectPath: previousObjectPath,
          userId,
          waiverId: waiver.id,
        });
      }
    }
  }

  return Response.json(
    { previousObjectCleanupPending, status: "submitted" },
    {
      headers: {
        "Cache-Control": "private, no-store",
      },
    },
  );
}