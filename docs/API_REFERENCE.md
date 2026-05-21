# API Reference

Base URL: `http://localhost:3000/api/v1`

All requests and responses are JSON. Auth endpoints (except login/register) require `Authorization: Bearer <token>` header.

---

## Health Check

### GET /health
No auth required.

**Response:**
```json
{ "status": "ok", "timestamp": "2026-05-16T..." }
```

---

## Auth

### POST /auth/register
No auth required.

**Notes:**
- Creates user with `isVerified: false`; must verify OTP before login
- 6-digit OTP sent via email (or printed to server console in dev)
- OTP expires in 10 minutes

**Body:**
```json
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "password": "string",
  "role": "patient|doctor"
}
```

**Response (201):**
```json
{
  "user": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "phone": "string",
    "role": "patient",
    "createdAt": "ISO8601"
  },
  "message": "OTP sent to email"
}
```

### POST /auth/login
No auth required.

**Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "phone": "string",
    "role": "patient|doctor|admin",
    "avatarUrl": "string|null",
    "isVerified": true,
    "createdAt": "ISO8601"
  },
  "accessToken": "eyJ...",
  "refreshToken": "eyJ..."
}
```

### POST /auth/refresh
No auth required.

**Body:**
```json
{ "refreshToken": "eyJ..." }
```

**Response (200):**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ..."
}
```

### POST /auth/verify-otp
No auth required.

**Notes:**
- Max 5 failed attempts per OTP (returns 429 after lockout)
- Successful verification sets `isVerified: true` and returns tokens
- Returns 400 for invalid/expired OTP

**Body:**
```json
{ "email": "string", "otp": "string" }
```

**Response (200):** Same shape as login (includes `accessToken`, `refreshToken`, `user`).

### POST /auth/resend-otp
No auth required.

**Notes:**
- Rate-limited: 60s cooldown between resends (returns 429)
- Generates new 6-digit OTP; previous OTP is invalidated
- New OTP expires in 10 minutes

**Body:**
```json
{ "email": "string" }
```

**Response (200):**
```json
{ "message": "OTP resent successfully" }
```
**Response (429):**
```json
{ "error": "Please wait before requesting another OTP" }
```

### POST /auth/logout
No auth required. Placeholder.

### GET /auth/me
Auth required (authenticate).

**Response (200):** Same `user` object as login.

---

## Doctors (Public)

### GET /doctors
No auth required. Lists all available doctors.

**Response:**
```json
{
  "doctors": [
    {
      "id": "uuid",
      "userId": "uuid",
      "name": "string",
      "specialty": "string",
      "qualification": "string",
      "experience": "string",
      "bio": "string",
      "consultationFee": 0,
      "yearsOfExperience": 0,
      "averageRating": 0,
      "totalReviews": 0,
      "availableDays": ["Monday", "Tuesday"],
      "isAvailable": true,
      "avatarUrl": "string|null",
      "hospital": { "name": "string", "city": "string" } | null
    }
  ]
}
```

### GET /doctors/search
Query params: `q` (search by name or specialty).

**Response:** Same shape as `/doctors`.

### GET /doctors/specialties
**Response:**
```json
{
  "specialties": ["Cardiologist", "Dermatologist", ...]
}
```

### GET /doctors/:id
**Response:**
```json
{
  "doctor": { /* full doctor object with user + hospital */ }
}
```

### GET /doctors/:id/slots
**Response:**
```json
{
  "slots": [
    {
      "id": "uuid",
      "doctorId": "uuid",
      "date": "ISO8601",
      "startTime": "09:00",
      "endTime": "09:30",
      "isBooked": false
    }
  ]
}
```

---

## Appointments

### POST /appointments
Auth: authenticate, authorize('patient')

**Body:**
```json
{
  "doctorId": "uuid",
  "date": "2026-06-08",
  "timeSlot": "09:00",
  "paymentProvider": "mock|stripe|payfast"   // optional
}
```

