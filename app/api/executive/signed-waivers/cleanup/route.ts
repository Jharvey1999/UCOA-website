import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

const MAX_CLEANUP_FILES = 100;

function response(message: string, status: number) {
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
    return response("Signed waiver cleanup is unavailable.", 404);
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();
  const actorId = claims?.claims?.sub;

  if (claimsError || !actorId) {
    return response("Sign in before cleaning up signed waivers.", 401);
  }

  let payload: { before?: unknown; confirm?: unknown };
  try {
    payload = (await request.json()) as { before?: unknown; confirm?: unknown };
  } catch {
    return response("Confirm the cleanup cutoff before continuing.", 400);
  }

  if (payload.confirm !== "yes" || typeof payload.before !== "string") {
    return response("Confirm the cleanup cutoff before continuing.", 400);
  }

  const cutoff = new Date(payload.before);
  if (Number.isNaN(cutoff.getTime()) || cutoff > new Date()) {
    return response("Choose a past cleanup cutoff.", 400);
  }

  const { data, error: listError } = await supabase.rpc("list_signed_waiver_orphans", {
    p_before: cutoff.toISOString(),
    p_limit: MAX_CLEANUP_FILES,
  });

  if (listError) {
    return response(listError.code === "42501" ? "Signed waiver cleanup unavailable." : "The cleanup list could not be loaded.", listError.code === "42501" ? 403 : 400);
  }

  const orphanRows = (data ?? []) as Array<{ object_path: string }>;
  if (orphanRows.length === 0) {
    return Response.json(
      { deleted: 0 },
      {
        headers: {
          "Cache-Control": "private, no-store",
        },
      },
    );
  }

  const adminClient = createAdminClient();
  if (!adminClient) {
    return response("Signed waiver cleanup is unavailable.", 503);
  }

  const deletedPaths: string[] = [];
  let cleanupError = false;
  for (const row of orphanRows) {
    const { data: claimed, error: claimError } = await supabase.rpc("claim_signed_waiver_orphan", {
      p_before: cutoff.toISOString(),
      p_object_path: row.object_path,
    });

    if (claimError) {
      cleanupError = true;
      break;
    }

    if (!claimed) {
      continue;
    }

    const { error: deleteError } = await adminClient.storage
      .from("signed-waivers")
      .remove([row.object_path]);

    if (deleteError) {
      const lastSeparator = row.object_path.lastIndexOf("/");
      const parentPath = row.object_path.slice(0, lastSeparator);
      const objectName = row.object_path.slice(lastSeparator + 1);
      const { data: remainingObjects, error: verificationError } = await adminClient.storage
        .from("signed-waivers")
        .list(parentPath, { search: objectName, limit: 100 });

      if (
        verificationError
        || !remainingObjects
        || remainingObjects.some((object) => object.name === objectName)
      ) {
        cleanupError = true;
        break;
      }
    }

    deletedPaths.push(row.object_path);
  }

  if (deletedPaths.length > 0) {
    const { error: auditError } = await adminClient.rpc("audit_signed_waiver_cleanup", {
      p_actor_id: actorId,
      p_object_paths: deletedPaths,
      p_before: cutoff.toISOString(),
    });

    if (auditError) {
      return response("The cleanup completed but could not be audited. Retry after one hour to reconcile it.", 500);
    }
  }

  if (cleanupError) {
    return response("Some signed waiver objects could not be cleaned up.", 502);
  }

  return Response.json(
    { deleted: deletedPaths.length },
    {
      headers: {
        "Cache-Control": "private, no-store",
      },
    },
  );
}