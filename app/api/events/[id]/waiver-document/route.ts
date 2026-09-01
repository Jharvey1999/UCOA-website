import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

const eventIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const waiverDocumentPathPattern =
  /^waivers\/[0-9]{4}-[0-9]{4}\/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$/;

type WaiverStatusRecord = {
  document_reference?: string | null;
};

function unavailableResponse() {
  return new Response(null, {
    status: 404,
    headers: {
      "Cache-Control": "private, no-store",
    },
  });
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;

  if (!hasEnvVars || !eventIdPattern.test(id)) {
    return unavailableResponse();
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims?.sub) {
    return unavailableResponse();
  }

  const { data, error } = await supabase.rpc("get_event_waiver_status", {
    p_event_id: id,
  });
  const statusRecord = (Array.isArray(data) ? data[0] : data) as
    | WaiverStatusRecord
    | undefined;
  const documentReference = statusRecord?.document_reference;

  if (
    error ||
    typeof documentReference !== "string" ||
    !waiverDocumentPathPattern.test(documentReference)
  ) {
    return unavailableResponse();
  }

  const { data: signedUrl, error: signedUrlError } = await supabase.storage
    .from("waiver-documents")
    .createSignedUrl(documentReference, 300);

  if (signedUrlError || !signedUrl?.signedUrl) {
    return unavailableResponse();
  }

  return new Response(null, {
    status: 302,
    headers: {
      "Cache-Control": "private, no-store",
      Location: signedUrl.signedUrl,
    },
  });
}