**Response (201):**
```json
{
  "appointment": {
    "id": "uuid",
    "patientId": "uuid",
    "doctorId": "uuid",
    "date": "ISO8601",
    "timeSlot": "09:00",
    "status": "pending",
    "doctor": { "id": "uuid", "name": "Dr. Name", "specialty": "string" },
    "patient": { "id": "uuid", "name": "Patient Name" },
    "payment": { "id": "uuid", "status": "pending", "provider": "mock" } | null,
    "createdAt": "ISO8601"
  }
}
```

### GET /appointments/my
Auth: authenticate. Returns current user's appointments.

**Response:**
```json
{
  "appointments": [ /* array of appointment objects */ ]
}
```

### GET /appointments/doctor
Auth: authenticate, authorize('doctor'). Returns logged-in doctor's appointments with patient details and payment info.

**Response:**
```json
{
  "appointments": [
    {
      "id": "uuid",
      "status": "confirmed",
      "date": "ISO8601",
      "timeSlot": "09:00",
      "patient": { "id": "uuid", "name": "string", "email": "string", "phone": "string" },
      "payment": { "status": "paid", "amount": 7500, "provider": "mock" } | null
    }
  ]
}
```

### PUT /appointments/:id/cancel
Auth: authenticate (patient or doctor).

**Response (200):**
```json
{
  "appointment": {
    "id": "uuid",
    "status": "cancelled",
    "patientId": "uuid",
    "doctorId": "uuid",
    "date": "ISO8601",
    "timeSlot": "09:00"
  }
}
```

### PUT /appointments/:id/complete
Auth: authenticate, authorize('doctor')

**Response (200):**
```json
{
  "appointment": {
    "id": "uuid",
    "status": "completed",
    "patientId": "uuid",
    "doctorId": "uuid",
    "date": "ISO8601",
    "timeSlot": "09:00"
  }
}
```

---

## Payments

### POST /payments/create
Auth: authenticate

**Body:**
```json
{
  "appointmentId": "uuid",
  "provider": "mock|stripe|payfast",
  "amount": 7500,
  "currency": "PKR"
}
```

**Response (200):**
```json
{
  "payment": {
    "id": "uuid",
    "appointmentId": "uuid",
    "amount": 7500,
    "currency": "PKR",
    "provider": "mock",
    "status": "pending",
    "providerTxnId": "txn_..."
  }
}
```

### POST /payments/mock-success
Auth: authenticate. Simulates successful payment for mock provider.

**Body:**
```json
{ "paymentId": "uuid" }
```

**Response (200):**
```json
{
  "payment": {
    "id": "uuid",
    "status": "paid",
    "provider": "mock"
  }
}
```

### GET /payments/status/:appointmentId
Auth: authenticate

**Response (200):**
```json
{
  "payment": {
    "id": "uuid",
    "appointmentId": "uuid",
    "amount": 7500,
    "currency": "PKR",
    "provider": "mock",
    "status": "paid",
    "createdAt": "ISO8601"
  }
}
```

---

## Doctor Dashboard

All routes require `authenticate` + `authorize('doctor', 'admin')`.

### GET /doctor/dashboard/summary
**Response (200):**
```json
{
  "summary": {
    "todayCount": 1,
    "upcomingCount": 7,
    "completedCount": 0,
    "cancelledCount": 3,
    "totalPatients": 1,
    "revenue": 7500
  }
}
```

### GET /doctor/appointments
Query params: `status` (optional filter: pending|confirmed|completed|cancelled)

**Response (200):**
```json
{
  "appointments": [
    {
      "id": "uuid",
      "patientId": "uuid",
      "doctorId": "uuid",
      "date": "ISO8601",
      "timeSlot": "09:00",
      "status": "confirmed",
      "notes": "string|null",
      "createdAt": "ISO8601",
      "patient": {
        "id": "uuid",
        "name": "string",
        "email": "string",
        "phone": "string"
      },
      "payment": {
        "id": "uuid",
        "amount": 7500,
        "currency": "PKR",
        "provider": "mock",
        "status": "paid"
      } | null
    }
  ]
}
```

