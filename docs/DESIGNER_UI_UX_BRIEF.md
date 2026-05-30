# DocBook — UI/UX Design Brief

> **Prepared for:** UI/UX Designer or Google Stitch  
> **Status:** Ready for design  
> **Version:** 1.0  
> **Platform:** Flutter (iOS + Android + responsive)  

---

## A) Product Overview

### What is DocBook?

DocBook is a Pakistan-first doctor appointment booking and video consultation platform. Patients can find verified doctors, request appointments for free, wait for the doctor to confirm, chat after confirmation, and join video consultations when available.

### Market

Pakistan's healthcare booking market is currently served by:

- **Marham** — dominant player, appointment booking + clinic payments
- **Oladoc** — similar model, strong in major cities
- **Sehat Kahani** — female-doctor focused, telehealth

DocBook differentiates by being a **trust-first, verification-gated platform**.

### Main Value Proposition

- Patients book appointments **for free**
- Doctors set their own availability and confirm appointments manually
- All doctors are **verified and admin-approved** before public listing
- Real-time chat with the doctor after appointment confirmation
- Video consultation (Agora) on confirmed appointments

### What Makes It Different

| Feature | DocBook | Competitors |
|---------|---------|-------------|
| Booking fee | Free (patient does not pay) | Often paid booking fee |
| Doctor verification | PMDC + admin review | Varies |
| Appointment control | Doctor confirms each request | Auto-confirm common |
| Chat scope | Appointment-scoped only | Often open |
| Payment | Pay-at-clinic directly | Platform-based payments |
| Women's Health | Dedicated trust-focused category | Generic |

### Trust and Safety Positioning

DocBook's core promise is: **"You are talking to a real, verified doctor."**

- Admin reviews every doctor profile before listing
- PMDC registration number collected and verifiable
- "Do not pay unverified numbers" is a safety principle
- Screenshot protection on Android for video calls
- Strong password policy (10+ chars, uppercase, lowercase, number, symbol)
- Rate-limited auth endpoints (5 requests/min for registrations)

---

## B) User Roles

### Patient

| Attribute | Detail |
|-----------|--------|
| **Goal** | Find a verified doctor, book an appointment, consult via chat/video |
| **Permissions** | Search doctors, view profiles, request appointments, cancel own pending appointments, chat after confirmation, join video calls after confirmation, edit own profile |
| **Main actions** | Search → View doctor → Request appointment → Wait for confirmation → Chat → Video call |
| **Pain points** | Unclear if doctor is verified, not knowing when doctor will confirm, no payment awareness, weak empty states when no doctors found, unclear appointment lifecycle |
| **Screens needed** | Home, Search, Doctor Profile, Book Appointment, Appointment Confirmation, Appointments List, Appointment Detail, Chat, Video Call, Profile, Notifications, Inbox, Support |

### Doctor

| Attribute | Detail |
|-----------|--------|
| **Goal** | Receive genuine patient requests, manage availability, confirm appointments, consult via chat/video |
| **Permissions** | View own dashboard, confirm/cancel/complete own appointments, chat after confirmation, join video calls for confirmed appointments, edit own profile |
| **Main actions** | Dashboard → Review requests → Confirm time → Chat → Complete appointment |
| **Pain points** | Unclear approval status, no clear onboarding success state, fee display awkward, dashboard cards text wrapping, no availability calendar |
| **Screens needed** | Dashboard, Appointment Requests, Today's Appointments, Upcoming/Confirmed, Completed/Cancelled, Profile Edit, Chat, Video Call |

### Admin

| Attribute | Detail |
|-----------|--------|
| **Goal** | Maintain platform trust by reviewing and approving doctors, monitoring activity |
| **Permissions** | View all doctors/patients/appointments, approve/reject doctors, toggle doctor active/inactive, view payments data, run email diagnostics |
| **Main actions** | Dashboard → Review new doctors → Approve/reject → Monitor activity |
| **Pain points** | No inline doctor verification evidence display, no notification on new signups, charts are basic, no search/filter on patient list |
| **Screens needed** | Dashboard, Doctors List, Doctor Detail/Approval, Patients List, Appointments List, Payments List |

---

## C) Full Screen Inventory

### Auth Screens

| Screen | Implemented? | Notes |
|--------|-------------|-------|
| Splash / Launch | Yes | Animated splash, performs auth check, routes to login or home |
| Login | Yes | Email + password form |
| Register (Patient) | Yes | Name, email, phone, city, password, confirm password |
| OTP Verification | Yes | 6-digit input, resend timer |
| Forgot Password | Yes | Email input triggers OTP |
| Reset Password | Yes | OTP + new password form |
| Doctor Onboarding | Yes | Extended form: name, email, phone, specialty, qualification, years of experience, city, clinic/hospital name, consultation fee, PMDC number, video consultation toggle, clinic consultation toggle, password, confirm password |

### Patient Screens

| Screen | Implemented? | Notes |
|--------|-------------|-------|
| Home | Yes | Specialties grid (icons), upcoming appointments, quick action cards |
| Doctor Search | Yes | Search bar + specialty filter chips + doctor result cards |
| Specialty Browsing | Yes | Via home screen specialty icons or search filter |
| Doctor Profile | Yes | Photo, name, specialty, rating, experience, fee, bio, available days, book button, reviews |
| Request Appointment | Yes | Date picker + time slot grid (9AM-5PM, 30min), confirm button |
| Appointment Confirmation | Yes | Post-book success screen with appointment details |
| My Appointments | Yes | Filterable list (pending/confirmed/completed/cancelled) |
| Appointment Detail | Yes | Full detail with status badge, doctor info, chat button, video button, cancel action |
| Inbox / Conversations | Yes | List of appointment-scoped conversations with latest message preview |
| Chat | Yes | Real-time messaging per appointment, text only, message bubbles |
| Video Call | Yes | Agora RTC UI (mobile) or fallback screen (web) |
| Profile / Settings | Yes | Patient info edit, theme selector (System/Light/Dark) |
| Support / Legal / Privacy | Yes | Static page with contact info |
| Notifications | Yes | List of notifications with read/unread states |

