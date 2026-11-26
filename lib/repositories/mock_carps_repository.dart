import '../core/demo_photos.dart';
import '../models/carps_models.dart';
import 'carps_repository.dart';

/// In-memory repository used until Firebase is wired up.
///
/// Every list is replaced on write so callers never mutate shared state.
class MockCarpsRepository extends CarpsRepository {
  MockCarpsRepository();

  /// Builds a repository pre-filled with the demo world, relative to [now].
  factory MockCarpsRepository.seeded(DateTime now) {
    final repo = MockCarpsRepository();
    seedDemoWorld(repo, now);
    return repo;
  }

  final Map<String, UserProfile> _users = {};
  final Map<String, CarpsEvent> _events = {};
  final Map<String, Invitation> _invitations = {};
  final Map<String, Registration> _registrations = {};
  final Map<String, GuestPass> _passes = {};
  final List<Attendance> _attendance = [];
  final Map<String, ExperiencePost> _posts = {};
  final Map<String, EventReview> _reviews = {};
  final Map<String, AppNotification> _notifications = {};
  final Map<String, SupportCase> _cases = {};
  final Map<String, int> _counters = {};

  @override
  String nextId(String prefix) {
    final n = (_counters[prefix] ?? 0) + 1;
    _counters[prefix] = n;
    return '${prefix}_$n';
  }

  @override
  List<UserProfile> get users => List.unmodifiable(_users.values);
  @override
  UserProfile? user(String id) => _users[id];
  @override
  void saveUser(UserProfile user) {
    _users[user.id] = user;
    notifyListeners();
  }

  @override
  List<CarpsEvent> get events => List.unmodifiable(_events.values);
  @override
  CarpsEvent? event(String id) => _events[id];
  @override
  void saveEvent(CarpsEvent event) {
    _events[event.id] = event;
    notifyListeners();
  }

  @override
  List<Invitation> get invitations => List.unmodifiable(_invitations.values);
  @override
  void saveInvitation(Invitation invitation) {
    _invitations[invitation.id] = invitation;
    notifyListeners();
  }

  @override
  List<Registration> get registrations =>
      List.unmodifiable(_registrations.values);
  @override
  void saveRegistration(Registration registration) {
    _registrations[registration.id] = registration;
    notifyListeners();
  }

  @override
  List<GuestPass> get passes => List.unmodifiable(_passes.values);
  @override
  GuestPass? passByToken(String token) {
    for (final p in _passes.values) {
      if (p.token == token) return p;
    }
    return null;
  }

  @override
  void savePass(GuestPass pass) {
    _passes[pass.id] = pass;
    notifyListeners();
  }

  @override
  List<Attendance> get attendance => List.unmodifiable(_attendance);
  @override
  void saveAttendance(Attendance record) {
    _attendance.add(record);
    notifyListeners();
  }

  @override
  List<ExperiencePost> get posts => List.unmodifiable(_posts.values);
  @override
  ExperiencePost? post(String id) => _posts[id];
  @override
  void savePost(ExperiencePost post) {
    _posts[post.id] = post;
    notifyListeners();
  }

  @override
  void deletePost(String id) {
    _posts.remove(id);
    notifyListeners();
  }

  @override
  List<EventReview> get reviews => List.unmodifiable(_reviews.values);
  @override
  void saveReview(EventReview review) {
    _reviews[review.id] = review;
    notifyListeners();
  }

  @override
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.values);
  @override
  void saveNotification(AppNotification notification) {
    _notifications[notification.id] = notification;
    notifyListeners();
  }

  @override
  List<SupportCase> get cases => List.unmodifiable(_cases.values);
  @override
  void saveCase(SupportCase supportCase) {
    _cases[supportCase.id] = supportCase;
    notifyListeners();
  }
}

/// Demo account ids, exposed for the demo panel and tests.
class DemoIds {
  static const mika = 'u_mika'; // community builder / host
  static const ana = 'u_ana'; // approved guest who checks in
  static const sofia = 'u_sofia'; // checked-in peer (taggable)
  static const paolo = 'u_paolo'; // approved no-show
  static const marco = 'u_marco'; // request gets declined
  static const bea = 'u_bea'; // outsider who follows Mika
  static const david = 'u_david'; // second builder (co-host / guest)
  static const sam = 'u_sam'; // assigned admin permission

