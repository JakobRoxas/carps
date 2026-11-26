// CARPS domain models.
//
// These are plain immutable records. Business rules (who may see, request,
// approve, scan, post or review) live in `services/carps_service.dart`, and
// storage lives behind `repositories/carps_repository.dart`, so a Firebase
// implementation can replace the mock without touching widgets.
//
// NOTE: The older `event_model.dart`, `user_model.dart`, `group_model.dart`
// and `social_model.dart` files are the team's earlier smoke-test models and
// are not used by this app. They model RSVP as attendance and unlinked forum
// posts, which the current product definition no longer allows.

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

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.email,
    this.password = 'carps123',
    this.avatarAsset,
    this.bio = '',
    this.area,
    this.interests = const [],
    this.followingIds = const [],
    this.hostingEnabled = false,
    this.builderName,
    this.builderAbout,
    this.isAdmin = false,
    this.termsAccepted = false,
    this.primaryRole,
    this.profileComplete = false,
    this.discoveryDone = false,
    this.contactDiscoveryOptIn = false,
  });

  final String id;
  final String displayName;
  final String username;
  final String email;

  /// Mock credential only. Real auth is out of scope for this frontend.
  final String password;
  final String? avatarAsset;
  final String bio;
  final String? area;
  final List<String> interests;

  /// Builder accounts this user follows. Never touches registrations.
  final List<String> followingIds;

  /// Hosting tools enabled on this same account (no second account).
  final bool hostingEnabled;
  final String? builderName;
  final String? builderAbout;

  /// Assigned permission. Never selectable during onboarding.
  final bool isAdmin;

  final bool termsAccepted;
  final PrimaryRole? primaryRole;
  final bool profileComplete;
  final bool discoveryDone;
  final bool contactDiscoveryOptIn;

  bool get onboardingComplete =>
      termsAccepted && primaryRole != null && profileComplete && discoveryDone;

  String get handle => '@$username';

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? avatarAsset,
    bool clearAvatar = false,
    String? bio,
    String? area,
    List<String>? interests,
    List<String>? followingIds,
    bool? hostingEnabled,
    String? builderName,
    String? builderAbout,
    bool? termsAccepted,
    PrimaryRole? primaryRole,
    bool? profileComplete,
    bool? discoveryDone,
    bool? contactDiscoveryOptIn,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email,
      password: password,
      avatarAsset: clearAvatar ? null : (avatarAsset ?? this.avatarAsset),
      bio: bio ?? this.bio,
      area: area ?? this.area,
      interests: interests ?? this.interests,
      followingIds: followingIds ?? this.followingIds,
      hostingEnabled: hostingEnabled ?? this.hostingEnabled,
      builderName: builderName ?? this.builderName,
      builderAbout: builderAbout ?? this.builderAbout,
      isAdmin: isAdmin,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      primaryRole: primaryRole ?? this.primaryRole,
      profileComplete: profileComplete ?? this.profileComplete,
      discoveryDone: discoveryDone ?? this.discoveryDone,
      contactDiscoveryOptIn:
          contactDiscoveryOptIn ?? this.contactDiscoveryOptIn,
    );
  }
}

