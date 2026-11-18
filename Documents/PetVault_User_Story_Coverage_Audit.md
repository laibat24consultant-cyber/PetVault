# PetVault user-story coverage audit

**Baseline:** `ThePetsVault_User_Stories_v1.1.docx` (11 epics, 29 stories)  
**Scope:** Current Flutter client, Express/PostgreSQL backend, migrations, and automated tests.

## Status key

- **Implemented** — core workflow exists in the app/backend; relevant behavior has automated coverage where practical.
- **Partial** — a useful workflow exists, but one or more specified capabilities or external integrations are missing.
- **Not implemented** — no production workflow currently satisfies the story.

## Story-by-story coverage

| Epic | User story | Status | Coverage and remaining work |
|---|---|---|---|
| 1. Identity, Authentication & Verified Onboarding | User Registration & Login | Partial | Registration, email-code verification, password reset, lockout, and authenticated sessions exist. Production email requires Resend configuration; SMS delivery is not configured. |
| 1. Identity, Authentication & Verified Onboarding | Role-Based Access Control | Implemented | Role-specific navigation and server-side role/ownership guards exist. Public admin selection is blocked; admin access is provisioned separately. Denied access is audited. |
| 1. Identity, Authentication & Verified Onboarding | KYC / Identity Verification | Partial | Submission, admin review, status, and supply-role enforcement exist. The stored document reference is not an uploaded identity document and no identity-provider adapter is configured. |
| 1. Identity, Authentication & Verified Onboarding | Account Deletion & Data Privacy | Partial | Account deletion checks active commitments and health access is consent-scoped/revocable. Legal retention/anonymization guarantees and portable data export require further policy and verification. |
| 2. Unified Pet Profile & Health Records | Pet Profile Creation & Management | Implemented | Pet profiles can be created, viewed, and edited and are used by care and marketplace workflows. |
| 2. Unified Pet Profile & Health Records | Vaccination & Medical History | Partial | Health records, due-date status, and vet consultation entries persist. Record attachments are metadata only; no file bytes are stored. |
| 2. Unified Pet Profile & Health Records | Document Upload & Access Permissions | Partial | Owners grant/revoke scoped, expiring access and unauthorized record reads are denied. Actual document upload, storage, and download are not implemented. |
| 3. Pet Marketplace (Buy/Sell) | Listing Creation & Management | Implemented | Verified sellers can create/manage listings; edits return through moderation. |
| 3. Pet Marketplace (Buy/Sell) | Marketplace Search & Discovery | Implemented | Listing search/filtering and favorites are available. Personalized recommendations are a separate, unimplemented story. |
| 3. Pet Marketplace (Buy/Sell) | Buyer–Seller Messaging & Transaction Flow | Partial | In-app conversations and transaction/dispute records exist. Protected escrow, confirmed handover, and automatic fund release are not enabled. |
| 3. Pet Marketplace (Buy/Sell) | Listing Moderation & Reporting | Implemented | Reports, human review actions, moderation metadata, and rule-based risk signals are persisted; risk signals do not automatically reject listings. |
| 4. Pet Sitting / Boarding | Sitter Profile & Availability | Partial | Verified sitters and booking requests work. A sitter service profile and availability calendar are not implemented. |
| 4. Pet Sitting / Boarding | Sitting Booking, Instructions & Cancellation | Implemented | Booking requests, instructions, status changes, cancellation, and emergency-contact privacy are supported. Sitters see emergency contacts only during a confirmed active booking. |
| 4. Pet Sitting / Boarding | Sitting Check-In Updates & Ratings | Partial | Sitters can post text check-ins during active bookings, and owners can read the updates. Photo upload and post-booking ratings are not implemented. |
| 5. Veterinary Care & Health Records | Vet Availability & Professional Verification | Partial | Verified veterinarians can publish slots and unverified roles are blocked. No external professional-license verification provider is connected. |
| 5. Veterinary Care & Health Records | Vet Discovery & Appointment Scheduling | Implemented | Owners can discover available verified-vet slots and book them; concurrent slot booking is guarded. |
| 5. Veterinary Care & Health Records | Tele-Consultation & Consultation Records | Partial | Consultation notes and optional follow-up dates persist to the appointment and pet health record, subject to owner-granted health access. Video consultation is not integrated. |
| 5. Veterinary Care & Health Records | Vet Ratings & Reviews | Not implemented | No completed-appointment vet-rating workflow is available. |
| 6. Pet Food & Accessories Commerce | Product Catalog & Vendor Management | Partial | Verified vendors can manage products and inventory; published out-of-stock products remain visible. Product variants are not implemented. |
| 6. Pet Food & Accessories Commerce | Cart, Checkout & Product Recommendations | Partial | Cart/order creation and explicitly configured mock checkout exist. No production payment adapter or personalized product-recommendation service is configured. |
| 6. Pet Food & Accessories Commerce | Order Tracking & Product Reviews | Partial | Orders and vendor fulfillment status are persisted. Delivery/carrier integration and product reviews are not implemented. |
| 7. Trust, Payment & Moderation Layer | Platform-Mediated Payment Processing | Not implemented | Local mock checkout does not charge a payment method. No approved production payment provider, settlement, or refund integration is configured. |
| 7. Trust, Payment & Moderation Layer | Cancellation, Refunds & Disputes | Partial | Users can submit disputes for supported orders, bookings, appointments, and listing transactions; admins can resolve cases. Decisions do not issue refunds or alter external payment settlement. |
| 7. Trust, Payment & Moderation Layer | Audit Trail & Admin Moderation Queue | Implemented | Admin moderation queues, paginated operational records, and audit events are database-backed and role-guarded. |
| 8. AI Recommendation & Matching Engine | Personalized Pet Discovery | Not implemented | Search and rule-based moderation signals exist, but no personalized discovery model/service is connected or evaluated. |
| 9. AI Support & Veterinary Triage Assistant | Grounded Support Chatbot | Partial | Users can submit support requests for human follow-up. No grounded chatbot or retrieval service is connected. |
| 9. AI Support & Veterinary Triage Assistant | Veterinary Triage & Red-Flag Routing | Partial | The app provides non-diagnostic care-routing guidance. No clinical triage model or validated medical knowledge service is connected. |
| 10. Notifications | Notifications & Reminders | Partial | In-app notifications are stored for key workflow events. Push/email/SMS delivery and scheduled vaccination reminders are not configured. |
| 11. Admin Dashboard & Analytics | Admin Dashboard & Secure Access | Partial | Admin-only dashboard counts and paginated operational views are database-backed. Production payment analytics and provider-dependent reporting are unavailable. |

