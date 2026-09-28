import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { hasEnvVars } from "@/lib/utils";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const signedWaiverPathPattern =
  /^signed-waivers\/[0-9a-f-]{36}\/[0-9a-f-]{36}\/[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.pdf$/i;

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

  const { data: submission, error } = await supabase
    .from("signed_waivers")
    .select("object_path,status")
    .eq("id", id)
    .maybeSingle();
  const objectPath = submission?.object_path;

  if (
    error
    || typeof objectPath !== "string"
    || typeof submission?.status !== "string"
    || !signedWaiverPathPattern.test(objectPath)
  ) {
    return unavailableResponse();
  }

  const { data: executiveRole, error: executiveRoleError } = await supabase
    .from("user_roles")
    .select("role")
    .eq("user_id", claims.claims.sub)
    .eq("role", "executive")
    .maybeSingle();

  if (executiveRoleError) {
    return unavailableResponse(503);
  }

  const adminClient = createAdminClient();
  if (!adminClient) {
    return unavailableResponse(503);
  }

  const { data: signedUrl, error: signedUrlError } = await adminClient.storage
    .from("signed-waivers")
    .createSignedUrl(objectPath, 300);

  if (signedUrlError || !signedUrl?.signedUrl) {
    return unavailableResponse();
  }

  if (executiveRole?.role === "executive") {
    const { error: auditError } = await adminClient.rpc("audit_signed_waiver_export", {
      p_actor_id: claims.claims.sub,
      p_signed_waiver_ids: [id],
      p_waiver_id: null,
      p_status: submission.status,
    });

    if (auditError) {
      return unavailableResponse(500);
    }
  }

  return new Response(null, {
    status: 302,
    headers: {
      "Cache-Control": "private, no-store",
      Location: signedUrl.signedUrl,
    },
  });
}