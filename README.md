# CARPS

CARPS is a Flutter Web event-discovery and community application for attendees,
organizers, and community builders. The current delivery target is the web app,
which is designed to adapt to desktop, tablet, and mobile browser sizes.

Firebase Authentication provides sign-in, and Cloud Firestore stores profiles
and application data. The app can use the local Firebase Emulator Suite for
isolated development and testing.

## Architecture

CARPS uses an MVC-inspired presentation layer supported by a service and
repository layer:

```text
Views
  ↓ user actions / displayed state
Feature Controllers + AppController
  ↓ use-case coordination
Focused feature services (EventService, RegistrationService, etc.)
  ↓ shared domain operation modules
CarpsRepository
  ├── FirebaseCarpsRepository → Cloud Firestore
  └── MockCarpsRepository    → in-memory test data
```

- **Models** define the application's data structures and shared validation.
- **Views** render screens and capture user interaction. They do not issue
  Firestore queries or call the domain service directly.
- **Controllers** expose feature-specific actions and read models to Views.
  `AppController` owns shared application state and `AppScope` provides it to
  the widget tree. `DataController` provides read-only cached data access.
- **Services** enforce business rules. Production controllers use focused
  feature services such as `EventService`, `RegistrationService`, and
  `SocialService`. Their shared operation modules preserve common business
  rules without putting every feature in one service class. `CarpsService` is
  retained as a lazily created compatibility facade for existing domain tests;
  the production app does not instantiate it unless a test accesses it.
- **Repositories** define and implement persistence. The Firebase repository
  uses Firestore; the mock repository supports deterministic tests.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the detailed folder map and feature
flow examples, and [REFACTORING_GUIDE.md](REFACTORING_GUIDE.md) for contribution
and local validation rules.

## Source layout

```text
lib/
  main.dart
  router.dart
  controllers/
    app_controller.dart
    auth_controller.dart
    data_controller.dart
    event_controller.dart
    feed_controller.dart
    notification_controller.dart
    profile_controller.dart
    registration_controller.dart
    support_controller.dart
  models/
    carps_models.dart          Public model barrel
    carps_enums.dart
    user_profile.dart
    event_models.dart
    registration_models.dart
    social_models.dart
    notification_model.dart
    support_model.dart
    history_models.dart
    scan_result.dart
    carps_validation.dart
  repositories/
    carps_repository.dart
    firebase_carps_repository.dart
    mock_carps_repository.dart
    carps_firestore_codec.dart
  services/
    carps_service.dart         Compatibility facade for domain tests
    carps_domain_operations.dart Shared base and operation mixins
    carps_service_base.dart
    event_service.dart
    registration_service.dart
    social_service.dart
    profile_service.dart
    notification_service.dart
    account_service.dart
    support_service.dart
    event_query_operations.dart
    event_management_operations.dart
    registration_operations.dart
    social_operations.dart
    profile_operations.dart
    notification_operations.dart
    account_operations.dart
    support_operations.dart
    firebase_auth_gateway.dart
  views/
    auth/ events/ feed/ home/ notifications/
    onboarding/ profile/ settings/ shell/ demo/
  core/
    theme/ widgets/ shared utilities
  firebase/
    firebase_runtime.dart
```

## Requirements

Install the Flutter SDK compatible with the Dart constraint in `pubspec.yaml`,
then verify it is available:

```bash
flutter --version
dart --version
```

## Run the web app

Install packages:

```bash
flutter pub get
```

Run against the configured Firebase project:

```bash
flutter run -d chrome
```

The checked-in `lib/firebase_options.dart` currently contains Web Firebase
options. Native Android/iOS Firebase configuration is outside the current
web-only delivery scope and must be completed before running those native
platforms.

## Use local Firebase emulators

Start Authentication and Firestore emulators in one terminal:

```bash
npx firebase-tools emulators:start --project carps-d19cf --only auth,firestore
```

Run the web app in a second terminal:

```bash
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```

For the web target, the browser connects to the emulator ports on the same
computer: Authentication `localhost:9099` and Firestore `localhost:8080`.
Emulator accounts and data are local and separate from production data.

## Firebase setup notes

1. In Firebase Console, verify that the CARPS Web app is registered in project
   `carps-d19cf`.
2. In **Authentication → Sign-in method**, enable the providers used by the
   app (Email/Password and, if configured, Google).
3. Verify that Cloud Firestore is created in the intended region.
4. Review `firestore.rules` before deploying security-rule changes.
5. Deploy rules only after reviewing them with the team:

   ```bash
   npx firebase-tools login
   npx firebase-tools deploy --project carps-d19cf --only firestore:rules
   ```

Firestore collections and documents are created as the app writes them; there
are no SQL tables to create manually. Email/password credentials are managed by
Firebase Authentication rather than stored as profile-document passwords.

Cloud Functions are not part of the current configured deployment. Push
delivery, image uploads, and production analytics remain out of scope unless
the team explicitly implements and verifies them.

## Quality checks

Run these from the project root before opening a pull request:

```bash
dart format .
flutter analyze
flutter test
flutter build web
```

Run Firestore Security Rules tests against the local emulator:

```bash
npx firebase-tools emulators:exec --project carps-d19cf --only firestore "npm test --prefix test/firestore_rules"
```

## Team workflow

1. Create a feature or cleanup branch from the latest `main`.
2. Make one focused change at a time.
3. Run formatting, analysis, relevant tests, and the web build.
4. Review the diff and open a pull request.
5. Do not merge untested changes into `main`.
