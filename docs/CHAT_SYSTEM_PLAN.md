# Chat System Plan — Appointment-Scoped Messaging

## Goals

- Patient and doctor can message **only in the context of a booked appointment**.
- No public or random user-to-user chat.
- Realtime via Socket.io with REST polling fallback.
- Admin sees **metadata only** by default (privacy).

## Data model

```prisma
model Message {
  id            String   @id @default(uuid())
  appointmentId String
  senderId      String
  receiverId    String
  content       String   @db.Text
  isRead        Boolean  @default(false)
  createdAt     DateTime @default(now())

  appointment Appointment @relation(...)
  sender      User @relation("SenderMessages", ...)
  receiver    User @relation("ReceiverMessages", ...)

  @@index([appointmentId, createdAt])
  @@index([receiverId, isRead])
}
```

## Authorization rules

| Action | Who |
|--------|-----|
| List/send messages | Patient or doctor on the appointment |
| Mark read | Receiver of messages |
| Chat meta | Admin only |
| Join socket room | Same as list/send |

Appointment status for chat: `confirmed` or `completed` (configurable; implemented as confirmed+completed).

## REST API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/appointments/:id/messages?cursor=&limit=50` | Paginated history (newest first or cursor-based) |
| POST | `/appointments/:id/messages` | Body: `{ content }` — max 2000 chars |
| PUT | `/appointments/:id/messages/read` | Mark all messages to current user as read |
| GET | `/appointments/:id/messages/unread-count` | Integer count |
| GET | `/admin/appointments/:id/chat-meta` | `{ messageCount, lastMessageAt, participants }` |

## Socket.io

**Room:** `appointment:{appointmentId}`

**Client → server:**

- `join-appointment` — `{ appointmentId, userId }` — server validates JWT user is participant

**Server → client:**

- `message:new` — full message payload
- `message:read` — `{ appointmentId, readerId }`

**Fallback:** Flutter polls `GET messages` every 10 seconds when socket disconnected.

## Security and privacy

- TLS in production (Railway/Vercel HTTPS).
- Validate appointment participation on every HTTP and socket action.
- Rate limit: e.g. 30 messages/minute per user per appointment.
- User-facing disclaimer: do not share passwords or full medical records in chat.
- Admin **must not** read message bodies in MVP (metadata endpoint only).
- Retention: consider 90-day archive policy in Phase 5.

## Abuse handling (future)

- `MessageReport` table — reporter, messageId, reason, status
- Block user — prevent new appointments between pair
- Admin queue for reported threads

Not implemented in Phase 4B launch.

## Flutter UX

- Entry: Appointment detail → “Message doctor” / “Message patient”
- `chat_screen.dart` — bubble list, text field, send
- Unread badge on appointment list cards
- `socket_io_client` package for web/mobile

## Testing checklist

1. Patient sends message → doctor receives via socket.
2. Doctor replies → patient sees update.
3. Third user cannot access thread (403).
4. Admin chat-meta returns count without content.
5. Polling works when socket disabled.
