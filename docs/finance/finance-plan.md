# UCOA Finance and E-Transfer Boundary

**Status:** planning

**Last reviewed:** August 29, 2026

## Non-negotiable boundary

No actual money transaction should occur through the UCOA website. The website must not process payments, collect bank credentials, receive card details, store financial account information, or represent that payment has been completed automatically.

The website may display executive-approved instructions that redirect a member to their own bank's e-transfer flow or explain an approved cash option. An executive may record that payment was verified, but the application does not move money.

## Current public instruction

The current membership form says that the annual CAD 10 fee can be paid by e-transfer or cash at the first event. It also describes the membership year as September 1 through August 31. These details must be verified by the executive before they are published as site settings.

The public recipient address observed in the form is `uofc.oa@gmail.com`. Treat this as a changeable operational setting, not hard-coded application logic, and verify it before launch.

## MVP workflow

1. Applicant creates an account and completes the approved application fields.
2. Site displays the current fee, membership-year dates, e-transfer instructions, and cash alternative.
3. Applicant completes the transfer in their own banking environment or arranges the cash payment.
4. Executive verifies payment outside the website using the club's existing operational process.
5. Executive records only safe metadata in the application, such as:
	- Membership year.
	- Payment status: `pending`, `verified`, `not_required`, or `unable_to_verify`.
	- Payment method: `e_transfer`, `cash`, or `other_approved_method`.
	- Verification timestamp.
	- Verifying executive ID.
	- Optional short operational reference that contains no bank credentials or transaction secrets.
6. Membership becomes active only when eligibility, required application data, and the executive's approval rules are satisfied.

## Prohibited data and behavior

Never ask for or store:

- Online banking usernames or passwords.
- Bank account, transit, institution, or card numbers.
- Security questions, one-time codes, or transfer authentication data.
- Full financial statements or unnecessary payment screenshots.
- Payment processor tokens unless a future approved design explicitly introduces a processor and legal review.

Never:

- Embed a bank login page in an iframe.
- Accept card numbers in a custom form.
- Claim that an e-transfer was received based only on user input.
- Put payment instructions in source code when they can be executive-managed settings.
- Log payment details in analytics, error reports, or audit metadata.

## Data model guidance

Payment verification belongs to the membership record or a restricted verification table, not a public profile. Use explicit enums and timestamps. Keep audit entries limited to actor, action, membership reference, status transition, and safe metadata.

The public site may read only the fee, membership period, and approved instructions. Members may read their own payment/application status. Organizers do not need access to payment records. Executives may read and update verification metadata according to the security policy.

## Later consideration

If UCOA ever wants online payments, that is a separate project requiring executive approval, a payment provider, privacy and legal review, reconciliation design, fraud handling, refund policy, and a new security assessment. It is outside this implementation plan.

## Acceptance checks

- The application contains no payment processor SDK or card/bank input.
- E-transfer instructions are editable executive-managed content.
- A member can see their own application/payment status but not another member's data.
- Organizers cannot view or modify payment verification.
- Audit logs contain status transitions but no banking information.
- A payment status cannot be self-approved by the applicant.