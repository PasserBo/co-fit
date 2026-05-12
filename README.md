# CoFit

Event-first social fitness MVP built with Flutter, Firebase Auth, and Ably.

## Fast MVP Scope

- Login/register with Firebase Auth
- Join a room by `roomId`
- Show online members via Ably Presence
- Send and receive action events (`started`, `paused`, `resumed`, `completed`)
- No manual animation integration in this phase

## One-time Manual Setup

### 1) Firebase

1. Open Firebase console and select this project.
2. In Authentication -> Sign-in method, enable:
   - Email/Password
   - (Optional fallback) Anonymous
3. Ensure iOS app config file `ios/Runner/GoogleService-Info.plist` is present.

### 2) Ably

1. Create an Ably app in the Ably dashboard.
2. Create a development API key.
3. Channel naming convention for this MVP:
   - `room:{roomId}:events`
4. Presence identity convention:
   - Firebase UID (or `anon_{uid}` for anonymous users)

## Run Locally

Use `--dart-define` to inject Ably runtime settings:

```bash
flutter pub get
flutter run \
  --dart-define=ABLY_API_KEY=your_ably_api_key \
  --dart-define=ABLY_CLIENT_ID_PREFIX=cofit
```

Notes:
- Never commit production secrets.
- For local development, dev keys are acceptable.
- `ABLY_CLIENT_ID_PREFIX` is optional and can help distinguish environments.

## Event Envelope (MVP)

Every action event should include:

- `eventId`
- `roomId`
- `userId`
- `type` (`action_started`, `action_paused`, `action_resumed`, `action_completed`)
- `timestamp` (ISO-8601)
- `payload` (action-specific metadata such as `actionKey`, `durationSec`, `remainingSec`)