### GET /doctor/appointments/:id
**Response (200):**
```json
{
  "appointment": {
    /* full appointment with patient + payment details */
  }
}
```

### PUT /doctor/appointments/:id/complete
**Response (200):**
```json
{
  "appointment": {
    "id": "uuid",
    "status": "completed",
    "patientId": "uuid",
    "doctorId": "uuid",
    "date": "ISO8601",
    "timeSlot": "09:00"
  }
}
```

### PUT /doctor/appointments/:id/cancel
**Response (200):** Same shape as complete, with `status: "cancelled"`.

---

## Admin Dashboard

All routes require `authenticate` + `authorize('admin')`.

### GET /admin/dashboard/summary
**Response (200):**
```json
{
  "summary": {
    "totalDoctors": 5,
    "totalPatients": 4,
    "totalAppointments": 15,
    "completedAppointments": 0,
    "cancelledAppointments": 3,
    "paidPaymentsCount": 3,
    "pendingPaymentsCount": 6,
    "totalRevenue": 7500
  }
}
```

### GET /admin/doctors
Returns flat list with hospital info.

**Response (200):**
```json
{
  "doctors": [
    {
      "id": "uuid",
      "name": "Ahmed Khan",
      "email": "ahmed.khan@docbook.com",
      "phone": "0300...",
      "isActive": true,
      "isVerified": true,
      "specialty": "Cardiologist",
      "qualification": "MBBS, FCPS",
      "consultationFee": 2500,
      "yearsOfExperience": 15,
      "averageRating": 4.5,
      "totalReviews": 42,
      "availableDays": ["Mon", "Tue", "Wed"],
      "hospitalName": "City General Hospital",
      "hospitalCity": "Lahore"
    }
  ]
}
```

### GET /admin/doctors/:id
**Response (200):**
```json
{
  "doctor": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "phone": "string",
    "isActive": true,
    "bio": "string",
    "specialty": "string",
    "qualification": "string",
    "consultationFee": 2500,
    "averageRating": 4.5,
    "availableDays": ["Mon", "Tue"],
    "hospital": { /* full hospital object */ }
  }
}
```

### GET /admin/patients
**Response (200):**
```json
{
  "patients": [
    {
      "id": "uuid",
      "name": "Test Patient",
      "email": "patient@test.com",
      "phone": "0300...",
      "isActive": true,
      "isVerified": true,
      "dob": "1995-06-15",
      "gender": "male",
      "bloodGroup": "B+"
    }
  ]
}
```

### GET /admin/patients/:id
**Response (200):** Full patient details including address, city, createdAt.

### GET /admin/appointments
Query params: `?status=&doctorId=&dateFrom=&dateTo=` (all optional)

**Response (200):**
```json
{
  "appointments": [
    {
      "id": "uuid",
      "patientId": "uuid",
      "doctorId": "uuid",
      "date": "ISO8601",
      "timeSlot": "09:00",
      "status": "confirmed",
      "patientName": "string",
      "patientEmail": "string",
      "patientPhone": "string",
      "doctorName": "string",
      "doctorEmail": "string",
      "hospitalName": "string",
      "payment": {
        "id": "uuid",
        "amount": 2500,
        "currency": "PKR",
        "provider": "mock",
        "status": "paid"
      } | null
    }
  ]
}
```

### GET /admin/appointments/:id
**Response (200):** Full appointment with patient, doctor, hospital, and payment details.

### GET /admin/payments
Query params: `?status=&provider=` (all optional)

