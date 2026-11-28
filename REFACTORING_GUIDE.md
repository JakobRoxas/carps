# CARPS Refactoring Guide

## What changed

This refactor makes the active Flutter Web app use feature-specific controllers
and feature-specific domain services. It does not delete the existing business
rules; it moves them into smaller modules and gives each feature a focused
service API.

## Runtime request path

```text
View
  → AppScope / AppController
  → feature Controller
  → feature Service
  → CarpsRepository interface
  → FirebaseCarpsRepository
  → Cloud Firestore
```

For tests, the same controllers can be backed by `MockCarpsRepository`.

## Feature ownership

| Feature | Controller | Service |
|---|---|---|
| Authentication | `AuthController` | `AccountService` + `FirebaseAuthGateway` |
| Events | `EventController` | `EventService` |
| RSVP / passes / attendance | `RegistrationController` | `RegistrationService` |
| Feed / posts / comments / reviews | `FeedController` | `SocialService` |
| Profiles / follows / history | `ProfileController` | `ProfileService` |
| Notifications | `NotificationController` | `NotificationService` |
| Support / moderation | `SupportController` | `SupportService` |
| Cached read models for screens | `DataController` | `CarpsRepository` interface |

`EventController` also coordinates event detail workflows that cross event,
registration, and social domains; it delegates each operation to the matching
service rather than owning the business rule itself.

## Why operation modules still exist

Some business rules are shared. For example, approving a registration also
creates a notification, and social posting eligibility depends on attendance.
The `*_operations.dart` files hold those rule implementations once. The
feature service classes compose the operation modules they need. This avoids
copying the same rules into several services.

`CarpsService` is a compatibility facade used by older domain tests. The
production feature controllers use the focused feature service classes. The
facade is lazily created only when legacy tests access `AppController.service`.

## Rules for future edits

1. Views call `app.events`, `app.registrations`, `app.feed`, `app.profiles`,
   `app.notifications`, `app.support`, `app.auth`, or `app.data`.
2. Do not import Firebase SDKs or repository implementations from a View.
3. Put presentation coordination in the feature controller.
4. Put business validation and domain decisions in a feature service.
5. Put Firestore reads/writes and serialization in repository implementations.
6. Keep shared data structures in `lib/models/`; add exports to
   `carps_models.dart` when a new model file is introduced.
7. Keep the mock repository behavior aligned with the Firebase repository.
8. Add or update tests whenever behavior changes.

## Validate locally (Windows PowerShell)

Run from the CARPS project root:

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter build web
```

For local Web development with Firebase emulators, use two terminals.

Terminal 1:

```powershell
npx firebase-tools emulators:start --project carps-d19cf --only auth,firestore
```

Terminal 2:

```powershell
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```

Test both successful and unsuccessful paths: sign in, sign up, event creation,
RSVP request and approval, pass/attendance, feed post and comments, profile
updates, notifications, support reporting, invalid input, and disconnected
emulator behavior.

**Important:** this refactoring workspace did not have the Flutter/Dart SDK
available, so no Flutter analyzer, widget-test, or Web-build success is claimed.
Run the commands above on the development machine and fix any output before
committing or merging.
