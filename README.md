Carps is a cross-platform event discovery and community app for attendees,
organizers, and community builders.

Firebase Authentication provides sign-in, and Cloud Firestore stores CARPS
profiles and app data. Tests use seeded in-memory fixtures.

This README is the team guide for building the project. Work is divided into
three areas: **frontend**, **backend**, and **database**.

## Planned features

Basically right now I'm going to delimit our scope to:

- Personalized event feed with recommendation and social-proof sections
- Event discovery with text search and category filters
- Event details with RSVP state and a conversation starter
- Group hubs with follow/unfollow behavior
- Profile, interests, and RSVP entry points

The login, sign-up, and password-reset screens use Firebase Authentication.
Image uploads, push delivery, and analytics remain future work.

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

The app uses Firebase Authentication and direct Cloud Firestore access. The
Flutter repository caches accessible records for the existing synchronous
business-rule service, then writes changes to Firestore. Firestore Security
Rules restrict reads and writes by account, event team, and attendance.

Direct Firestore avoids Cloud Functions and a Blaze upgrade, but it does not
provide a trusted server for every workflow. Critical changes must be
constrained by Firestore Rules, and backend-only services such as push delivery
are not included.

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

## Firebase setup

The app is configured for the Firebase project `carps-d19cf` (Web). Before
running it:

1. In Firebase Console, open **Build → Firestore Database → Create database**.
   Choose Production mode and select the database location carefully; the
   location cannot be changed later.
2. In **Authentication → Sign-in method**, enable the providers you want to
   offer (Email/Password and Google).
3. Install/use the Firebase CLI, sign in, and deploy the checked-in rules:

   ```bash
   npx firebase-tools login
   npx firebase-tools deploy --project carps-d19cf --only firestore:rules
   ```

The app supports email/password sign-up, login, Google sign-in, password reset,
and sign-out. Firebase options are currently configured for Web; run
FlutterFire configuration before using Android or iOS.

```bash
flutter run -d chrome
```

Firestore creates collections and documents as the app writes them; there are
no SQL tables to create manually. Profiles and username reservations live in
`profiles` and `usernames`; events, invitations, event access, registrations,
registration notes, passes, attendance, posts, reviews, notifications, and
support cases are stored in their corresponding collections. Registration notes
are private to the attendee and event team. Email addresses are kept in Firebase
Authentication, not in public profile documents.

Existing Firebase Auth accounts without a `profiles/{uid}` document will need
to complete CARPS onboarding once. After the profile is saved, onboarding
progress persists across sign-ins.

Cloud Firestore has a free quota, but usage beyond the free limits may incur
charges. Cloud Functions are not deployed or required by this setup.

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