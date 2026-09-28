import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const reviewStatuses = ["approved", "rejected", "revoked"] as const;

function errorResponse(message: string, status: number) {
  return Response.json(
    { error: message },
    {
      status,
      headers: { "Cache-Control": "private, no-store" },
    },
  );
}

export async function POST(request: Request) {
  if (!hasEnvVars) {
    return errorResponse("Signed waiver review is unavailable.", 404);
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims?.sub) {
    return errorResponse("Sign in before reviewing a signed waiver.", 401);
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return errorResponse("The signed waiver review request is invalid.", 400);
  }

  if (typeof body !== "object" || body === null) {
    return errorResponse("The signed waiver review request is invalid.", 400);
  }

  const payload = body as Record<string, unknown>;
  const signedWaiverId = payload.signedWaiverId;
  const status = payload.status;
  const confirmed = payload.confirm;

  if (
    typeof signedWaiverId !== "string"
    || !uuidPattern.test(signedWaiverId)
    || typeof status !== "string"
    || !reviewStatuses.includes(status as (typeof reviewStatuses)[number])
    || confirmed !== "yes"
  ) {
    return errorResponse("The signed waiver review request is invalid.", 400);
  }

  const { data, error } = await supabase.rpc("review_signed_waiver", {
    p_signed_waiver_id: signedWaiverId,
    p_status: status,
  });

  if (error) {
    return errorResponse(
      error.code === "42501" ? "Signed waiver review is unavailable." : "The signed waiver review could not be saved.",
      error.code === "42501" ? 403 : 400,
    );
  }

  const review = Array.isArray(data) ? data[0] : data;
  if (!review) {
    return errorResponse("The signed waiver review could not be saved.", 400);
  }

  return Response.json(
    { status: review.status },
    { headers: { "Cache-Control": "private, no-store" } },
  );
}