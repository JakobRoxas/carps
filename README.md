Carps is a cross-platform event discovery and community app for attendees,
organizers, and community builders.

The app defaults to seeded in-memory data for demos and tests. An opt-in Firebase
backend uses Firebase Authentication, callable Cloud Functions, and Cloud
Firestore.

This README is the team guide for building the project. Work is divided into
three areas: **frontend**, **backend**, and **database**.

## Features

Basically right now I'm going to delimit our scope to:

- Personalized event feed with recommendation and social-proof sections
- Event discovery with text search and category filters
- Event details with RSVP state and a conversation starter
- Group hubs with follow/unfollow behavior
- Profile, interests, and RSVP entry points

The login, sign-up, and password-reset screens use Firebase Authentication
when the Firebase backend is enabled; the default demo mode still uses mock
accounts. Media uploads, push notifications, analytics, and moderation
workflows remain future work.

## Screens

Here are the screens we'll need to have (I think, just add more if needed sa mga in charge sa UI):

- Login + Sign Up
- Main "FYP"
- Yung event page + the social features here:
  - Being able to indicate interest in the event
  - Following the group/community who made/are associated with this event
  - Forum for the event
- User Profile
- Community/Group Page; kumbaga parang professional FB page
- Settings


## Repository layout

```text
lib/
  main.dart                         App entry point and app-wide setup
  models/                           Shared domain models and value objects
  controllers/                      UI-facing state and user actions
  repositories/                     Data access interfaces and implementations
  views/                            Screens and widgets
```

Platform folders (`android/`, `ios/`, and `web/`) contain Flutter platform
configuration. Avoid changing them unless the feature needs platform-specific
behavior.

## Team responsibilities

### Frontend team

User experience and Flutter presentation layer.

**Primary responsibilities**

- Build screens, widgets, navigation, loading states, empty states, and errors.
- Keep UI state in controllers and presentation logic out of repositories.
- Use the shared models in `lib/models/`.
- Call repositories through controllers instead of embedding data access in
  widgets.
- Add responsive behavior for mobile and web.
- Add or update widget tests for user-visible behavior.

### Backend

The Firebase callable functions in `functions/` are the trusted server
boundary. Keep authorization and state-changing product rules on the server;
the Flutter service checks are for user experience and are not a security
boundary.

**Primary responsibilities**

- Maintain callable functions that validate authenticated users and enforce
  event, registration, pass, attendance, post, review, and support rules.
- Keep Firestore client access denied by default; clients must go through the
  callable functions.
- Add tests for allowed and rejected operations, especially private-event
  access and attendance/pass transitions.
- Deploy functions and rules together when a change depends on both.

### Database

- Design tables/collections for users, events, groups, RSVPs, follows, and
  other agreed features.
- Define relationships, constraints, indexes, and retention requirements.
- Create versioned migrations and a way to roll them back when practical.
- Provide seed data for local development and test fixtures for automated tests.
- Protect sensitive data and document access rules.
- Review backend queries for correctness and performance.

**Database rules**

- Every schema change must have a migration; do not edit production data
  manually.
- Use stable identifiers and explicit timestamps.
- Add constraints for invariants that must always hold.
- Keep secrets and connection strings out of the repository.
- Coordinate breaking schema changes with a backend migration plan.

## Workflow

- Maglagay lang kayo ng commit msg haha

## Frontend demo (mock data)

The app runs fully on an in-memory mock (`lib/repositories/mock_carps_repository.dart`)
behind the `CarpsRepository` interface, with all product rules in
`lib/services/carps_service.dart`. Firebase is opt-in; the mock remains the
default so screenshots and tests don't require a network or Firebase account.

```bash
flutter run -d chrome          # responsive web
flutter run -d <android-device> # Android
```

Demo accounts use `<username>@example.com` / `carps123` (e.g. `anareyes@example.com`),
or use the purple **DEMO** tab to switch users, simulate a pass scan, end an event,
or force a failed lookup. Seeded roles: `mikacruz` (builder/host), `anareyes`
(guest who checks in), `sofiasantos` (checked-in peer), `paolotan` (approved
no-show), `marcolim` (gets declined), `beavalenzuela` (outsider who follows Mika),
`davidlim` (second builder), `sambautista` (assigned admin).

The older `event_model`, `user_model`, `group_model`, `social_model`, `event_repository`,
`group_repository` and `*_controller` files from the backend smoke test are kept but
unused: they treat an RSVP as attendance, which the current product definition forbids.

## Firebase backend

The Firebase implementation keeps the existing view/controller interface. The
Flutter app caches domain models locally; reads and writes go through the
callable functions. Server-side validation remains authoritative. Failed
background writes are shown in the app rather than silently discarded.

### Run against the local emulators

Install the Firebase CLI and Functions dependencies once:

```bash
npm install -g firebase-tools
firebase login
npm --prefix functions install
```

Start the Auth, Firestore, and Functions emulators from the repository root:

```bash
firebase emulators:start --project demo-carps --only auth,firestore,functions
```

In another terminal, launch the Flutter web app against those emulators:

```bash
flutter run -d chrome \
  --dart-define=CARPS_USE_FIREBASE=true \
  --dart-define=CARPS_USE_FIREBASE_EMULATORS=true
```

For Android emulators, the app uses `10.0.2.2` to reach the host machine. iOS
simulators and web use `localhost`.

### Connect a Firebase project

1. Create a Firebase project and a Cloud Firestore database. Choose a database
   region before creating it; `asia-southeast1` (Singapore) is the configured
   Cloud Functions region.
2. Enable **Email/Password** and **Google** providers in Firebase
   Authentication. Configure the OAuth client for Google sign-in.
3. Register a web, Android, and/or iOS app in Firebase Console. Pass its public
   SDK settings as the `FIREBASE_*` Dart defines used by
   `lib/firebase/firebase_runtime.dart` (use the platform-specific app ID for
   each build). Firebase client API keys are not authorization; do not put
   service-account keys or other secrets in the app.
4. Deploy the server functions and deny-by-default Firestore rules:

   ```bash
   firebase deploy --project YOUR_PROJECT_ID --only functions,firestore:rules
   ```

5. Run the app with `CARPS_USE_FIREBASE=true` and the matching Firebase app
   settings. Do not set `CARPS_USE_FIREBASE_EMULATORS=true` when using the live
   project.

New accounts are regular users. The app cannot grant admin access: provision an
admin profile through a trusted, auditable Admin SDK process after the account
has been created. Never expose service-account credentials or let a client set
the `isAdmin` field. At least one admin profile is needed to assign and resolve
support cases.

For example, a web build uses the app's public web configuration:

```bash
flutter run -d chrome \
  --dart-define=CARPS_USE_FIREBASE=true \
  --dart-define=FIREBASE_API_KEY=YOUR_WEB_API_KEY \
  --dart-define=FIREBASE_WEB_APP_ID=YOUR_WEB_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

For Android or iOS, use `FIREBASE_ANDROID_APP_ID` or `FIREBASE_IOS_APP_ID`
instead of the web app ID. Additional platform client IDs may be supplied for
Google sign-in.

Deploying Cloud Functions may require enabling the Firebase Blaze billing
plan. Test changes with the local emulators before deploying.

## Local development

Install dependencies and run the Flutter app:

```bash
flutter pub get
flutter run
```

Run the test suite:

```bash
flutter test
```

Check formatting and static analysis before opening a pull request:

```bash
dart format .
flutter analyze
```

The app should remain runnable with mock data while backend work is in progress.
Do not commit service-account files, passwords, or machine-specific
configuration. Public Firebase client settings are not secrets; authorization
must come from Authentication and server-side validation.