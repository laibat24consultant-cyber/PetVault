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

## Fixes covered by this audit

- Restricted sitter access to emergency-contact details to the confirmed booking interval and added active-booking text check-ins.
- Enforced owner-granted health access when veterinarians save consultation notes; saved notes and follow-up dates into pet health records.
- Kept published zero-stock products visible while retaining checkout stock validation.
- Made repeat successful payment requests idempotent for notifications and audit events.
- Added ownership-checked dispute intake with duplicate-open-case protection and admin notification/audit events.
- Corrected date-only API serialization so database dates do not shift by a timezone day.
- Updated the README's story-boundary table to reflect check-ins, consultation records, and dispute intake.

## Validation performed

- Backend unit/configuration tests: **3 passed, 1 database-dependent test skipped** in the standalone run.
- PostgreSQL integration suite: **passed** against a disposable local `petvault_test` database on port 5433; this includes the new privacy, check-in, consultation, stock, payment-idempotency, and dispute cases.
- Flutter tests: **23 passed**.
- Flutter static analysis: **no issues found**.
- Flutter Web build: **passed**. Flutter emitted an existing Cupertino icon-font warning; it did not block the build.
- Changed backend JavaScript syntax checks and `git diff --check`: **passed**.

This is a repository-level implementation and test audit, not a penetration test, legal/privacy certification, payment-provider certification, or clinical validation. Provider-dependent features must remain marked incomplete until their integrations and acceptance tests exist.
