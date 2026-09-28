export const MEMBER_EXPORT_HEADERS = [
  "Executive",
  "Organizer",
  "Probation",
  "Banned",
  "ACC",
  "Role",
  "First Name",
  "Last Name",
  "Paid Fee? (Y/N)",
  "Date Joined (month/day/year)",
  "Student ID",
  "Email",
  "Added to email list",
  "Phone Number",
  "Blanket Waiver",
  "Notes (no shows/status, certifications like AST1, etc)",
  "Emergency Contact",
  "Status",
  "Phone number",
  "Consent to share",
  "Account Created (UTC)",
  "Membership Year Start",
  "Membership Year End",
  "Affiliation",
  "Display Name",
  "Account ID",
  "Membership ID",
] as const;

export type MemberExportRow = {
  executive: boolean;
  organizer: boolean;
  probation: boolean;
  banned: boolean;
  acc: boolean;
  role: string;
  first_name: string;
  last_name: string;
  paid_fee: boolean;
  date_joined: string | null;
  student_id: string | null;
  email: string | null;
  added_to_email_list: boolean;
  phone_number: string | null;
  blanket_waiver: boolean;
  notes: string | null;
  emergency_contact: string | null;
  status: string;
  emergency_contact_phone: string | null;
  consent_to_share: boolean;
  account_created_at: string;
  membership_year_start: string | null;
  membership_year_end: string | null;
  affiliation: string | null;
  display_name: string | null;
  user_id: string;
  membership_id: string | null;
};

export const MEMBERSHIP_STATUSES = [
  "account_created",
  "pending",
  "needs_verification",
  "active",
  "expired",
  "rejected",
  "suspended",
] as const;

export const MEMBER_ROLES = ["member", "organizer", "executive"] as const;

export function yesNo(value: boolean) {
  return value ? "Y" : "N";
}

export function formatExportDate(value: string | null) {
  if (!value) {
    return "";
  }

  const date = new Date(`${value.slice(0, 10)}T12:00:00Z`);
  if (Number.isNaN(date.getTime())) {
    return "";
  }

  return new Intl.DateTimeFormat("en-US", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "UTC",
    year: "numeric",
  }).format(date);
}

export function formatExportTimestamp(value: string | null) {
  if (!value) {
    return "";
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "" : date.toISOString();
}