class EventNotice {
  const EventNotice({
    required this.id,
    required this.text,
    required this.createdAt,
    this.isVenueChange = false,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final bool isVenueChange;
}

/// A registered CARPS event. An upcoming listing is NOT a social post.
class CarpsEvent {
  const CarpsEvent({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.topic,
    required this.venue,
    required this.area,
    required this.start,
    required this.end,
    required this.visibility,
    this.coverAsset,
    this.coHostIds = const [],
    this.capacity,
    this.featuredOnProfile = false,
    this.status = EventStatus.published,
    this.notices = const [],
    this.seriesLabel,
  });

  final String id;
  final String hostId;

  /// Co-hosts who ACCEPTED. Pending co-host invitations live in invitations.
  final List<String> coHostIds;
  final String title;
  final String description;
  final String topic;
  final String venue;
  final String area;
  final DateTime start;
  final DateTime end;
  final EventVisibility visibility;
  final String? coverAsset;
  final int? capacity;
  final bool featuredOnProfile;
  final EventStatus status;
  final List<EventNotice> notices;

  /// e.g. "Sunday open play" so recurring sessions stay distinguishable.
  final String? seriesLabel;

  bool get isPrivate => visibility == EventVisibility.private;
  bool get isCancelled => status == EventStatus.cancelled;
  bool isEnded(DateTime now) => !now.isBefore(end);
  bool isUpcoming(DateTime now) => now.isBefore(start);
  bool isLive(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  bool isHostingTeam(String userId) =>
      hostId == userId || coHostIds.contains(userId);

  CarpsEvent copyWith({
    List<String>? coHostIds,
    String? title,
    String? description,
    String? topic,
    String? venue,
    String? area,
    DateTime? start,
    DateTime? end,
    EventVisibility? visibility,
    String? coverAsset,
    int? capacity,
    bool? featuredOnProfile,
    EventStatus? status,
    List<EventNotice>? notices,
  }) {
    return CarpsEvent(
      id: id,
      hostId: hostId,
      coHostIds: coHostIds ?? this.coHostIds,
      title: title ?? this.title,
      description: description ?? this.description,
      topic: topic ?? this.topic,
      venue: venue ?? this.venue,
      area: area ?? this.area,
      start: start ?? this.start,
      end: end ?? this.end,
      visibility: visibility ?? this.visibility,
      coverAsset: coverAsset ?? this.coverAsset,
      capacity: capacity ?? this.capacity,
      featuredOnProfile: featuredOnProfile ?? this.featuredOnProfile,
      status: status ?? this.status,
      notices: notices ?? this.notices,
      seriesLabel: seriesLabel,
    );
  }
}

class Invitation {
  const Invitation({
    required this.id,
    required this.eventId,
    required this.inviteeId,
    required this.invitedById,
    required this.kind,
    required this.createdAt,
    this.status = InvitationStatus.sent,
  });

  final String id;
  final String eventId;
  final String inviteeId;
  final String invitedById;
  final InvitationKind kind;
  final InvitationStatus status;
  final DateTime createdAt;

  Invitation copyWith({InvitationStatus? status}) => Invitation(
        id: id,
        eventId: eventId,
        inviteeId: inviteeId,
        invitedById: invitedById,
        kind: kind,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}

class Registration {
  const Registration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.note = '',
    this.decidedAt,
    this.passId,
  });

  final String id;
  final String eventId;
  final String userId;
  final RegistrationStatus status;
  final DateTime requestedAt;
  final String note;
  final DateTime? decidedAt;

  /// Only set once a hosting-team member approves the request.
  final String? passId;

  bool get isActive =>
      status == RegistrationStatus.pending ||
      status == RegistrationStatus.approved;

  Registration copyWith({
    RegistrationStatus? status,
    DateTime? decidedAt,
    String? passId,
  }) =>
      Registration(
        id: id,
        eventId: eventId,
        userId: userId,
        status: status ?? this.status,
        requestedAt: requestedAt,
        note: note,
        decidedAt: decidedAt ?? this.decidedAt,
        passId: passId ?? this.passId,
      );
}

/// A unique QR pass for one guest at one event.
class GuestPass {
  const GuestPass({
    required this.id,
    required this.token,
    required this.eventId,
    required this.userId,
    required this.registrationId,
    required this.issuedAt,
    this.revoked = false,
  });

  final String id;

  /// What the QR code encodes. Unique per guest and event.
  final String token;
  final String eventId;
  final String userId;
  final String registrationId;
  final DateTime issuedAt;
  final bool revoked;

  GuestPass revoke() => GuestPass(
        id: id,
        token: token,
        eventId: eventId,
        userId: userId,
        registrationId: registrationId,
        issuedAt: issuedAt,
        revoked: true,
      );
}

/// Proof of presence, created only by a valid first scan.
class Attendance {
  const Attendance({
    required this.eventId,
    required this.userId,
    required this.arrivedAt,
    required this.scannedById,
    this.passId,
  });

  final String eventId;
  final String userId;
  final DateTime arrivedAt;
  final String scannedById;
  final String? passId;
}

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.parentId,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;

  /// Set for threaded replies.
  final String? parentId;
}

/// One experience post. The SAME record backs the event's Experiences tab,
/// the author's Posts tab and each tagged person's Tagged tab.
class ExperiencePost {
  const ExperiencePost({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.photoAsset,
    this.taggedIds = const [],
    this.likedByIds = const [],
    this.comments = const [],
  });

  final String id;
  final String eventId;
  final String authorId;

  /// Text, or the caption when a photo is attached.
  final String body;
  final String? photoAsset;
  final List<String> taggedIds;
  final List<String> likedByIds;
  final List<PostComment> comments;
  final DateTime createdAt;

