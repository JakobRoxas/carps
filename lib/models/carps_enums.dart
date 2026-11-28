// Shared CARPS enums.

enum EventVisibility { public, private }

enum PrimaryRole { attendee, builder }

enum EventStatus { published, cancelled }

/// A join request for one guest at one event. This is THE registration record
/// both the guest and the hosting team look at.
enum RegistrationStatus { pending, approved, declined, withdrawn }

enum InvitationKind { guest, coHost }

enum InvitationStatus { sent, accepted, declined }

enum ScanOutcome {
  checkedIn,
  alreadyCheckedIn,
  wrongEvent,
  invalid,
  withdrawn,
  notAuthorized,
  outsideWindow,
}

enum NotificationKind {
  joinRequest,
  approved,
  declined,
  guestInvite,
  coHostInvite,
  coHostAccepted,
  notice,
  reminder,
  checkedIn,
  tagged,
  comment,
  cancelled,
  supportUpdate,
  supportAssigned,
}

enum CaseStatus { open, closed }

enum CaseOutcome { noAction, removedPost, warnedUser, attendanceCorrected }