## Admin Panel implementation

| Module | Status | Implementation notes |
|---|---|---|
| Dashboard | Completed | Counts come from PostgreSQL; cards drill into the relevant workspaces. |
| User and role management | Partial | Search, role/status/email-verification filters, paginated account records, KYC status display, suspend/reactivate actions, and session revocation are available. Admins cannot directly edit assigned roles; role activation follows the existing user/KYC workflows. |
| KYC & verification | Partial | Admin review and decision notes are persisted. Identity files and external licence verification are unavailable because no document/provider adapter exists. |
| Pet listings & moderation | Completed | Search, pending listing decisions, report review, risk queue, and moderation audit records use existing database workflows. |
| Bookings & veterinary appointments | Completed | Paginated scheduling/participant views; emergency contacts, consultation notes, and private health records are deliberately excluded. |
| Marketplace orders & payment monitoring | Partial | Orders, items, vendors, payment states, and mock transaction status are visible. No real payment references, settlement, or refunds are exposed or performed. |
| Products & vendors | Partial | Added a paginated, searchable, filterable, read-only products/inventory view joined with vendor identity. Vendors retain product-edit authority; no admin product-moderation state exists. |
| Disputes | Partial | Intake and admin decisions persist with audit events; decisions do not issue refunds or settle transactions. |
| Reviews & ratings | Partial | Admins can search and inspect records. Moderation is unavailable because the current schema has no moderation state/action. |
| Notifications | Partial | Stored in-app notification activity is visible; external delivery status is not available. |
| Support requests | Completed | Admins can search, page, and update supported request statuses. |
| Audit logs | Completed | Paginated, read-only audit events are available through the admin API. |
| Admin access & navigation | Completed | Server-enforced role checks, restricted provisioning, responsive bottom navigation, and a persistent scrollable desktop module sidebar with sign-out. |

### Admin APIs and persistence

- Admin routes include `/admin/dashboard`, `/admin/users`, `/admin/users/:id/status`, `/admin/listings`, `/admin/products`, `/admin/bookings`, `/admin/appointments`, `/admin/orders`, `/admin/disputes`, `/admin/reviews`, `/admin/notifications`, `/admin/audit-events`, and `/admin/support/requests`.
- Existing KYC, listing moderation, and listing-report APIs remain in their current route modules; equivalent APIs were reused rather than duplicated.
- All admin APIs apply backend `admin` role middleware. Administrative writes persist to PostgreSQL and relevant account, moderation, dispute, support, and KYC actions are audited.
- Migration `004_admin_workflows.sql` supplies persisted account suspension, listing review metadata, and query indexes. The product view uses the existing products/vendor schema; this UI addition required no migration.
- No migration resets or deletes existing records.