  static const pickleballPast = 'ev_pb_past';
  static const clinicPast = 'ev_clinic_past';
  static const coffeePast = 'ev_coffee_past';
  static const chessCancelled = 'ev_chess_cancelled';
  static const pickleballLive = 'ev_pb_live';
  static const clinicNext = 'ev_clinic_next';
  static const techNight = 'ev_tech';
  static const foodCrawl = 'ev_food';
  static const sketchWalk = 'ev_sketch';

  static const publicPost = 'post_seed_public';
  static const privatePost = 'post_seed_private';
}

/// Seeds one public and one private community with distinct host, approved
/// guest, no-show and outsider accounts so privacy and attendance rules can
/// actually be exercised.
void seedDemoWorld(MockCarpsRepository repo, DateTime now) {
  DateTime at(int dayOffset, int hour, [int minute = 0]) {
    final d = DateTime(now.year, now.month, now.day)
        .add(Duration(days: dayOffset));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  const done = (terms: true, profile: true, discovery: true);

  UserProfile u(
    String id,
    String name,
    String username, {
    String bio = '',
    String? area,
    List<String> interests = const [],
    List<String> following = const [],
    bool hosting = false,
    String? builderName,
    String? builderAbout,
    bool admin = false,
    PrimaryRole role = PrimaryRole.attendee,
  }) {
    return UserProfile(
      id: id,
      displayName: name,
      username: username,
      email: '$username@example.com',
      bio: bio,
      area: area,
      interests: interests,
      followingIds: following,
      hostingEnabled: hosting,
      builderName: builderName,
      builderAbout: builderAbout,
      isAdmin: admin,
      termsAccepted: done.terms,
      primaryRole: role,
      profileComplete: done.profile,
      discoveryDone: done.discovery,
    );
  }

  for (final user in [
    u(DemoIds.mika, 'Mika Cruz', 'mikacruz',
        bio: 'Running weekly sunset open play at The Upper Deck. All levels welcome.',
        area: 'Bonifacio Global City',
        interests: ['Pickleball', 'Running & Fitness', 'Coffee Crawls'],
        hosting: true,
        builderName: 'BGC Smashers',
        builderAbout: 'Weekly pickleball open play and beginner clinics around High Street.',
        role: PrimaryRole.builder),
    u(DemoIds.ana, 'Ana Reyes', 'anareyes',
        bio: 'Always game for pickleball and third-wave coffee.',
        area: 'Bonifacio Global City',
        interests: ['Tech & AI', 'Pickleball', 'Food & Drinks'],
        following: [DemoIds.mika]),
    u(DemoIds.sofia, 'Sofia Santos', 'sofiasantos',
        bio: 'Foodie and board-game regular.',
        area: 'Makati',
        interests: ['Pickleball', 'Chess & Board Games', 'Food & Drinks'],
        following: [DemoIds.mika]),
    u(DemoIds.paolo, 'Paolo Tan', 'paolotan',
        bio: 'Sunday smasher in training.',
        area: 'Ortigas',
        interests: ['Pickleball', 'Running & Fitness', 'Badminton']),
    u(DemoIds.marco, 'Marco Lim', 'marcolim',
        bio: 'First time at Upper Deck!',
        area: 'Quezon City',
        interests: ['Pickleball', 'Tech & AI', 'Music & Gigs']),
    u(DemoIds.bea, 'Bea Valenzuela', 'beavalenzuela',
        bio: 'Coffee enthusiast from Pasig.',
        area: 'Ortigas',
        interests: ['Coffee Crawls', 'Pickleball', 'Design & Creative'],
        following: [DemoIds.mika]),
    u(DemoIds.david, 'David Lim', 'davidlim',
        bio: 'Tech Manila host. Strategy games on weekends.',
        area: 'Makati',
        interests: ['Tech & AI', 'Chess & Board Games', 'Food & Drinks'],
        hosting: true,
        builderName: 'Manila Tech Guild',
        builderAbout: 'Founder meetups, AI demo nights and the occasional food crawl.',
        role: PrimaryRole.builder),
    u(DemoIds.sam, 'Sam Bautista', 'sambautista',
        bio: 'CARPS pilot support.',
        area: 'Manila',
        interests: ['Tech & AI', 'Coffee Crawls', 'Running & Fitness'],
        admin: true),
  ]) {
    repo.saveUser(user);
  }

  const upperDeck = 'The Upper Deck Sports Center, 6th Floor, High Street South';
  const openPlayTitle = 'Pop and Pickle: Pickle Open Play';

  final events = [
    CarpsEvent(
      id: DemoIds.pickleballPast,
      hostId: DemoIds.mika,
      title: openPlayTitle,
      description:
          'Cap off your evening with casual open play rallies and friendly doubles match-ups. '
          'No partner needed: we rotate after every 11-point match. Beginners get a quick '
          'briefing on scoring and kitchen-zone rules.',
      topic: 'Pickleball',
      venue: upperDeck,
      area: 'Bonifacio Global City',
      start: at(-7, 18),
      end: at(-7, 21),
      visibility: EventVisibility.public,
      coverAsset: DemoPhotos.pickleball,
      capacity: 20,
      seriesLabel: 'Sunset open play',
    ),
    CarpsEvent(
      id: DemoIds.clinicPast,
      hostId: DemoIds.mika,
      title: 'Private Doubles Clinic',
      description: 'Invite-only drills on third-shot drops and stacking.',
      topic: 'Pickleball',
      venue: 'Terra 28th Courts, Court 3',
      area: 'Bonifacio Global City',
      start: at(-3, 7),
      end: at(-3, 9),
      visibility: EventVisibility.private,
      coverAsset: DemoPhotos.pickleball,
      capacity: 8,
      seriesLabel: 'Doubles clinic',
    ),
    CarpsEvent(
      id: DemoIds.coffeePast,
      hostId: DemoIds.david,
      title: 'Salcedo Weekend Coffee Run',
      description: 'A 5K easy run ending at the Salcedo market for coffee.',
      topic: 'Coffee Crawls',
      venue: 'Salcedo Park, Makati',
      area: 'Makati',
      start: at(-14, 8),
      end: at(-14, 10),
      visibility: EventVisibility.public,
    ),
    CarpsEvent(
      id: DemoIds.chessCancelled,
      hostId: DemoIds.david,
      title: 'Makati Chess Afternoon',
      description: 'Rapid games and a puzzle corner.',
      topic: 'Chess & Board Games',
      venue: 'Greenbelt 3 Atrium',
      area: 'Makati',
      start: at(-10, 14),
      end: at(-10, 17),
      visibility: EventVisibility.public,
      status: EventStatus.cancelled,
    ),
    CarpsEvent(
      id: DemoIds.pickleballLive,
      hostId: DemoIds.mika,
      title: openPlayTitle,
      description:
          'This week\'s sunset session. Courts 3 and 4 reserved, paddles and balls provided. '
          'Non-marking shoes required.',
      topic: 'Pickleball',
      venue: upperDeck,
      area: 'Bonifacio Global City',
      start: now.add(const Duration(hours: 1)),
      end: now.add(const Duration(hours: 4)),
      visibility: EventVisibility.public,
      coverAsset: DemoPhotos.pickleball,
      capacity: 20,
      seriesLabel: 'Sunset open play',
    ),
    CarpsEvent(
      id: DemoIds.clinicNext,
      hostId: DemoIds.mika,
      title: 'Private Doubles Clinic #2',
      description: 'Invite-only follow-up clinic: serve placement and resets.',
      topic: 'Pickleball',
      venue: 'Terra 28th Courts, Court 3',
      area: 'Bonifacio Global City',
      start: at(2, 7),
      end: at(2, 9),
      visibility: EventVisibility.private,
      coverAsset: DemoPhotos.pickleball,
      capacity: 8,
      seriesLabel: 'Doubles clinic',
    ),
    CarpsEvent(
      id: DemoIds.techNight,
      hostId: DemoIds.david,
      title: 'OpenAI Exchange Community Event',
      description: 'Five-minute demos from local founders, then open networking.',
      topic: 'Tech & AI',
      venue: 'KMC Megamall, Mandaluyong',
      area: 'Mandaluyong',
      start: at(2, 19, 30),
      end: at(2, 22),
      visibility: EventVisibility.public,
      coverAsset: DemoPhotos.openai,
      capacity: 60,
    ),
    CarpsEvent(
      id: DemoIds.foodCrawl,
      hostId: DemoIds.david,
      title: 'Binondo Eats: Street Food Challenge',
      description: 'Try dumplings, kikiam and hopia across six stops in Chinatown.',
      topic: 'Food & Drinks',
      venue: 'Ongpin St, Binondo',
      area: 'Manila',
      start: at(3, 17, 30),
      end: at(3, 21),
      visibility: EventVisibility.public,
      coverAsset: DemoPhotos.foodcrawl,
      capacity: 24,
    ),
    CarpsEvent(
      id: DemoIds.sketchWalk,
      hostId: DemoIds.mika,
      title: 'Intramuros Golden Hour Run',
      description: 'An easy-paced jog around the Walled City before sunset.',
      topic: 'Running & Fitness',
      venue: 'Fort Santiago Gate, Manila',
      area: 'Manila',
      start: at(5, 16),
      end: at(5, 18, 30),
      visibility: EventVisibility.public,
      coverAsset: DemoPhotos.intramuros,
      capacity: 15,
      featuredOnProfile: true,
    ),
    CarpsEvent(
      id: 'ev_nightmare',
      hostId: DemoIds.david,
      title: 'Nightmare Manila Day 1',
      description: 'Meet up for a group visit to the horror attraction.',
      topic: 'Design & Creative',
      venue: 'Nightmare Manila',
      area: 'Parañaque',
      start: at(4, 18),
      end: at(4, 21),
      visibility: EventVisibility.public,
      coverAsset: DemoPhotos.nightmare,
    ),
    CarpsEvent(
      id: 'ev_bookclub',
      hostId: DemoIds.david,
      title: 'Clover Bookclub: December Meetup',
      description: 'Bring a book you read this year and tell the group what stuck with you.',
      topic: 'Books & Reading',
      venue: 'Makati',
      area: 'Makati',
      start: at(6, 15),
      end: at(6, 17),
      visibility: EventVisibility.public,
      coverAsset: DemoPhotos.bookclub,
    ),
  ];
  for (final e in events) {
    repo.saveEvent(e);
  }

  var passCounter = 880;
  void reg(String eventId, String userId, RegistrationStatus status,
      {bool attended = false, String note = ''}) {
    final event = repo.event(eventId)!;
    final regId = repo.nextId('reg');
    String? passId;
    if (status == RegistrationStatus.approved) {
      passCounter++;
      passId = repo.nextId('pass');
      repo.savePass(GuestPass(
        id: passId,
        token: 'CARP-$passCounter-${userId.substring(2).toUpperCase()}',
        eventId: eventId,
        userId: userId,
        registrationId: regId,
        issuedAt: event.start.subtract(const Duration(days: 1)),
      ));
    }
    repo.saveRegistration(Registration(
      id: regId,
      eventId: eventId,
      userId: userId,
      status: status,
      requestedAt: event.start.subtract(const Duration(days: 2)),
      decidedAt: status == RegistrationStatus.pending
          ? null
          : event.start.subtract(const Duration(days: 1)),
      passId: passId,
      note: note,
    ));
    if (attended) {
      repo.saveAttendance(Attendance(
        eventId: eventId,
        userId: userId,
        arrivedAt: event.start.add(const Duration(minutes: 5)),
        scannedById: event.hostId,
        passId: passId,
      ));
    }
  }

  // Past public session: Ana + Sofia checked in, Paolo no-show, Marco declined.
  reg(DemoIds.pickleballPast, DemoIds.ana, RegistrationStatus.approved,
      attended: true);
  reg(DemoIds.pickleballPast, DemoIds.sofia, RegistrationStatus.approved,
      attended: true);
  reg(DemoIds.pickleballPast, DemoIds.paolo, RegistrationStatus.approved);
  reg(DemoIds.pickleballPast, DemoIds.marco, RegistrationStatus.declined);

  // Past private clinic: invited Ana, Sofia, Paolo. Paolo did not come.
  for (final id in [DemoIds.ana, DemoIds.sofia, DemoIds.paolo]) {
    repo.saveInvitation(Invitation(
      id: repo.nextId('inv'),
      eventId: DemoIds.clinicPast,
      inviteeId: id,
      invitedById: DemoIds.mika,
      kind: InvitationKind.guest,
      createdAt: at(-6, 9),
      status: InvitationStatus.accepted,
    ));
  }
  reg(DemoIds.clinicPast, DemoIds.ana, RegistrationStatus.approved,
      attended: true);
  reg(DemoIds.clinicPast, DemoIds.sofia, RegistrationStatus.approved,
      attended: true);
  reg(DemoIds.clinicPast, DemoIds.paolo, RegistrationStatus.approved);

  // Ana's history extras: a no-show and a cancelled session.
  reg(DemoIds.coffeePast, DemoIds.ana, RegistrationStatus.approved);
  reg(DemoIds.chessCancelled, DemoIds.ana, RegistrationStatus.approved);

  // Live session (starts in 1h): the end-to-end demo happens here.
  reg(DemoIds.pickleballLive, DemoIds.sofia, RegistrationStatus.approved);
  reg(DemoIds.pickleballLive, DemoIds.paolo, RegistrationStatus.approved);
  reg(DemoIds.pickleballLive, DemoIds.marco, RegistrationStatus.pending,
      note: 'First time playing at Upper Deck, excited to join!');

  // Upcoming public listings with a few approved guests for "going" counts.
  reg(DemoIds.techNight, DemoIds.sofia, RegistrationStatus.approved);
  reg(DemoIds.techNight, DemoIds.paolo, RegistrationStatus.approved);
  reg(DemoIds.techNight, DemoIds.marco, RegistrationStatus.approved);
  reg(DemoIds.foodCrawl, DemoIds.sofia, RegistrationStatus.approved);
  reg(DemoIds.sketchWalk, DemoIds.bea, RegistrationStatus.approved);

  // Upcoming private clinic: Ana and David (a builder) invited as GUESTS.
  for (final id in [DemoIds.ana, DemoIds.david]) {
    repo.saveInvitation(Invitation(
      id: repo.nextId('inv'),
      eventId: DemoIds.clinicNext,
      inviteeId: id,
      invitedById: DemoIds.mika,
      kind: InvitationKind.guest,
      createdAt: now.subtract(const Duration(hours: 5)),
    ));
    repo.saveNotification(AppNotification(
      id: repo.nextId('ntf'),
      userId: id,
      kind: NotificationKind.guestInvite,
      title: 'Mika Cruz invited you to a private event',
      body: 'Private Doubles Clinic #2. You can request to join; the host still decides.',
      createdAt: now.subtract(const Duration(hours: 5)),
      eventId: DemoIds.clinicNext,
    ));
  }
  repo.saveNotification(AppNotification(
    id: repo.nextId('ntf'),
    userId: DemoIds.mika,
    kind: NotificationKind.joinRequest,
    title: 'Marco Lim requested to join',
    body: '$openPlayTitle · review in Guest roster',
    createdAt: now.subtract(const Duration(minutes: 20)),
    eventId: DemoIds.pickleballLive,
  ));

  // One public post (tags the builder and a checked-in peer)…
  repo.savePost(ExperiencePost(
    id: DemoIds.publicPost,
    eventId: DemoIds.pickleballPast,
    authorId: DemoIds.ana,
    body: 'First doubles win at Upper Deck!! Thanks @mikacruz for the awesome rally and @sofiasantos for carrying me.',
    photoAsset: DemoPhotos.pickleball,
    taggedIds: const [DemoIds.mika, DemoIds.sofia],
    likedByIds: const [DemoIds.sofia, DemoIds.bea],
    comments: [
      PostComment(
        id: 'c_seed_1',
        authorId: DemoIds.sofia,
        body: 'That last dink was unreal 🔥',
        createdAt: at(-7, 22),
      ),
      PostComment(
        id: 'c_seed_2',
        authorId: DemoIds.ana,
        body: 'Rematch next week!',
        createdAt: at(-7, 22, 30),
        parentId: 'c_seed_1',
      ),
    ],
    createdAt: at(-7, 21, 40),
  ));

  // …and one PRIVATE post that tags Ana and Mika. Bea follows Mika but was
  // never part of the clinic, so she must not see it anywhere.
  repo.savePost(ExperiencePost(
    id: DemoIds.privatePost,
    eventId: DemoIds.clinicPast,
    authorId: DemoIds.sofia,
    body: 'Third-shot drops finally clicked today. Ana and I are stacking pros now.',
    taggedIds: const [DemoIds.ana, DemoIds.mika],
    likedByIds: const [DemoIds.ana],
    createdAt: at(-3, 10),
  ));

  repo.saveReview(EventReview(
    id: repo.nextId('rev'),
    eventId: DemoIds.pickleballPast,
    authorId: DemoIds.sofia,
    rating: 5,
    text: 'Super welcoming host! Courts were ready on time and skill matching was spot on.',
    createdAt: at(-6, 9),
  ));

  // An open support case for the admin flow.
  repo.saveCase(SupportCase(
    id: repo.nextId('case'),
    reporterId: DemoIds.paolo,
    category: 'Attendance discrepancy',
    link: 'carps.ph/event/${DemoIds.pickleballPast}',
    details: 'I think I was marked as a no-show for Sunset Open Play but I was there.',
    createdAt: at(-5, 12),
    assignedAdminId: DemoIds.sam,
  ));
  repo.saveNotification(AppNotification(
    id: repo.nextId('ntf'),
    userId: DemoIds.sam,
    kind: NotificationKind.supportAssigned,
    title: 'New issue assigned to you',
    body: 'Attendance discrepancy · reported by a member',
    createdAt: at(-5, 12),
    caseId: 'case_1',
  ));
}