**Response (200):**
```json
{
  "payments": [
    {
      "id": "uuid",
      "appointmentId": "uuid",
      "userId": "uuid",
      "amount": 2500,
      "currency": "PKR",
      "provider": "mock",
      "providerTxnId": "txn_...",
      "status": "paid",
      "createdAt": "ISO8601",
      "userName": "Test Patient",
      "userEmail": "patient@test.com",
      "appointmentDate": "2026-06-08T00:00:00.000Z",
      "appointmentTimeSlot": "09:00",
      "appointmentStatus": "confirmed"
    }
  ]
}
```

---

## Video Sessions

### GET /appointments/:id/video-session
Auth: authenticate. Returns video session details for a confirmed appointment.

**Access rules:**
- Patient who owns the appointment → full session with `uid: 1`
- Doctor who owns the appointment → full session with `uid: 2`
- Admin → metadata only (`isMock: true`, no token)
- Unrelated user → 403

**Blocked states (all return 403):**
- Appointment cancelled
- Appointment completed
- Appointment not confirmed (pending etc.)
- User is not a participant in the appointment

**Response (200) — patient/doctor:**
```json
{
  "success": true,
  "session": {
    "appId": "mock_app_id|real-agora-app-id",
    "channelName": "appt_{appointmentId}",
    "token": "mock_token_...|real-agora-rtc-token",
    "uid": 1,
    "isMock": true
  }
}
```

**Notes:**
- `channelName` is deterministic: `appt_{appointmentId}` — both participants get the same value
- `uid=1` for patient, `uid=2` for doctor
- `isMock=true` when `AGORA_APP_ID` is missing or set to placeholder in `.env`
- When `isMock=true`, `appId` is `"mock_app_id"` and `token` is a dummy string
- When `isMock=false` (real keys configured), `appId` is the real Agora App ID and `token` is a valid RTC token (expires in 1 hour)
- **Web limitation:** real Agora video on web additionally requires `iris-web-rtc_*.js` script in `web/index.html` (alpha stage feature)

---

## Notifications

All notification routes require `authenticate`.

### GET /notifications

Returns the authenticated user's notifications, most recent first.

**Query params:** `?page=1&limit=20` (both optional, defaults shown)

**Response (200):**
```json
{
  "notifications": [
    {
      "id": "uuid",
      "userId": "uuid",
      "title": "Appointment Confirmed",
      "body": "Your appointment with Ahmed Khan on 5/19/2026 at 10:00 has been confirmed",
      "type": "appointment_booked",
      "data": {
        "appointmentId": "uuid"
      },
      "isRead": false,
      "createdAt": "ISO8601"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20,
  "totalPages": 1
}
```

**Notification types:** `appointment_booked`, `appointment_cancelled`, `appointment_completed`, `payment_paid`

### GET /notifications/unread-count

**Response (200):**
```json
{ "count": 3 }
```

### PUT /notifications/:id/read

Marks a single notification as read.

**Response (200):**
```json
{
  "notification": {
    "id": "uuid",
    "userId": "uuid",
    "title": "Appointment Confirmed",
    "body": "...",
    "type": "appointment_booked",
    "data": { "appointmentId": "uuid" },
    "isRead": true,
    "createdAt": "ISO8601"
  }
}
```

### PUT /notifications/read-all

Marks all of the authenticated user's notifications as read.

**Response (200):**
```json
{ "message": "All notifications marked as read" }
```

---

## Error Response Format

All errors follow this shape:

```json
{
  "error": "Human-readable error message",
  "statusCode": 400
}
```

### Common HTTP Status Codes

| Code | Meaning |
|---|---|
| 200 | Success |
| 201 | Created |
| 400 | Bad request (validation error, missing/invalid fields) |
| 401 | Missing or invalid token |
| 403 | Forbidden (wrong role for endpoint) |
| 404 | Resource not found |
| 409 | Conflict (e.g., double booking) |
| 429 | Rate limited (OTP resend cooldown, max verify attempts) |
| 500 | Internal server error |
