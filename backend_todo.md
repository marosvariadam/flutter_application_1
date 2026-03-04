# Backend Completion List

## 1. Auth — minor additions

- **POST `/api/auth/logout`** — invalidate token server-side (optional but good practice)
- **POST `/api/auth/change-password`** — body: `{ currentPassword, newPassword }`; requires auth; 204 on success

---

## 2. Workout model — add missing fields

Add to the `Workout` document:

```
status          string  "Planned" | "InProgress" | "Completed"   (default: "Planned")
difficulty      string  "Easy" | "Moderate" | "Hard" | "Intense" (default: "Easy")
notes           string? (trainer notes on the workout)
athleteFeedback string? (set when athlete completes)
```

The existing `isCompleted: bool` can stay — just also set `status = "Completed"` when it's true.

Add to `WorkoutExercise`:

```
actualSets      int?
actualReps      int?
actualWeightKg  double?
```

---

## 3. Workout — missing endpoints

| Method  | Route                                  | Role    | Description |
|---------|----------------------------------------|---------|-------------|
| `PATCH` | `/api/workout/{id}/start`              | Athlete | Sets `status = "InProgress"` |
| `PATCH` | `/api/workout/{id}/exercises/{index}`  | Athlete | Logs actual sets/reps/weight for one exercise. Body: `{ actualSets, actualReps, actualWeightKg, athleteNotes }` |
| `PATCH` | `/api/workout/{id}/complete`           | Athlete | Sets `status = "Completed"`, saves `athleteFeedback`. Body: `{ feedback? }` (endpoint exists — update to accept feedback and set status field) |
| `GET`   | `/api/workout/trainer/calendar`        | Trainer | Query params: `from`, `to` (ISO dates). Returns workouts in that date range |
| `GET`   | `/api/workout/athlete/calendar`        | Athlete | Same as above but for the current athlete's workouts |
| `GET`   | `/api/workout/trainer/review`          | Trainer | Query param: `athleteId`. Returns completed workouts for that athlete |

---

## 4. Exercise — missing endpoint

| Method | Route               | Role                   | Description |
|--------|---------------------|------------------------|-------------|
| `PUT`  | `/api/exercise/{id}` | Trainer (owner only)  | Update exercise. Body: `{ name, muscleGroup, description?, equipment? }` |

---

## 5. Trainer requests — new feature

New controller `TrainerRequestController`:

| Method  | Route                              | Role    | Description |
|---------|------------------------------------|---------|-------------|
| `POST`  | `/api/trainer-request`             | Athlete | Send a join request. Body: `{ trainerEmail, note? }` |
| `GET`   | `/api/trainer-request/mine`        | Athlete | Get own sent requests |
| `GET`   | `/api/trainer-request/pending`     | Trainer | Get all pending incoming requests |
| `PATCH` | `/api/trainer-request/{id}/accept` | Trainer | Accept request; sets `athlete.trainerId = trainer.id` |
| `PATCH` | `/api/trainer-request/{id}/reject` | Trainer | Reject request |

New `TrainerRequest` document:

```
id           ObjectId
athleteId    ObjectId
athleteName  string
athleteEmail string
trainerEmail string
status       string  "Pending" | "Accepted" | "Rejected"
note         string?
createdAt    DateTime
```

---

## 6. Notifications — new feature

New controller `NotificationController`:

| Method  | Route                               | Role | Description |
|---------|-------------------------------------|------|-------------|
| `GET`   | `/api/notification`                 | Any  | Get all notifications for current user |
| `GET`   | `/api/notification/unread-count`    | Any  | Returns `{ count: int }` |
| `PATCH` | `/api/notification/{id}/read`       | Any  | Mark one as read |
| `PATCH` | `/api/notification/mark-all-read`   | Any  | Mark all as read |

New `Notification` document:

```
id        ObjectId
userId    ObjectId  (recipient)
type      string    "TrainerRequestAccepted" | "TrainerRequestRejected" | "WorkoutAssigned" | "OnboardingFormAvailable"
message   string    (human-readable text)
isRead    bool      (default: false)
createdAt DateTime
metadata  object?   (e.g. { workoutId } or { requestId })
```