## Fixes covered by this audit

- Restricted sitter access to emergency-contact details to the confirmed booking interval and added active-booking text check-ins.
- Enforced owner-granted health access when veterinarians save consultation notes; saved notes and follow-up dates into pet health records.
- Kept published zero-stock products visible while retaining checkout stock validation.
- Made repeat successful payment requests idempotent for notifications and audit events.
- Added ownership-checked dispute intake with duplicate-open-case protection and admin notification/audit events.
- Corrected date-only API serialization so database dates do not shift by a timezone day.
- Added a persistent, scrollable admin desktop sidebar and dashboard statistic-card drill-downs to the corresponding record pages.
- Added read-only product/vendor inventory administration with server-side search, filters, pagination, and non-admin denial coverage.
- Updated the README's story-boundary table to reflect check-ins, consultation records, and dispute intake.

## Important files changed

- `backend/src/app.js` — shared pet-access extraction registration and date-only response serialization.
- `backend/src/pet-access.js` — reusable pet ownership/consent access check.
- `backend/src/routes/services.js` — active-booking contact privacy and check-ins; consent-checked vet consultation notes persisted to health records.
- `backend/src/routes/commerce.js` — out-of-stock catalog visibility and idempotent successful payment side effects.
- `backend/src/routes/disputes.js` — ownership-checked dispute intake, duplicate protection, admin notifications, and audit events.
- `backend/src/routes/admin.js` — database-backed admin dashboards and record APIs, including the products/vendor inventory view.
- `backend/test/api.integration.test.js` — focused coverage for the changed workflows.
- `lib/petvault_api.dart` and `lib/main.dart` — backend API integration, responsive admin navigation, inventory view, and dashboard drill-down.
- `test/admin_dashboard_test.dart` — admin dashboard data, inventory, navigation, drill-down, responsive layout, and sign-out coverage.
- `README.md` — current story boundaries and link to this audit.
- `Documents/PetVault_User_Story_Coverage_Audit.md` — this coverage report.

## Admin security verification

- **Public registration UI:** the dropdown is generated from the client's five-role public allowlist (Owner, Seller, Sitter, Veterinarian, Vendor); a widget test verifies no Admin option and the selected role is submitted.
- **Registration role injection:** the API validates roles against the backend `PUBLIC_ROLES` allowlist, rejects `admin`/`Admin`/case and unknown variants before user creation, audits rejected attempts, and rejects extra role fields through strict request schemas.
- **Role changes:** `/auth/roles` only activates a role already stored for the account; Admin activation is available only to an account already provisioned with Admin. KYC role requests use the supply-role allowlist and audit denied assignment attempts. No public profile-role update endpoint exists.
- **Provisioning:** `backend/src/provision-admin.js` requires operator-supplied environment credentials and an explicit email confirmation; it does not promote an existing account.
- **Admin endpoints and dashboard:** the integration suite verifies a non-admin receives `403` for an admin endpoint, a provisioned Admin can log in and load the dashboard, and admin API routes enforce server-side role checks.
- **Security review:** the scoped backend review reported no exploitable vulnerabilities. This does not substitute for a penetration test or provider/security certification.

## Validation performed

- Across final test runs: **29 passed, 0 failed, 1 skipped** (the database-dependent integration test is skipped by the standalone unit-test command).
- Backend unit/configuration tests: **3 passed, 1 database-dependent test skipped** in the standalone run.
- PostgreSQL integration suite: **passed** against a disposable local `petvault_test` database on port 5433; this includes public role allowlist acceptance/rejection, rejected-role audit records, Admin provisioning/login/dashboard access, admin authorization, product search/status filtering, and the privacy, check-in, consultation, stock, payment-idempotency, and dispute cases.
- Flutter tests: **25 passed**, including public signup role visibility/submission, client-side role validation, admin login/session, navigation, product view, dashboard drill-down, responsive layouts, and sign-out.
- Flutter static analysis: **no issues found**.
- Flutter Web build: **passed**. Flutter emitted an existing Cupertino icon-font warning; it did not block the build.
- Changed backend JavaScript syntax checks and `git diff --check`: **passed**.
- The backend has no separate compile/build script; backend syntax and runtime behavior were checked with Node.js and the PostgreSQL integration suite.

This is a repository-level implementation and test audit, not a penetration test, legal/privacy certification, payment-provider certification, or clinical validation. Provider-dependent features must remain marked incomplete until their integrations and acceptance tests exist.
