# Live QA Checklist — DocBook Platform

Run this against the **production/deployed instance** after every deployment.

---

## 1. Health & Infrastructure

| # | Test | Expected | Result |
|---|---|---|---|
| 1.1 | `GET /api/v1/health` | 200, `"database":"healthy"` | ☐ |
| 1.2 | Response headers contain `X-Frame-Options` (Helmet) | Present | ☐ |
| 1.3 | CORS: frontend domain works (check browser console) | No CORS errors | ☐ |
| 1.4 | CORS: random origin blocked | 403 or blocked | ☐ |

---

## 2. Authentication

| # | Test | Expected | Result |
|---|---|---|---|
| 2.1 | Login as patient | Token issued | ☐ |
| 2.2 | Login as doctor | Token issued | ☐ |
| 2.3 | Login as admin | Token issued | ☐ |
| 2.4 | Login with wrong password | 401 "Invalid email or password" | ☐ |
| 2.5 | Access protected route without token | 401 "Access denied. No token provided." | ☐ |
| 2.6 | Rapid login attempts (11+) | 429 after 10th attempt | ☐ |
| 2.7 | Token refresh works | New tokens returned | ☐ |

---

## 3. Patient Flow

| # | Test | Expected | Result |
|---|---|---|---|
| 3.1 | Browse doctors list | Doctors returned | ☐ |
| 3.2 | Search doctors by specialty | Filtered results | ☐ |
| 3.3 | View doctor profile | Profile loaded | ☐ |
| 3.4 | View available slots | Slots returned | ☐ |
| 3.5 | Book appointment | Status: confirmed | ☐ |
| 3.6 | Double booking same slot | 409 conflict | ☐ |
| 3.7 | View my appointments | Appointments listed | ☐ |
| 3.8 | Cancel upcoming appointment | Status: cancelled | ☐ |
| 3.9 | Create payment | Payment record created | ☐ |
| 3.10 | Mock payment success | Status: paid | ☐ |
| 3.11 | View payment status | Status shown | ☐ |

---

## 4. Doctor Flow

| # | Test | Expected | Result |
|---|---|---|---|
| 4.1 | View dashboard summary | Counts (today/upcoming/completed/cancelled/revenue) | ☐ |
| 4.2 | View appointments list | Appointments with patient + payment details | ☐ |
| 4.3 | View single appointment detail | Full details | ☐ |
| 4.4 | Complete appointment | Status: completed | ☐ |
| 4.5 | Cancel appointment | Status: cancelled | ☐ |
| 4.6 | Patient tries doctor route | 403 Forbidden | ☐ |

---

## 5. Admin Flow

| # | Test | Expected | Result |
|---|---|---|---|
| 5.1 | View dashboard summary | Platform-wide stats | ☐ |
| 5.2 | List all doctors | All 5 doctors | ☐ |
| 5.3 | List all patients | All patients | ☐ |
| 5.4 | List all appointments (filters) | Filtered by status/doctor/date | ☐ |
| 5.5 | List all payments (filters) | Filtered by status/provider | ☐ |
| 5.6 | Non-admin tries admin route | 403 Forbidden | ☐ |

---

## 6. Notifications

| # | Test | Expected | Result |
|---|---|---|---|
| 6.1 | Booking creates notification | Patient + doctor notified | ☐ |
| 6.2 | Cancel creates notification | Both parties notified | ☐ |
| 6.3 | Complete creates notification | Patient notified | ☐ |
| 6.4 | Payment success creates notification | Patient notified | ☐ |
| 6.5 | List notifications | Paginated list | ☐ |
| 6.6 | Unread count | Correct number | ☐ |
| 6.7 | Mark single as read | `isRead: true` | ☐ |
| 6.8 | Mark all as read | All read | ☐ |
| 6.9 | Unauthenticated access | 401 | ☐ |

---

## 7. Video Calls (Mock Mode)

| # | Test | Expected | Result |
|---|---|---|---|
| 7.1 | Get video session (confirmed appt) | `isMock: true`, uid, channel | ☐ |
| 7.2 | Cancelled appointment | 403 | ☐ |
| 7.3 | Completed appointment | 403 | ☐ |
| 7.4 | Non-confirmed appointment | 403 | ☐ |
| 7.5 | Unrelated user | 403 | ☐ |
| 7.6 | Admin gets metadata only | `isMock: true`, no token | ☐ |

---

## 8. Flutter Web App

| # | Test | Expected | Result |
|---|---|---|---|
| 8.1 | App loads without console errors | Clean console | ☐ |
| 8.2 | Splash → auto-login (or login screen) | Navigates correctly | ☐ |
| 8.3 | Patient home screen loads with doctors | Doctors visible | ☐ |
| 8.4 | Search screen works | Results update | ☐ |
| 8.5 | Booking flow works end-to-end | Appointment created | ☐ |
| 8.6 | Payment screen works | Payment processed | ☐ |
| 8.7 | Notifications bell shows badge | Unread count visible | ☐ |
| 8.8 | Notifications screen opens | List loads | ☐ |
| 8.9 | Doctor dashboard loads | Summary + appointments | ☐ |
| 8.10 | Admin dashboard loads | Stats visible | ☐ |
| 8.11 | Logout works | Redirects to login | ☐ |
| 8.12 | Browser refresh preserves auth session | Stay logged in | ☐ |

---

## 9. Logging & Errors

| # | Test | Expected | Result |
|---|---|---|---|
| 9.1 | Backend logs are JSON | No plain text logs | ☐ |
| 9.2 | No secrets in logs | No passwords/tokens exposed | ☐ |
| 9.3 | Error responses have no stack traces | `{ "error": "message" }` only | ☐ |
| 9.4 | 404 for unknown routes | `{ "error": "Route not found" }` | ☐ |

---

## 10. Database

| # | Test | Expected | Result |
|---|---|---|---|
| 10.1 | Migration status | "Database schema is up to date!" | ☐ |
| 10.2 | Seed data exists | Test users + doctors present | ☐ |
| 10.3 | New bookings create records | Appointment in DB | ☐ |

---

## Summary

| Section | Pass | Fail | Skip |
|---|---|---|---|
| 1. Health & Infrastructure | ☐ | ☐ | ☐ |
| 2. Authentication | ☐ | ☐ | ☐ |
| 3. Patient Flow | ☐ | ☐ | ☐ |
| 4. Doctor Flow | ☐ | ☐ | ☐ |
| 5. Admin Flow | ☐ | ☐ | ☐ |
| 6. Notifications | ☐ | ☐ | ☐ |
| 7. Video Calls | ☐ | ☐ | ☐ |
| 8. Flutter Web App | ☐ | ☐ | ☐ |
| 9. Logging & Errors | ☐ | ☐ | ☐ |
| 10. Database | ☐ | ☐ | ☐ |
| **Total** | | | |

**Go/No-Go Decision:** ☐ Ready for launch  ☐ Blocked (fix issues above)
