import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const waiverDocumentPathPattern =
  /^waivers\/[0-9]{4}-[0-9]{4}\/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$/;

function unavailableResponse(status = 404) {
  return new Response(null, {
    status,
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

  if (!hasEnvVars || !uuidPattern.test(id)) {
    return unavailableResponse();
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims?.sub) {
    return unavailableResponse(401);
  }

  const { data: waiver, error } = await supabase
    .from("waivers")
    .select("document_reference")
    .eq("id", id)
    .eq("status", "approved")
    .eq("member_downloadable", true)
    .maybeSingle();

  const documentReference = waiver?.document_reference;
  if (
    error
    || typeof documentReference !== "string"
    || !waiverDocumentPathPattern.test(documentReference)
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