### Doctor Screens

| Screen | Implemented? | Notes |
|--------|-------------|-------|
| Dashboard | Yes | Summary stat cards + appointments list |
| Appointment Requests | Yes | Via dashboard "Pending" filter tab |
| Today's Appointments | Yes | Via dashboard "Today" filter tab |
| Upcoming / Confirmed | Yes | Via dashboard filter |
| Completed / Cancelled | Yes | Via dashboard filter |
| Confirm Appointment Dialog | Yes | Modal dialog for the doctor to set date/time slot |
| Chat | Yes | Same ChatScreen, shared component |
| Video Call | Yes | Same VideoCallScreen, shared component |
| Profile Edit | Yes | Name, phone, specialty, qualification, experience, bio, fee, available days, video/clinic availability |

### Admin Screens

| Screen | Implemented? | Notes |
|--------|-------------|-------|
| Dashboard | Yes | Summary: total doctors, patients, appointments, revenue |
| Doctors List | Yes | Cards with name, specialty, fee, approval status badge |
| Doctor Detail / Approval | Yes | Bottom sheet with full profile + approve/reject/active toggle |
| Patients List | Yes | Simple cards with name, email, phone |
| Appointments List | Yes | Filterable list with status, patient, doctor, date |
| Payments List | Yes | Table with amount, provider, status, user |
| Reports / Support | Yes | Support screen is shared; separate report endpoint exists |

---

## D) Existing Functional Flows

### 1. Patient Signup

1. User taps "Create Account" on login screen
2. Register screen loads with fields: Full name, Email, Phone, City, Password, Confirm password
3. User fills form, taps "Create Account"
4. `POST /auth/register` — backend validates password (min 10, upper, lower, digit, symbol, no common/name/email in password), checks email not already registered, creates `PendingRegistration` with bcrypt-hashed OTP
5. Backend sends OTP email via Brevo (or SMTP fallback, or logs to console in dev)
6. On success, user is redirected to OTP verification screen
7. If error (e.g. email taken), error `MessageBanner` shown above form

### 2. OTP Verification

1. OTP screen shows masked email ("OTP sent to ah***@example.com")
2. User enters 6-digit code
3. If no OTP received, "Resend code" button (60s cooldown enforced by backend)
4. Tap "Verify" → `POST /auth/verify-otp`
5. Backend compares OTP via bcrypt, checks expiry and attempt count (max 5)
6. On success: creates `User` + `Patient`/`Doctor` record in transaction, deletes `PendingRegistration`, returns JWT tokens
7. User is logged in and redirected to role-based home screen
8. On failure: inline error message, or "Too many attempts" requiring resend

### 3. Login

1. Email + password form
2. `POST /auth/login`
3. Backend: find user by email, check isActive + isVerified, bcrypt compare
4. On success: returns accessToken (15min) + refreshToken (7d) + user object
5. On failure: generic "Invalid email or password" (no user enumeration)
6. Demo admin login blocked in production

### 4. Forgot / Reset Password

1. "Forgot password?" link on login → email input
2. `POST /auth/forgot-password` — generates OTP (stored in Redis or in-memory Map), sends email
3. If email exists, always says "If an account exists, a reset code has been sent" (no enumeration)
4. User enters OTP + new password on reset screen
5. `POST /auth/reset-password` — verifies OTP, bcrypt-hashes new password, updates user

### 5. Doctor Onboarding

1. "I am a doctor — request onboarding" link on register screen
2. Extended form (complete field list):
   - Full name (required)
   - Email (required, receives OTP)
   - Phone (required)
   - Specialty (required, free-text)
   - Qualification (required, e.g. "MBBS, FCPS (Cardiology)")
   - Years of experience (required, numeric)
   - City (required)
   - Clinic / Hospital name (required)
   - Consultation fee (PKR) (required, numeric — informational only)
   - PMDC registration number (required, verifiable)
   - Video consultation available? (toggle: Yes/No — controls video call visibility)
   - Clinic consultation available? (toggle: Yes/No)
   - Password (required, strength meter, min 10 chars)
   - Confirm password (required)
3. Info banner at top: "Your profile will be reviewed by our admin team before patients can see you. This usually takes 1–2 business days."
4. Password strength meter (Weak/Medium/Strong bar)
5. `POST /auth/register-doctor` — backend validates all fields including PMDC, creates `PendingRegistration` with role=doctor
6. Doctor proceeds through same OTP flow as patient
7. On OTP verify, a `Hospital` record is created (from clinicName + city) and linked to the `Doctor` record
8. Doctor record starts as `isApproved: false` — invisible to patients

### 6. Admin Approval of Doctor

1. Admin logs in → taps "Doctors" tab
2. List shows all doctors with status badges: "Pending" (orange), "Approved" (green), "Inactive" (red)
3. Tap a doctor card → bottom sheet with full detail: name, email, phone, specialty, PMDC, qualification, experience, fee, rating, available days, hospital
4. Admin can:
   - **Approve**: sets `isApproved: true`, `isAvailable: true` → doctor appears in patient search
   - **Revoke Approval**: sets `isApproved: false` → doctor hidden from search
   - **Activate/Deactivate**: toggles `isActive` on the User → deactivates account entirely

### 7. Patient Doctor Search

