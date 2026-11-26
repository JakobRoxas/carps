Carps is a cross-platform event discovery and community app for attendees,
organizers, and community builders.

As of 11/19/2026 we don't have a database yet so for testing and development
we will be working with data that is stored in memory. So all of this is in
'lib/repositories'.

This README is the team guide for building the project. Work is divided into
three areas: **frontend**, **backend**, and **database**.

## Features

Basically right now I'm going to delimit our scope to:

- Personalized event feed with recommendation and social-proof sections
- Event discovery with text search and category filters
- Event details with RSVP state and a conversation starter
- Group hubs with follow/unfollow behavior
- Profile, interests, and RSVP entry points

Yung mga nasa 'Screens' section I think it's good to have those screens
just for the sake of having them done, but things like authentication
we'll just implement later on (Authentication, persistence, media uploads,
notifications, analytics, and moderation). 

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

Si jakob lang toh #onemanarmy

**Primary responsibilities**

- Kumbaga pre ung API haha.
- Ung nasa api-test-client folder that's just for me to test the api i'm working on
  kase mas trip ko gumagamit ng html for making the temporary UI.

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
`lib/services/carps_service.dart`. Swap the repository for Firebase later; widgets
and rules don't change.

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

The app should remain runnable with mock data while backend work is in
progress. Do not commit local credentials, service-account files, or
machine-specific configuration. Kung may kinemerut kayo, lagay niyo
nalang sa .env then make sure nasa .gitignore