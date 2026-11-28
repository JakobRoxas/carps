# CARPS Architecture Guide

## 1. Architectural approach

CARPS uses an **MVC-inspired, layered architecture**. Views, controllers, and
models form the presentation/domain boundary; focused services hold business
rules, and repositories isolate persistence.

This is not textbook MVC without additional layers. The service and repository
layers are deliberate additions: controllers coordinate user actions, services
validate and execute use cases, and repositories persist data.

```text
┌────────────────────────────────────────────────┐
│ VIEW                                           │
│ lib/views/** and lib/core/widgets/**            │
│ Render UI and collect user interaction         │
└───────────────────────┬────────────────────────┘
                        │ calls controller actions / reads state
┌───────────────────────▼────────────────────────┐
│ CONTROLLERS                                    │
│ AppController + feature controllers            │
│ Coordinate presentation actions and app state │
└───────────────────────┬────────────────────────┘
                        │ invokes focused use cases
┌───────────────────────▼────────────────────────┐
│ FEATURE SERVICES                               │
│ EventService, RegistrationService,             │
│ SocialService, ProfileService, etc.            │
│ Enforce business rules                         │
└───────────────────────┬────────────────────────┘
                        │ read / write through contract
┌───────────────────────▼────────────────────────┐
│ REPOSITORY                                     │
│ CarpsRepository                                │
│ FirebaseCarpsRepository / MockCarpsRepository │
└───────────────────────┬────────────────────────┘
                        │
                Cloud Firestore / test data
```

## 2. Responsibilities by layer

### Models — `lib/models/`

Models define the domain data used by CARPS: users, events, registrations,
invitations, passes, attendance, posts, reviews, notifications, support cases,
and history entries. Related models are grouped in focused files.
`carps_models.dart` is the public export barrel so feature code can import the
shared types from one stable location. `CarpsValidation` contains reusable
validation rules, and `ScanResult` is a value object returned by pass scanning.

### Views — `lib/views/` and `lib/core/widgets/`

Views render screens, collect form input, and present success/error/empty
states. They access shared state through `context.app` / `context.appRead` and
call feature controllers such as `app.events`, `app.registrations`, and
`app.feed`.

Views and reusable UI widgets must not instantiate Firebase clients, issue
Firestore queries, or call feature services/repositories directly.

### Controllers — `lib/controllers/`

- `AppController`: shared signed-in user/session state, service/controller
  composition, and repository change notifications.
- `AuthController`: sign-in, sign-up, Google sign-in, password recovery, and
  translation of Firebase errors into application errors.
- `DataController`: read-only access to cached repository records for view
  presentation.
- `EventController`: event discovery, details, creation, editing, invitations,
  and event-level coordination across registration/social use cases.
- `RegistrationController`: RSVP decisions, passes, attendance, and scanning.
- `FeedController`: feed queries, posts, tags, likes, comments, and reviews.
- `ProfileController`: profile updates, hosting setup, follows, profile stats,
  and history.
- `NotificationController`: inbox queries and read state.
- `SupportController`: reports and admin support-case workflows.

Controllers are the UI-facing API. They translate screen actions into calls to
focused feature services and expose application models/results to Views.
`AppScope` makes the `AppController` available through the widget tree.

### Services — `lib/services/`

Production controllers use focused service classes:

| Service | Main responsibility |
|---|---|
| `EventService` | Event queries, visibility/discovery, event creation/editing, invitations and host notices |
| `RegistrationService` | RSVP eligibility, approvals, guest passes, scanning and attendance |
| `SocialService` | Feed queries, posts, comments, likes, tags and reviews |
| `ProfileService` | Following, profile feeds/stats, hosting setup, account-profile updates and history |
| `NotificationService` | Notification creation, inbox queries, unread counts and read state |
| `AccountService` | Local/mock account operations and account validation |
| `SupportService` | Support reporting, assignment and case resolution |

The feature services share reusable operation mixins in
`carps_domain_operations.dart` and the `*_operations.dart` modules. Some
services compose additional operation mixins when a use case depends on shared
rules from another domain (for example, social posting checks attendance).
Each feature service is a separate instance backed by the same repository and
clock, rather than a single 1,200-line service object.

`CarpsService` is retained as an aggregate compatibility facade for existing
domain tests during migration. `AppController.service` creates that facade
lazily; the production feature controllers do not depend on or instantiate
it.

`FirebaseAuthGateway` isolates Firebase Authentication SDK calls from Views.
`AuthController` exposes application-level operations and errors to the UI.

### Repositories — `lib/repositories/`

`CarpsRepository` is the persistence contract. `FirebaseCarpsRepository`
implements it using Cloud Firestore and maintains the app's local read cache.
`MockCarpsRepository` provides seeded in-memory data for tests.
`CarpsFirestoreCodec` maps CARPS models to and from Firestore documents.

Firestore Security Rules remain the authorization boundary. Client-side
validation improves the user experience but does not replace server-side rules.

## 3. Dependency setup

`main.dart` initializes Firebase, creates Authentication and Firestore
instances, optionally connects them to local emulators, constructs the Firebase
repository and authentication gateway, and injects them into `AppController`.
`AppController` creates focused feature services and their corresponding
controllers using the same repository and clock. `CarpsApp` installs `AppScope`,
`MaterialApp.router`, the theme, and GoRouter configuration.

## 4. Example feature flow — RSVP

```text
EventDetailView
    │ user taps “Request to join”
    ▼
EventController
    │ delegates RSVP use case
    ▼
RegistrationService
    │ checks eligibility and registration rules
    ▼
CarpsRepository
    │ saveRegistration(...)
    ▼
FirebaseCarpsRepository
    │ writes registration document
    ▼
Cloud Firestore
```

The repository notifies listeners after its cache changes. `AppController`
forwards those notifications through `AppScope`, allowing affected widgets to
rebuild and display the latest state.

## 5. Rules for future changes

1. A View calls a feature Controller; it does not call a Service or Repository.
2. A Controller coordinates a user-facing action; it does not contain Firestore
   query implementation or duplicate domain validation rules.
3. A Service owns business rules and decides whether an operation is allowed.
4. A Repository owns persistence and serialization boundaries, not UI logic.
5. Models describe data and value objects; they do not contain Flutter widgets.
6. Add or update a test for each business-rule change.
7. Before merging, run `dart format .`, `flutter analyze`, `flutter test`, and
   `flutter build web`.
8. Keep service-account private keys and other genuine secrets out of client
   source code and Git.

## 6. Current limitations to describe honestly

- The checked-in Firebase options currently target Web. Native Android/iOS
  Firebase setup is not included in the current web delivery scope.
- The demo panel is a testing aid and is disabled in the normal `main()` launch.
- The notification email flag describes simulated email behavior; it is not
  proof that email delivery is implemented.
- The current pass scanner uses a simulated pass selection/input flow, not a
  hardware camera integration.
- Cloud Functions, push delivery, and image uploads are not part of the current
  configured deployment.
