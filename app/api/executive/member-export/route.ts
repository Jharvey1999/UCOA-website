import ExcelJS from "exceljs";

import {
  formatExportDate,
  formatExportTimestamp,
  MEMBER_EXPORT_HEADERS,
  MEMBER_ROLES,
  MEMBERSHIP_STATUSES,
  type MemberExportRow,
  yesNo,
} from "@/lib/member-export";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { hasEnvVars } from "@/lib/utils";

function unavailableResponse(status = 404) {
  return new Response("Member export unavailable", {
    status,
    headers: {
      "Cache-Control": "private, no-store",
      "Content-Type": "text/plain; charset=utf-8",
    },
  });
}

function parseBoolean(value: string | null) {
  if (value === "yes") {
    return true;
  }

  if (value === "no") {
    return false;
  }

  return null;
}

function isAllowedValue<T extends readonly string[]>(value: string | null, values: T) {
  return value === null || values.includes(value);
}

function toWorksheetRow(row: MemberExportRow) {
  return [
    yesNo(row.executive),
    yesNo(row.organizer),
    yesNo(row.probation),
    yesNo(row.banned),
    yesNo(row.acc),
    row.role,
    row.first_name,
    row.last_name,
    yesNo(row.paid_fee),
    formatExportDate(row.date_joined),
    row.student_id ?? "",
    row.email ?? "",
    yesNo(row.added_to_email_list),
    row.phone_number ?? "",
    yesNo(row.blanket_waiver),
    row.notes ?? "",
    row.emergency_contact ?? "",
    row.status,
    row.emergency_contact_phone ?? "",
    yesNo(row.consent_to_share),
    formatExportTimestamp(row.account_created_at),
    formatExportDate(row.membership_year_start),
    formatExportDate(row.membership_year_end),
    row.affiliation ?? "",
    row.display_name ?? "",
    row.user_id,
    row.membership_id ?? "",
  ];
}

export async function POST(request: Request) {
  if (!hasEnvVars) {
    return unavailableResponse();
  }

  const supabase = await createClient();
  const { data: claims, error: claimsError } = await supabase.auth.getClaims();

  if (claimsError || !claims?.claims?.sub) {
    return unavailableResponse(401);
  }

  let payload: Record<string, unknown>;
  try {
    const body: unknown = await request.json();
    if (typeof body !== "object" || body === null || Array.isArray(body)) {
      return unavailableResponse(400);
    }
    payload = body as Record<string, unknown>;
  } catch {
    return unavailableResponse(400);
  }

  const statusValue = payload.status;
  const roleValue = payload.role;
  const searchValue = payload.search;
  const signedWaiverValue = payload.signedWaiver;
  const confirmationValue = payload.confirm;
  const status = statusValue === null || statusValue === undefined || statusValue === "" ? null : statusValue;
  const role = roleValue === null || roleValue === undefined || roleValue === "" ? null : roleValue;
  const search = searchValue === null || searchValue === undefined || searchValue === ""
    ? null
    : typeof searchValue === "string" ? searchValue.trim() : searchValue;
  const signedWaiver = signedWaiverValue === null || signedWaiverValue === undefined || signedWaiverValue === ""
    ? null
    : signedWaiverValue;
  const confirmed = confirmationValue;

  if (
    (typeof status !== "string" && status !== null)
    || (typeof role !== "string" && role !== null)
    || (typeof search !== "string" && search !== null)
    || (typeof signedWaiver !== "string" && signedWaiver !== null)
    || !isAllowedValue(status as string | null, MEMBERSHIP_STATUSES)
    || !isAllowedValue(role as string | null, MEMBER_ROLES)
    || (typeof search === "string" && search.length > 100)
    || ![null, "yes", "no"].includes(signedWaiver)
    || confirmed !== "yes"
  ) {
    return unavailableResponse(400);
  }

  const adminClient = createAdminClient();
  if (!adminClient) {
    return unavailableResponse(503);
  }

  const { data, error } = await adminClient.rpc("export_member_directory", {
    p_actor_id: claims.claims.sub,
    p_confirmation: confirmed,
    p_purpose: "google_drive_reconciliation",
    p_status: status || null,
    p_role: role || null,
    p_search: search || null,
    p_has_signed_waiver: parseBoolean(signedWaiver),
  });

  if (error) {
    if (error.code === "42501") {
      return unavailableResponse(403);
    }
    if (error.code === "54000") {
      return unavailableResponse(413);
    }
    return unavailableResponse(400);
  }

  const rows = (data ?? []) as MemberExportRow[];
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet("Members");
  worksheet.addRow([...MEMBER_EXPORT_HEADERS]);
  worksheet.addRows(rows.map(toWorksheetRow));
  MEMBER_EXPORT_HEADERS.forEach((header, index) => {
    worksheet.getColumn(index + 1).width = Math.min(Math.max(header.length + 2, 14), 42);
  });
  const workbookBuffer = await workbook.xlsx.writeBuffer();

  return new Response(workbookBuffer, {
    headers: {
      "Cache-Control": "private, no-store",
      "Content-Disposition": `attachment; filename="ucoa-members-${new Date().toISOString().slice(0, 10)}.xlsx"`,
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    },
  });
}