Create notifications automatically when:
- Trainer accepts/rejects a trainer request → notify the athlete
- Trainer assigns a workout to an athlete → notify the athlete
- Trainer publishes an onboarding form → notify their athletes

---

## 7. Messaging — new endpoints (Message model already exists)

New `MessageController`:

| Method  | Route                          | Role | Description |
|---------|--------------------------------|------|-------------|
| `GET`   | `/api/message/conversations`   | Any  | Returns conversation list with last message + unread count per contact |
| `GET`   | `/api/message/{otherId}`       | Any  | Get full message thread with `otherId`. Query param: `page` |
| `POST`  | `/api/message/{recipientId}`   | Any  | Send message. Body: `{ content: string }` |
| `PATCH` | `/api/message/{otherId}/read`  | Any  | Mark all messages from `otherId` as read |

`GET /api/message/conversations` response shape (array):

```json
[
  {
    "contactId": "...",
    "contactName": "Bajnok Ádám",
    "lastMessage": "Holnap találkozunk!",
    "lastMessageTime": "2025-01-01T10:00:00Z",
    "unreadCount": 2
  }
]
```

---

## 8. Onboarding survey — new feature

New controller `OnboardingFormController`:

| Method  | Route                                       | Role    | Description |
|---------|---------------------------------------------|---------|-------------|
| `GET`   | `/api/onboarding-form/mine`                 | Trainer | Get the trainer's own form (null if none created yet) |
| `PUT`   | `/api/onboarding-form`                      | Trainer | Create or update the trainer's form |
| `GET`   | `/api/onboarding-form/responses`            | Trainer | Get all athlete responses to this trainer's form |
| `GET`   | `/api/onboarding-form/responses/{athleteId}`| Trainer | Get one athlete's response |
| `GET`   | `/api/onboarding-form/my-trainer-form`      | Athlete | Get the athlete's trainer's form |
| `POST`  | `/api/onboarding-form/submit`               | Athlete | Submit answers. Body: `{ answers: [{ questionId, answer }] }` |
| `GET`   | `/api/onboarding-form/my-response`          | Athlete | Get own previously submitted response |

New documents:

```
OnboardingForm:
  id          ObjectId
  trainerId   ObjectId
  title       string
  description string?
  questions   OnboardingQuestion[]

OnboardingQuestion:
  id      string (UUID or ObjectId)
  text    string
  type    "Text" | "MultipleChoice" | "Scale"
  options string[]?  (only for MultipleChoice)

OnboardingResponse:
  id          ObjectId
  athleteId   ObjectId
  athleteName string
  trainerId   ObjectId
  answers     [{ questionId: string, answer: string }]
  submittedAt DateTime
```

---

## 9. SignalR hubs — new feature

Add two SignalR hubs (requires `Microsoft.AspNetCore.SignalR`):

### `/hubs/chat` — `ChatHub`
- Clients connect with JWT
- When a message is sent via `POST /api/message/{recipientId}`, push to recipient:
  ```json
  // Client method name: "ReceiveMessage"
  { "id": "...", "senderId": "...", "content": "...", "timestamp": "..." }
  ```

### `/hubs/notification` — `NotificationHub`
- Clients connect with JWT
- When a notification is created, push to recipient:
  ```json
  // Client method name: "Notification"
  { "id": "...", "type": "...", "message": "...", "isRead": false, "createdAt": "..." }
  ```

Both hubs must support JWT via query string (`?access_token=...`) — standard SignalR pattern for WebSocket connections:

```csharp
options.Events = new JwtBearerEvents {
    OnMessageReceived = ctx => {
        var token = ctx.Request.Query["access_token"];
        if (!string.IsNullOrEmpty(token))
            ctx.Token = token;
        return Task.CompletedTask;
    }
};
```

Register hubs in `Program.cs`:

```csharp
app.MapHub<ChatHub>("/hubs/chat");
app.MapHub<NotificationHub>("/hubs/notification");
```

---

## Priority order

1. **Workout model fields + missing workout endpoints** — needed for the core workout flow
2. **Trainer requests** — needed for athletes to connect to trainers
3. **Notifications** — needed for real-time feedback on requests and assignments
4. **Exercise PUT** — small addition
5. **Messaging endpoints** — Message model exists, just needs the controller
6. **SignalR hubs** — add after all REST endpoints work
7. **Onboarding** — can be last