1. Home screen shows specialty icons grid (Cardiologist, Dermatologist, etc.)
2. Tap specialty → `SearchScreen` with filter applied
3. Search bar also allows text search by doctor name or specialty
4. Results: cards with doctor name, specialty, city, hospital, rating, fee, availability indicator
5. Cards show "Pending Approval"/"Approved" badge if... actually no — unapproved doctors are filtered out by backend
6. Tap card → Doctor Profile screen

### 8. Appointment Request

1. Doctor Profile screen: name, photo, rating, experience, fee, bio, available days
2. "Book Appointment" CTA button
3. Book screen: date picker + time slot grid (9:00 AM–5:00 PM, 30-min slots)
4. Only available days (from doctor's `availableDays`) are tappable
5. Already-booked slots are shown as disabled
6. No payment selection (payment flow is separate and not part of booking)
7. "Confirm Booking" → `POST /appointments` (authenticated)
8. Creates appointment with status `pending`

### 9. Doctor Appointment Confirmation

1. Doctor sees new `pending` appointment in dashboard list
2. Tap appointment → detail view
3. "Confirm" button → dialog asking doctor to set date and time slot (default is the requested slot)
4. `PUT /doctor/appointments/:id/confirm` — updates status to `confirmed`
5. Both parties receive notification

### 10. Appointment Pending State

**Patient sees:**
- Status badge: "Pending" (yellow/orange)
- "Waiting for doctor confirmation" message
- Cancel button available
- Chat and Video buttons **disabled** or **hidden**
- No meeting link

**Doctor sees:**
- Status badge: "Pending"
- "Awaiting your confirmation" message
- Confirm button available
- Chat and Video buttons **disabled**

### 11. Appointment Confirmed State

**Patient sees:**
- Status badge: "Confirmed" (green)
- Chat button **enabled**
- Video call button **enabled** (if Agora configured)
- Cancel button still available
- Appointment date/time and doctor details

**Doctor sees:**
- Status badge: "Confirmed"
- Chat button **enabled**
- Video call button **enabled**
- Complete button available
- Cancel button available

### 12. Chat Availability Rules

- Chat is **only available** for appointments with status `confirmed` or `completed`
- Chat is **per-appointment** (scoped; not an open conversation)
- Both patient and doctor can send messages
- Messages have a 2000-character limit
- Real-time via Socket.IO (with 10s polling fallback)
- Unread count shown in inbox

### 13. Video Call Availability Rules

- Video call button **only appears** when appointment status is `confirmed`
- `GET /appointments/:id/video-session` validates appointment status, generates Agora token
- On mobile (iOS/Android): opens full-screen Agora RTC UI with camera/mic controls
- On web: shows "Mobile-Only Feature" fallback screen (Agora web SDK not integrated)

### 14. Completed / Cancelled Appointment

**Completed:**
- Status badge: "Completed" (gray)
- Chat remains visible in **read-only mode** — patient and doctor can view the conversation history but cannot send new messages
- A small notice appears: "This appointment has ended. Chat is now read-only."
- Video call disabled
- No further actions required
- *(Future: limited follow-up window — e.g. 24h of active chat post-completion, then read-only — not yet implemented)*

**Cancelled:**
- Status badge: "Cancelled" (red)
- Chat is **disabled** and hidden or shown read-only with "Appointment was cancelled" notice
- Video disabled
- Patient can book a new appointment with the same doctor or another

### 15. Theme Mode Setting

- Theme mode persisted via `flutter_secure_storage`
- Three options: **System** (default, follows device), **Light**, **Dark**
- Accessible from Patient Profile screen under "Appearance" section
- Radio-list selection with check indicator
- Backend-independent (no API call required)

### 16. Support / Legal Flow

- Support screen accessible from profile menu
- Static content: email (svh@docbook.pk), support hours
- Links to Legal and Privacy pages (can be static screens or web views)
- No in-app ticketing system yet

---

## E) Appointment Lifecycle

### Status Definitions

| Status | Meaning | Color |
|--------|---------|-------|
| `pending` | Patient requested, doctor hasn't responded yet | Orange/Warning (#F59E0B) |
| `confirmed` | Doctor has accepted and set a date/time | Green (#10B981) |
| `completed` | Doctor marked appointment as done | Gray (#64748B) |
| `cancelled` | Either party cancelled | Red (#EF4444) |

**(Payment-related statuses like `paid`/`refunded` exist in the backend Payment model but are NOT part of the active appointment flow.)**

### Rules Matrix

| Action | Who can do it | When |
|--------|--------------|------|
| Create (book) | Patient only | Any time (subject to doctor availability) |
| Confirm | Doctor only | When status is `pending` |
| Cancel | Patient or doctor | When status is `pending` or `confirmed` |
| Complete | Doctor only | When status is `confirmed` |
| Send chat message | Patient or doctor | When status is `confirmed` (completed = read-only) |
| Read chat history | Patient or doctor | When status is `confirmed` or `completed` |
| Video call | Patient or doctor | When status is `confirmed` |

### What Each Role Sees

| Status | Patient View | Doctor View | Admin View |
|--------|-------------|-------------|------------|
| Pending | "Waiting for confirmation", cancel button, chat/video hidden | "Awaiting your response", confirm + cancel buttons | Standard row with status badge |
| Confirmed | Chat button (active), video button, cancel button, date/time, doctor details | Chat button (active), video button, complete button, cancel button | Standard row with status badge |
| Completed | Chat history visible (read-only) with notice, video disabled, no actions | Chat history visible (read-only) with notice, video disabled, no actions | Standard row with status badge |
| Cancelled | "Cancelled" notice, chat hidden/read-only, option to rebook | "Cancelled" notice, chat hidden/read-only | Standard row with status badge |

---

## F) Video Consultation Flow

### Backend (Agora)

- `GET /appointments/:id/video-session` endpoint
- Validates appointment exists, status is `confirmed`, user is a participant
- Generates Agora RTC token using `appId`, `appCertificate`, `channelName`, `uid`, role, expiration
- Returns: `{ appId, channelName, token, uid, isMock }`
- If Agora is not configured (missing env vars), returns mock token with `isMock: true`

### Mobile (iOS / Android)

- `agora_rtc_engine` Flutter plugin (native only)
- Camera and microphone permissions requested on first launch
- Full-screen UI with:
  - Local video (small PiP overlay)
  - Remote video (full screen)
  - Mute/unmute mic button
  - Camera on/off button
  - End call button
  - Connection status indicator
- On Android: `FLAG_SECURE` enabled to block screenshots
- On iOS: screenshot detection / blur not fully implemented (do not overclaim)

### Browser / Web

- **Decision: Video consultation is mobile-first for MVP**
- `kIsWeb` check → **clean fallback screen** displayed with phone icon and text: "Video consultations are currently available on the DocBook mobile app."
- Agora Web SDK is **not integrated** in the current version
- Future Agora Web SDK integration is marked as **v2** — the designer should acknowledge this as a known platform gap but not design a web video UI
- The fallback screen should be visually cohesive with the rest of the app, not an afterthought

### Privacy / Security

- Android: screenshot blocking via `ScreenSecurity.enableScreenshotProtection()` (platform channel)
- iOS: partial screenshot recording detection (cannot fully block every screenshot like Android)
- No recording or streaming of calls
- Video session is appointment-scoped — only participants of that appointment can join

---

## G) Doctor Verification / Security Requirements

### Current

| Requirement | Status | Detail |
|-------------|--------|--------|
| PMDC number | Required | Collected during onboarding, validated as non-empty |
| Qualification | Collected | Stored on Doctor model, editable in profile edit |
| City | Required | Collected during onboarding |
| Clinic/Hospital | Required | Name collected, new Hospital record created per doctor |
| Specialty | Required | Free-text (not constrained to enum) |
| Phone | Required | Collected during onboarding |
| Email OTP | Required | Must verify before account creation |
| Password | Required | Min 10 chars, uppercase, lowercase, digit, symbol, no common/name/email |
| Admin approval | Required | Doctor invisible to patients until `isApproved: true` |
| States | 3 states | `pending` (unapproved), `active` (approved + available), `inactive` (deactivated) |

### Fake Doctor / Scam Prevention

- Admin reviews profile before public listing
- PMDC number is a verifiable credential (Pakistan Medical Commission)
- Hospital name + city provides location credibility
- Rate-limited registration endpoints prevent mass fake signups
- No upfront payment required from patients (reduces financial scam surface)
- "Do not pay unverified numbers" safety messaging

### Doctor Profile Visibility Rules

- `isApproved = false` → Doctor **not visible** in patient search
- `isApproved = true` + `isActive = true` → Doctor **visible** in patient search
- `isActive = false` → Doctor account deactivated, **not visible**, cannot log in
- Admin can see all doctors regardless of status

---

## H) Payment / Scam Safety Model

### Critical: DocBook Does NOT Collect Payments

- **No payment gateway is active in the user flow**
- `StripePaymentProvider` and `PayFastPaymentProvider` exist in the backend codebase but are **not wired into any user-facing flow**
- The `Payment` model exists in the database schema, and the admin payments screen exists, but payments have no user-facing booking integration

### Decision: Removed from User-Facing IA

- **Payment screen is removed** from patient and doctor navigation
- The payment-related API endpoints and admin payments list exist solely for backend/admin transparency — they are **not part of any user-facing flow**
- **No Stripe/PayFast UI** is designed anywhere in the patient or doctor journey
- Doctors' consultation fee is displayed as **informational-only** with "pay at clinic" label
- After an appointment is confirmed, the appointment detail screen shows a **safety guidance card** (not a payment form) reminding the patient to pay the clinic directly
- Future direct-payment proof-of-payment flow (if any) is marked as **v2** and should not be designed now

### Safety Copy Requirements

- "DocBook does not collect payments"
- "Pay your doctor directly at the clinic after your appointment is confirmed"
- "Do not pay unverified numbers or accounts"
- "Doctor details are verified before public listing"
- "Report suspicious payment requests to svh@docbook.pk"

### Fee Display Rule

- Doctor's consultation fee is shown as **informational only** ("Rs 1500 — pay at clinic")
- The fee is not collected by the platform
- Appointment booking does not require payment — no price-gating on booking
- Doctors can mark themselves as "Free consultation" (fee = 0)
- After appointment confirmation, a safety guidance slot appears: "This doctor charges Rs X. Please pay the doctor/clinic directly at the time of your visit."
- No payment form, no provider selection, no transaction UI

---

## I) Women's Health / Gynecologist Feature Direction

### Why It Matters

- Women's health is a sensitive, high-trust category in Pakistan
- Many women prefer female gynecologists for consultations
- A dedicated trust-focused category signals safety and privacy

### Target Use Cases

- Women seeking gynecological consultations
- Privacy-sensitive health concerns
- Preference for female doctors

### Implementation Status

- **Current schema does NOT include a doctor gender field**
- A female-doctor filter is **future-ready** — the designer should note it in the information architecture but **not treat it as a current requirement**
- The Women's Health category can launch with gynecologists (mixed gender) and gain trust first
- Doctor gender can be added to the Doctor model and onboarding form in a future iteration

### Design Tone

- Calm, warm, private
- **Not** clinical or intimidating
- Respectful language throughout
- No diagnosis claims — "Consult a healthcare professional"
- Medical disclaimer + emergency disclaimer required

### Privacy / Safety

- Video consultation is private (appointment-scoped, screenshot protection on Android)
- Profile details are verified
- No recording or sharing of consultations

### Copy Rules

- Do not claim medical expertise or diagnoses
- Must include: "This platform provides a connection to healthcare professionals but does not provide medical advice, diagnosis, or treatment."
- Must include: "For medical emergencies, contact local emergency services immediately."

---

## J) Current UI/UX Problems

### Visual Quality

| Issue | Details |
|-------|---------|
| AI-generated look | Current UI uses basic Material components with minimal customization. Feels generic |
| Too much blue/white | Primary color (#2563EB) is overused. Cards, buttons, backgrounds all lean heavily on blue |
| Dark mode contrast bugs | Admin dashboard white cards on dark background, unreadable text on some surfaces |
| Inconsistent buttons | Mix of filled, outlined, text buttons with inconsistent padding and sizing |
| Inconsistent tabs | Filter tabs use different styles across screens |

### Layout / Spacing

| Issue | Details |
|-------|---------|
| Doctor fee layout awkward | Fee displayed inline with specialty on doctor cards — wraps awkwardly |
| Quick action cards text wrapping | Home screen action cards have text that overflows or wraps unevenly |
| Insufficient padding | Some screens have cramped spacing, others are too generous |
| Navigation/back transition issues | Some screens don't use consistent transition animation |

### States

| Issue | Details |
|-------|---------|
| Missing or weak empty states | "No doctors found" and "No appointments" screens are minimal |
| Missing loading skeletons | Only basic `CircularProgressIndicator` used — no shimmer/skeleton |
| Error banners are basic | `MessageBanner` is functional but not visually integrated |
| No success animation | OTP verified, appointment booked — no celebratory feedback |

### Platform

| Issue | Details |
|-------|---------|
| Web video fallback | Web users see a mobile-only fallback screen — needs to be cohesive with app design, not an afterthought |
| iOS vs Android differences | Some platform-specific behavior not handled |
| Safari compatibility | Not tested, potential issues with some dependencies |

### Content

| Issue | Details |
|-------|---------|
| Mock/fake payment labels | Payment screen had mock payment option — removed from IA per product decision. Ensure no payment UI appears in patient/doctor flow |
| Mixed terminology | "Appointments" vs "Bookings", "Inbox" vs "Conversations" not consistent |
| Weak about/legal screens | Support screen is functional but minimal |
| No medical disclaimer | Missing from doctor profile and consultation screens |

### Performance

| Issue | Details |
|-------|---------|
| Loading/hang/stutter | Some screens rebuild unnecessarily, chat can lag with many messages |
| No pagination loading | Infinite scroll not visually indicated in notification list |

---

## K) Design Requirements for New UI

### Overall Direction

- **Premium healthcare SaaS** — clean, calm, professional, trusted
- **Pakistan-first** — culturally appropriate, but globally scalable
- **Not childish** — no cartoon icons, playful colors, or gamification
- **Not generic** — must not look like a default Flutter app or AI-generated template
- **Not copied from Marham/Oladoc** — study hierarchy and UX patterns only, do not replicate visual identity
- **Mobile-first** — design for phone screens first, tablet second
- **iOS + Android** — must work well on both platforms
- **Light + Dark + System modes** — all three required
- **Accessible contrast** — WCAG AA minimum

### Visual Language

| Element | Direction |
|---------|-----------|
| Typography | Professional, clean. Use system font stack or Inter. Google Fonts currently used |
| Color palette | Calm, muted, healthcare-appropriate. Less aggressive blue. Earth tones or teal-based accent |
| Cards | Subtle shadows, rounded corners (12–16px), clean borders |
| Status badges | Pill-shaped, colored (orange=pending, green=confirmed, gray=completed, red=cancelled) |
| Verified badge | Trustmark icon next to verified doctor name |
| Icons | Line-style, consistent weight, outlined preferred |
| Spacing | Consistent 8px grid system |
| CTA buttons | Rounded, clear hierarchy (primary, secondary, outline, text) |
| Navigation | Bottom tab bar for primary navigation, clean app bars |
| Dialogs | Centered or bottom sheet, clear action buttons |
| Empty states | Illustrated or icon-based, with clear CTA |
| Loading states | Skeleton/shimmer placeholders, not spinners |

---

## L) Suggested Information Architecture

### Patient Bottom Navigation

| Tab | Screen | Icon |
|-----|--------|------|
| Home | Home Dashboard | house |
| Search | Doctor Search | magnifying glass |
| Appointments | My Appointments | calendar |
| Inbox | Conversations List | chat / message |
| Profile | Profile / Settings | person |

*Inbox is a first-class destination in the bottom nav. Notification bell remains in the app bar for real-time alerts.*

### Doctor Bottom Navigation

| Tab | Screen | Icon |
|-----|--------|------|
| Dashboard | Summary + Appointments | grid / squares |
| Requests | Pending Requests | clipboard |
| Appointments | All Appointments | calendar |
| Inbox | Conversations List | chat / message |
| Profile | Profile / Settings | person |

### Admin Bottom Navigation

| Tab | Screen | Icon |
|-----|--------|------|
| Dashboard | Platform Summary | grid |
| Doctors | Doctor Management | medical cross |
| Patients | Patient List | people |
| Appointments | All Appointments | calendar |
| More | Payments, Reports, Support | ellipsis / gear |

---

## M) Component System Needed

The designer should deliver a complete component library in Figma covering:

### Navigation
- App bar (top, with back, title, actions)
- Bottom navigation bar (3–5 tabs, selected/unselected states)
- Tab bar (segmented control style for filtering)

### Cards
- Doctor card (photo, name, specialty, rating, fee, location, status badge)
- Appointment card (status badge, doctor name, date/time, actions)
- Service/specialty card (icon + label, grid layout)
- Dashboard stat card (number + label + icon)
- Conversation card (avatar, name, last message preview, time, unread count)

### Badges & Indicators
- Status badge (pending/confirmed/completed/cancelled)
- Verified badge (trustmark)
- Online/offline indicator
- Unread count badge
- Rating badge

### Inputs & Forms
- Text field (regular, with icon, with helper/error)
- Password field with visibility toggle
- OTP input (6 digit boxes)
- Password strength meter (bar + label)
- Search bar
- Dropdown / select
- Date picker
- Time slot grid
- Radio/list tile (for theme selection)
- Switch / toggle

### Buttons
- Primary CTA button (filled, full-width)
- Secondary button (outlined)
- Text button
- Icon button
- Loading button (with spinner)
- Floating action button

### Feedback
- Empty state (icon + title + subtitle + optional CTA)
- Loading skeleton (shimmer placeholder)
- Error banner
- Success banner
- Info/trust banner
- Safety notice card
- Snackbar / toast
- Confirmation dialog

### Communication
- Chat bubble (sent/received, read status)
- Chat input bar (text field + send button)
- Video call controls (mute, camera off, end call)
- Incoming call screen

### Profile
- Profile header (avatar, name, role)
- Profile row (icon + label + value)
- Theme selector (radio tiles)

### Misc
- Section header (label + optional action)
- Filter chip
- Specialty icon (mapped to medical categories)
- Divider
- Bottom sheet (draggable)
- Notification item (title, body, time, read/unread)

---

## N) Copywriting Requirements

These messages must appear in the app. Provide them to the designer for layout context.

### Auth & Onboarding

| Copy | Where |
|------|-------|
| "Create Account" | Register screen heading |
| "Book appointments for free. Pay your doctor at the clinic." | Register screen subtitle |
| "I am a doctor — request onboarding" | Link on register screen |
| "Your profile will be reviewed by our admin team before patients can see you. This usually takes 1–2 business days." | Doctor onboarding info banner |
| "We will send a verification code to this email" | Email field helper |
| "At least 8 characters" → "Min 10 chars with upper, lower, number & symbol" | Password field helper |
| "Join the DocBook network" | Doctor onboarding subtitle |

### Appointments

| Copy | Where |
|------|-------|
| "Book appointments for free" | Home screen tagline |
| "Doctor will confirm the final time" | Booking confirmation screen |
| "Waiting for doctor confirmation" | Pending appointment detail |
| "Video call becomes available after confirmation" | Appointment detail (pending state) |
| "Chat with doctor" | Confirmed appointment CTA |
| "Join video call" | Confirmed appointment CTA |
| "Are you sure you want to cancel?" | Cancel confirmation dialog |

### Trust & Safety

| Copy | Where |
|------|-------|
| "DocBook does not collect payments" | Safety notice card |
| "Pay your doctor directly at the clinic after confirmation" | Doctor profile, booking flow |
| "Do not pay unverified numbers" | Safety notice card |
| "Doctor profiles are reviewed before public listing" | Trust banner |
| "Report suspicious activity" | Support screen |

### Medical Disclaimer

| Copy | Where |
|------|-------|
| "This platform provides a connection to healthcare professionals but does not provide medical advice, diagnosis, or treatment." | Doctor profile, About/Legal |
| "For medical emergencies, contact local emergency services immediately." | Doctor profile, Safety notice |

### Video Call

| Copy | Where |
|------|-------|
| "Video consultations are currently available on the DocBook mobile app." | Web fallback screen heading/body |
| "Connecting..." | Video call connecting state |
| "Call ended" | Video call disconnected state |

---

## O) Technical Constraints Designer Must Respect

### Platform

- Built with **Flutter** (Material 3 + custom theming)
- Existing app icon and assets must remain unchanged
- API is already fully built — **do not design new API-dependent features**
- Browser (web) video call is **not supported** — web users see fallback

### Payments

- **The payment screen is removed from main user-facing IA** — do not design a payment flow
- Payment models (Stripe, PayFast) exist in backend code but are **not wired into any user journey**
- Doctor fee is informational-only, shown as "pay at clinic"
- No payment form, no provider selection, no transaction UI
- After appointment confirmation, a **safety guidance card** replaces any payment UI: "Please pay the doctor/clinic directly"
- Future proof-of-payment feature is **v2** and out of scope
- Admin payments list screen exists for backend transparency — not for patient/doctor access

### Features NOT to Design

- No voice notes (feature disabled — `enableVoiceNotes = false`)
- No in-app ticketing/support system (email-only: svh@docbook.pk)
- No phone number login (email + password only)
- No social login (email + password only)
- No payment receipts/invoices from platform
- No web-based video call UI (mobile-only for MVP; Agora Web SDK is v2)
- No doctor gender filter (future-ready, not current scope)

### Modes

- All screens must support **light mode** and **dark mode**
- Theme selector offers System/Light/Dark (default: System)

### Responsiveness

- Must support small iPhones (SE, 12/13 mini) — avoid overflow
- Must support large Android phones (6.7"+)
- Tablet support is nice-to-have but not primary

### Accessibility

- Minimum WCAG AA contrast ratios
- Text should be resizable without breaking layout
- Touch targets minimum 44×44pt

### Localization

- Current language: **English**
- Future: Urdu / Roman Urdu support should be architecturally possible
- String extraction to `AppLocalizations` or similar preferred

---

## P) Stitch Prompt

Copy and paste this into Google Stitch:

```
I need a complete mobile app UI redesign for a Pakistan-first healthcare platform called "DocBook". This is a two-sided marketplace connecting patients with verified doctors.

THE PRODUCT:
- Patients search for verified doctors, book appointments for free, chat after confirmation, and join video consultations
- Doctors manage appointments, confirm requests, and consult via chat/video
- Admins approve doctors before public listing
- NO payment collection — patients pay doctors directly at the clinic
- Built with Flutter, needs professional healthcare design

CORE USER ROLES:
1. Patient — searches doctors, books appointments, chats (active on confirmed, read-only on completed), video calls (mobile only)
2. Doctor — manages dashboard, confirms appointments, chats, video calls, marks complete
3. Admin — approves doctors, monitors platform

DESIGN REQUIREMENTS:
- Premium healthcare SaaS look — clean, calm, professional, trusted
- Pakistan-first but globally scalable design language
- NOT childish, NOT generic AI app, NOT copied from Marham/Oladoc
- Mobile-first (iOS + Android), with light + dark + system mode support
- WCAG AA accessible contrast
- Consistent 8px grid, professional typography, line-style icons

SCREENS NEEDED (design each for light + dark mode):

AUTH:
1. Splash screen
2. Login (email + password)
3. Patient Register (name, email, phone, city, password with strength meter)
4. Doctor Onboarding — FULL field list: name, email, phone, specialty, qualification, years of experience, city, clinic/hospital name, consultation fee (PKR), PMDC number, video consultation toggle, clinic consultation toggle, password with strength meter, confirm password
5. OTP Verification (6-digit input)
6. Forgot Password (email input)
7. Reset Password (OTP + new password)

PATIENT FLOW (bottom nav: Home, Search, Appointments, Inbox, Profile):
8. Home (specialties grid, upcoming appointment, quick actions)
9. Doctor Search (search bar + specialty filter chips + result cards)
10. Doctor Profile (photo, name, specialty, rating, experience, fee, bio, available days, book button, reviews)
11. Book Appointment (date picker + time slot grid 9AM-5PM, no payment)
12. Appointment Confirmation (success state with safety guidance: "Please pay the doctor/clinic directly")
13. Appointment Detail (status badge, actions: chat/video/cancel; safety card if confirmed)
14. My Appointments List (filterable by status)
15. Inbox / Conversations (per-appointment chat list, first-class tab)
16. Chat Screen (per-appointment messaging; active on confirmed, read-only with notice on completed)
17. Video Call Screen (Agora fullscreen — mobile only; web shows "Available on mobile app" fallback)
18. Profile / Settings (edit info, theme selector System/Light/Dark)
19. Notifications List
20. Support / About / Legal (with medical disclaimer)

DOCTOR FLOW (bottom nav: Dashboard, Requests, Appointments, Inbox, Profile):
21. Dashboard (summary stats + appointment list with filter tabs)
22. Appointment Requests (pending tab with confirm action)
23. Appointment Detail (with confirm/cancel/complete actions, chat/video)
24. Profile Edit (name, phone, specialty, qualification, experience, bio, fee, available days, video/clinic availability)

ADMIN FLOW:
25. Dashboard (platform stats)
26. Doctors List (with approve/reject/active toggle)
27. Doctor Detail Bottom Sheet (full profile + approval actions)
28. Patients List
29. All Appointments List
30. Payments List (admin-only read-only view — no patient/doctor payment UI exists)

COMPONENTS TO DESIGN:
- App bars, bottom navigation (5 tabs), tab bars, segmented tabs
- Doctor cards, appointment cards, stat cards, specialty cards, conversation cards
- Status badges (pending/confirmed/completed/cancelled), verified badge
- Search bar, filter chips
- Forms with labels, OTP input, password strength meter
- Primary/secondary/outline/text buttons, loading button
- Empty states, loading skeletons, error banners, info banners, trust banners, safety notice cards
- Chat bubbles (sent/received, read-only mode indicator), chat input bar
- Video call controls (mute, camera, end call)
- Confirmation dialogs, bottom sheets
- Profile rows, theme selector, notification items

IMPORTANT COPY:
- "Book appointments for free. Pay your doctor at the clinic."
- "DocBook does not collect payments"
- "Please pay the doctor/clinic directly after confirmation" (safety card)
- "Do not pay unverified numbers"
- "Your profile will be reviewed before public listing"
- "Chat is now read-only — this appointment has ended" (completed chat)
- "Video call becomes available after confirmation"
- "Video consultations are currently available on the DocBook mobile app." (web fallback)
- "For medical emergencies, contact local emergency services"
- Medical disclaimer on doctor profiles and About page

DO NOT DESIGN:
- Payment gateway flow (no Stripe, PayFast, or any payment collection UI)
- Voice notes feature
- Phone login or social login
- Web video call — mobile-only for MVP (Agora Web SDK is v2)
- Doctor gender filter (future-ready, not current scope)
- Any features that require new backend APIs
- Payment receipts or invoices from platform

CHAT STATE RULES:
- Pending appointment: chat disabled, no chat button
- Confirmed appointment: chat active (both can send)
- Completed appointment: chat read-only with notice
- Cancelled appointment: chat disabled/hidden

VIDEO STATE RULES:
- On mobile: button appears only when status is confirmed
- On web: clean fallback screen (no video UI)

DELIVERABLES PER SCREEN:
- Light mode mockup
- Dark mode mockup  
- loading state
- empty state
- error state (where applicable)

OUTPUT: Complete Figma design system with components, screens, and flows ready for developer handoff.
```

---

## Q) Designer Handoff Checklist

### Screen List

- [ ] Splash / Launch
- [ ] Login
- [ ] Register (Patient)
- [ ] Doctor Onboarding
- [ ] OTP Verification
- [ ] Forgot Password
- [ ] Reset Password
- [ ] Patient Home
- [ ] Doctor Search
- [ ] Doctor Profile
- [ ] Book Appointment
- [ ] Appointment Confirmation
- [ ] Appointment Detail
- [ ] My Appointments (list)
- [ ] Inbox / Conversations
- [ ] Chat
- [ ] Video Call (mobile)
- [ ] Video Call Fallback (web)
- [ ] Patient Profile / Settings
- [ ] Notifications
- [ ] Support / About
- [ ] Doctor Dashboard
- [ ] Doctor Appointment Detail
- [ ] Doctor Profile Edit
- [ ] Admin Dashboard
- [ ] Admin Doctors List
- [ ] Admin Doctor Detail / Approval
- [ ] Admin Patients List
- [ ] Admin Appointments List
- [ ] Admin Payments List

### Component List

- [ ] App bar (top)
- [ ] Bottom navigation bar
- [ ] Tab bar (segmented)
- [ ] Doctor card
- [ ] Appointment card
- [ ] Dashboard stat card
- [ ] Specialty/service card
- [ ] Conversation card
- [ ] Status badge (4 variants)
- [ ] Verified badge
- [ ] Online indicator
- [ ] Search bar
- [ ] Filter chip
- [ ] Text field
- [ ] Password field
- [ ] OTP input
- [ ] Password strength meter
- [ ] Date picker
- [ ] Time slot grid
- [ ] Primary button
- [ ] Secondary button
- [ ] Outline button
- [ ] Text button
- [ ] Loading button
- [ ] Icon button
- [ ] Chat bubble (sent/received)
- [ ] Chat input bar
- [ ] Video call controls
- [ ] Empty state
- [ ] Loading skeleton
- [ ] Error banner
- [ ] Success banner
- [ ] Info/trust banner
- [ ] Safety notice card
- [ ] Confirmation dialog
- [ ] Bottom sheet
- [ ] Profile row
- [ ] Theme selector
- [ ] Notification item
- [ ] Divider
- [ ] Section header

### Light / Dark Deliverables

- [ ] Every screen designed in light mode
- [ ] Every screen designed in dark mode
- [ ] Component specs for both modes
- [ ] Color tokens for both modes documented

### Mobile Sizes

- [ ] Minimum: iPhone SE (375×667) or equivalent
- [ ] Primary: iPhone 15 / Android medium (390×844)
- [ ] Large: Android large (430×932)
- [ ] Tablet: iPad / Android tablet (nice-to-have)

### Assets Needed

- [ ] App icon (existing — must not change)
- [ ] Doctor placeholder avatar
- [ ] Specialty icons (12–15 medical specialties)
- [ ] Empty state illustrations (3–4 variants)
- [ ] Safety/trust illustrations
- [ ] Logo lockup (existing — must not change)
- [ ] Loading skeleton shapes

### Interaction States (per component)

- [ ] Default / Resting
- [ ] Active / Selected
- [ ] Pressed / Tapped
- [ ] Disabled
- [ ] Loading
- [ ] Error (for inputs)
- [ ] Focused (for inputs)
- [ ] Hover (desktop only)

### Empty / Loading / Error States

- [ ] No doctors found (search)
- [ ] No appointments (list)
- [ ] No messages (chat)
- [ ] No notifications
- [ ] Loading state per screen
- [ ] Network error state
- [ ] Generic error state
- [ ] OTP expired state

### Final Export Expectations

- [ ] Figma file with components as auto-layout
- [ ] Color palette as local styles
- [ ] Typography as local styles
- [ ] Spacing grid (8px increments)
- [ ] Exportable assets (SVG preferred)
- [ ] Developer handoff mode enabled
- [ ] Prototype with screen flows connected
- [ ] Design system documentation included

---

## Summary

**File created:** `docs/DESIGNER_UI_UX_BRIEF.md`

**Key findings:**

1. **30+ screens** are implemented and need redesign — auth (7), patient (12), doctor (4), admin (6), shared (3)
2. **60+ components** need design specs covering light + dark modes
3. **Appointment lifecycle** has 4 statuses (pending → confirmed → completed/cancelled) with strict chat/video gating rules
4. **No active payment flow** — Stripe/PayFast backends exist but are not connected; the payment screen should not be promoted
5. **Video call is mobile-only** (Agora RTC is native-only); web shows a fallback screen
6. **Dark mode has known contrast bugs** especially in admin screens (white cards on dark backgrounds)
7. **Doctor verification** is a key trust feature — PMDC required, admin review gating, but no direct verification evidence displayed to patients
8. **Women's Health direction** is identified as a priority category but doctor gender field does not exist yet
9. **All API endpoints are built** — design should not require new backend work

**Resolved product decisions (applied to this brief):**

1. ✅ **Payment screen** → Removed from main IA. Safety guidance only after confirmation. Payment gateway UI is out of scope. V2 if proof-of-payment is added.
2. ✅ **Doctor gender** → Future-ready. Not required for current implementation. No gender filter in MVP.
3. ✅ **Onboarding fields** → Qualification, experience, video/clinic availability toggles are all **required** in onboarding. Full field list documented in section D.5.
4. ✅ **Chat after completion** → Read-only after completed. Disabled/hidden after cancelled. Active during confirmed.
5. ✅ **Inbox placement** → First-class bottom nav tab for both patient (Home, Search, Appointments, Inbox, Profile) and doctor (Dashboard, Requests, Appointments, Inbox, Profile).
6. ✅ **Web video** → Mobile-only for MVP. Clean fallback screen. Agora Web SDK is v2 if prioritized.

**Brief is ready for: Paid designer ✓ | Google Stitch ✓**