  ExperiencePost copyWith({
    List<String>? taggedIds,
    List<String>? likedByIds,
    List<PostComment>? comments,
  }) =>
      ExperiencePost(
        id: id,
        eventId: eventId,
        authorId: authorId,
        body: body,
        photoAsset: photoAsset,
        createdAt: createdAt,
        taggedIds: taggedIds ?? this.taggedIds,
        likedByIds: likedByIds ?? this.likedByIds,
        comments: comments ?? this.comments,
      );
}

/// Post-event rating/review. Separate from posts on purpose.
class EventReview {
  const EventReview({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String authorId;
  final int rating;
  final String text;
  final DateTime createdAt;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.eventId,
    this.postId,
    this.caseId,
    this.read = false,
    this.emailSimulated = false,
  });

  final String id;
  final String userId;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? eventId;
  final String? postId;
  final String? caseId;
  final bool read;

  /// True when an opted-in email copy WOULD have been sent. Nothing is sent.
  final bool emailSimulated;

  AppNotification markRead() => AppNotification(
        id: id,
        userId: userId,
        kind: kind,
        title: title,
        body: body,
        createdAt: createdAt,
        eventId: eventId,
        postId: postId,
        caseId: caseId,
        read: true,
        emailSimulated: emailSimulated,
      );
}

/// Settings → Help issue report, routed to an assigned admin.
class SupportCase {
  const SupportCase({
    required this.id,
    required this.reporterId,
    required this.category,
    required this.details,
    required this.createdAt,
    required this.assignedAdminId,
    this.link,
    this.status = CaseStatus.open,
    this.outcome,
    this.decisionNote,
    this.closedAt,
    this.hostConfirmed = false,
  });

  final String id;
  final String reporterId;
  final String category;
  final String details;
  final String? link;
  final DateTime createdAt;
  final String assignedAdminId;
  final CaseStatus status;
  final CaseOutcome? outcome;
  final String? decisionNote;
  final DateTime? closedAt;

  /// For attendance discrepancies: confirmed with the host before acting.
  final bool hostConfirmed;

  SupportCase close({
    required CaseOutcome outcome,
    required String note,
    required DateTime at,
    bool hostConfirmed = false,
  }) =>
      SupportCase(
        id: id,
        reporterId: reporterId,
        category: category,
        details: details,
        link: link,
        createdAt: createdAt,
        assignedAdminId: assignedAdminId,
        status: CaseStatus.closed,
        outcome: outcome,
        decisionNote: note,
        closedAt: at,
        hostConfirmed: hostConfirmed,
      );
}

/// Per-guest attendance history entry (distinguishes bookings from arrivals).
enum HistoryState { checkedIn, noShow, booked, cancelled }

class HistoryEntry {
  const HistoryEntry({
    required this.event,
    required this.state,
    this.arrivedAt,
    this.canPost = false,
    this.canReview = false,
    this.hasReviewed = false,
  });

  final CarpsEvent event;
  final HistoryState state;
  final DateTime? arrivedAt;
  final bool canPost;
  final bool canReview;
  final bool hasReviewed;
}

class HostAnalytics {
  const HostAnalytics({
    required this.confirmedAtStart,
    required this.arrivals,
    required this.postCount,
    required this.commentCount,
    required this.reviewCount,
    required this.ratingBreakdown,
    required this.pendingCount,
  });

  final int confirmedAtStart;
  final int arrivals;
  final int postCount;
  final int commentCount;
  final int reviewCount;
  final int pendingCount;

  /// index 0 = 1 star … index 4 = 5 stars.
  final List<int> ratingBreakdown;

  /// null means "Not available" (zero denominator).
  double? get turnout =>
      confirmedAtStart == 0 ? null : arrivals / confirmedAtStart;

  /// null means "No reviews yet".
  double? get averageRating {
    if (reviewCount == 0) return null;
    var total = 0;
    for (var i = 0; i < 5; i++) {
      total += ratingBreakdown[i] * (i + 1);
    }
    return total / reviewCount;
  }
}

/// Thrown when a rule blocks an action. The message is user-facing.
class RuleViolation implements Exception {
  const RuleViolation(this.message);
  final String message;
  @override
  String toString() => message;
}

const kTopics = [
  'Tech & AI',
  'Pickleball',
  'Food & Drinks',
  'Chess & Board Games',
  'Running & Fitness',
  'Music & Gigs',
  'Badminton',
  'Design & Creative',
  'Coffee Crawls',
  'Books & Reading',
];

const kAreas = [
  'Bonifacio Global City',
  'Makati',
  'Ortigas',
  'Quezon City',
  'Manila',
  'Mandaluyong',
  'Parañaque',
];
