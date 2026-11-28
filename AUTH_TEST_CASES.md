# Authentication test cases

## Prerequisites

- Run the web app with Firebase configured.
- Enable Email/Password and Google under Firebase Authentication sign-in
  providers. Add the test host (for example, `localhost`) to authorized domains.
- Use a test account or the Firebase Authentication emulator. Google provider
  tests require the configured Firebase project and a browser that permits the
  provider popup.

## Cases

| ID | Scenario | Steps | Expected result |
| --- | --- | --- | --- |
| AUTH-01 | Email sign-up | Open **Sign up**, enter a valid unused email and a password of at least 8 characters, then create the account. | Firebase creates the account and CARPS profile; the user is routed to onboarding. |
| AUTH-02 | Email sign-in | Open **Log in**, enter an existing email and correct password, then submit. | The user is signed in and routed to Home (or onboarding if setup is incomplete). |
| AUTH-03 | Email validation | Enter an invalid email or submit sign-up with a password shorter than 8 characters. | Inline validation appears and no Firebase account is created. |
| AUTH-04 | Invalid credentials | Submit an unknown email or incorrect password. | A useful authentication error is shown; the user remains on the login screen. |
| AUTH-05 | Google sign-up | Select **Continue with Google** and authorize with a Google account that has no CARPS account. | Firebase creates/signs in the account, CARPS creates its profile, and the user is routed to onboarding. |
| AUTH-06 | Google sign-in | Select **Continue with Google** and authorize with an account that already has a CARPS profile. | The existing profile is loaded and the user is routed to Home (or onboarding if incomplete). |
| AUTH-07 | Google cancellation/failure | Start Google sign-in, then close/cancel the popup or simulate a provider/network failure. | The user stays signed out on the login screen and sees an actionable error. |
| AUTH-08 | Keep signed in (enabled) | Leave **Keep me logged in** checked, sign in, reload the page, then open the app again in a later browser session. | The user remains signed in across reloads and browser sessions. |
| AUTH-09 | Keep signed in (disabled) | Uncheck **Keep me logged in**, sign in, reload the page, then end the browser session and reopen the app. | The user remains signed in during the current browser session but is signed out after that session ends. |
| AUTH-10 | Google persistence choice | Repeat AUTH-05 or AUTH-06 once with the checkbox enabled and once disabled. | The Google account follows the same persistence behavior as email authentication. |
| AUTH-11 | Sign out | Sign in, choose **Sign out** in Settings, then reload the app. | The app returns to login and does not restore the signed-out account. |

## Mobile authentication checks

Run Firebase-backed cases on a physical Android or iOS device after configuring
the native app registrations with FlutterFire. Do not pass
`USE_MOCK_DATA=true` for Firebase cases; that mode intentionally bypasses
Firebase.

| ID | Scenario | Steps | Expected result |
| --- | --- | --- | --- |
| MOBILE-AUTH-01 | Missing native Firebase setup | Build without mock mode before Android/iOS options are configured. | A setup notice explains that native Firebase apps must be configured; the app does not silently start as a demo user. |
| MOBILE-AUTH-02 | Explicit mock mode | Build with `--dart-define=USE_MOCK_DATA=true`. | A **LOCAL DEMO** banner is visible and the app starts signed out. Demo controls may switch to sample users; no Firebase account is used. |
| MOBILE-AUTH-03 | Email sign-up | Build without mock mode; sign up with an unused email and valid password. | Firebase creates the account, loads/creates its profile, and opens onboarding. |
| MOBILE-AUTH-04 | Email sign-in | Sign out, then sign in with the account created in MOBILE-AUTH-03. | Firebase authenticates the account and opens Home or unfinished onboarding; the user is not automatically Mika. |
| MOBILE-AUTH-05 | Invalid credentials | Submit a wrong password, then submit the correct password. | The first attempt displays an error without signing in; the second authenticates normally. |
| MOBILE-AUTH-06 | Session restore | Enable **Keep me logged in**, sign in, close and relaunch the app. Then sign out and relaunch. | Firebase restores the first session; the explicitly signed-out session stays signed out. |
| MOBILE-AUTH-07 | Google provider | Use **Continue with Google** for new and existing accounts. | Native Firebase Google sign-in returns the correct account; no mock user is selected. |
| MOBILE-AUTH-08 | Network failure | Disable network and submit email sign-in, then restore network and retry. | The failed request shows an error without demo fallback; retry succeeds once online. |

## Refresh and live notification checks

| ID | Scenario | Steps | Expected result |
| --- | --- | --- | --- |
| LIVE-NOTIF-01 | New join request | Keep the host signed in with the app open. From another account, request to join the host's event. | The host's in-app notification list updates without a manual refresh. |
| LIVE-NOTIF-02 | Request decision | Keep the requester signed in with the app open, then approve or decline the request from the host account. | The requester's in-app notification list updates without a manual refresh. |
| LIVE-NOTIF-03 | App backgrounded | Background or close the recipient app before another user creates a notification. | No operating-system alert is expected; the notification appears in the in-app list after reopening. |
| REFRESH-01 | Web reload | Sign in on the web and reload the page with a typical account and event dataset. | The app restores the session and finishes its parallel Firestore data load without a long serial wait. |
