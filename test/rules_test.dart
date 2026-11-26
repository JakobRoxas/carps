import 'package:carps/models/carps_models.dart';
import 'package:carps/repositories/mock_carps_repository.dart';
import 'package:carps/services/carps_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rule tests for the five flows. A mutable clock lets us move time forward
/// the same way the demo "end event" control does.
void main() {
  late DateTime clock;
  late MockCarpsRepository repo;
  late CarpsService svc;

  setUp(() {
    clock = DateTime(2026, 11, 24, 15);
    repo = MockCarpsRepository.seeded(clock);
    svc = CarpsService(repo, clock: () => clock);
  });

  const live = DemoIds.pickleballLive;

  group('Flow 3 · request, approval and arrival', () {
    test('definition of done: request → approve → pass → scan → end → tagged post',
        () {
      final reg = svc.requestToJoin(DemoIds.ana, live);
      expect(reg.status, RegistrationStatus.pending);
      expect(svc.passFor(live, DemoIds.ana), isNull,
          reason: 'pending has no pass');

      svc.decide(DemoIds.mika, reg.id, approve: true);
      final pass = svc.passFor(live, DemoIds.ana);
      expect(pass, isNotNull);
      expect(svc.notificationsFor(DemoIds.ana).first.kind,
          NotificationKind.approved);
      expect(svc.hasAttended(live, DemoIds.ana), isFalse,
          reason: 'approval alone is not attendance');

      final scan = svc.scan(DemoIds.mika, live, pass!.token);
      expect(scan.outcome, ScanOutcome.checkedIn);
      // Sofia (a peer) also checks in so she can be tagged.
      svc.scan(DemoIds.mika, live, svc.passFor(live, DemoIds.sofia)!.token);

      // Before the event ends nobody can post about it.
      expect(svc.eligiblePostEvents(DemoIds.ana).map((e) => e.id),
          isNot(contains(live)));

      svc.endEventNow(live);
      expect(svc.eligiblePostEvents(DemoIds.ana).map((e) => e.id),
          contains(live));

      final post = svc.publishPost(
        authorId: DemoIds.ana,
        eventId: live,
        body: 'Great rallies tonight!',
        taggedIds: [DemoIds.mika, DemoIds.sofia],
      );
      // One record across event, author Posts and both Tagged tabs.
      expect(svc.eventPosts(DemoIds.bea, live).single.id, post.id);
      expect(svc.authoredPosts(DemoIds.bea, DemoIds.ana).first.id, post.id);
      expect(svc.taggedPosts(DemoIds.bea, DemoIds.mika).first.id, post.id);
      expect(svc.taggedPosts(DemoIds.bea, DemoIds.sofia).first.id, post.id);
    });

    test('private requests also start Pending; uninvited cannot request', () {
      expect(svc.requestToJoin(DemoIds.ana, DemoIds.clinicNext).status,
          RegistrationStatus.pending);
      expect(() => svc.requestToJoin(DemoIds.bea, DemoIds.clinicNext),
          throwsA(isA<RuleViolation>()));
    });

    test('declined user gets a decision but no pass', () {
      final marco = svc.registrationFor(live, DemoIds.marco)!;
      svc.decide(DemoIds.mika, marco.id, approve: false);
      expect(svc.registrationFor(live, DemoIds.marco)!.status,
          RegistrationStatus.declined);
      expect(svc.passFor(live, DemoIds.marco), isNull);
      expect(repo.passes.where((p) =>
          p.eventId == live && p.userId == DemoIds.marco), isEmpty);
      expect(svc.notificationsFor(DemoIds.marco).first.kind,
          NotificationKind.declined);
    });

    test('duplicate scan does not increase turnout', () {
      final token = svc.passFor(live, DemoIds.sofia)!.token;
      expect(svc.scan(DemoIds.mika, live, token).outcome, ScanOutcome.checkedIn);
      final before = svc.analyticsFor(DemoIds.mika, live).arrivals;
      final again = svc.scan(DemoIds.mika, live, token);
      expect(again.outcome, ScanOutcome.alreadyCheckedIn);
      expect(svc.analyticsFor(DemoIds.mika, live).arrivals, before);
      expect(svc.attendanceForEvent(live).length, 1);
    });

    test('invalid, wrong-event and withdrawn passes never grant attendance', () {
      expect(svc.scan(DemoIds.mika, live, 'CARP-FAKE').outcome,
          ScanOutcome.invalid);

      // Ana's pass for the private clinic, scanned at the open play.
      final reg = svc.requestToJoin(DemoIds.ana, DemoIds.clinicNext);
      svc.decide(DemoIds.mika, reg.id, approve: true);
      final clinicPass = svc.passFor(DemoIds.clinicNext, DemoIds.ana)!;
      expect(svc.scan(DemoIds.mika, live, clinicPass.token).outcome,
          ScanOutcome.wrongEvent);

      // Paolo withdraws: his old token is rejected.
      final paoloPass = svc.passFor(live, DemoIds.paolo)!;
      svc.withdraw(DemoIds.paolo, svc.registrationFor(live, DemoIds.paolo)!.id);
      expect(svc.passFor(live, DemoIds.paolo), isNull);
      expect(svc.scan(DemoIds.mika, live, paoloPass.token).outcome,
          ScanOutcome.withdrawn);

      expect(svc.hasAttended(live, DemoIds.ana), isFalse);
      expect(svc.hasAttended(live, DemoIds.paolo), isFalse);
    });

    test('only the hosting team can scan or decide; admins cannot approve', () {
      final token = svc.passFor(live, DemoIds.sofia)!.token;
      expect(svc.scan(DemoIds.sam, live, token).outcome,
          ScanOutcome.notAuthorized);
      final marco = svc.registrationFor(live, DemoIds.marco)!;
      expect(() => svc.decide(DemoIds.sam, marco.id, approve: true),
          throwsA(isA<RuleViolation>()));
    });

    test('following never creates a registration', () {
      svc.toggleFollow(DemoIds.paolo, DemoIds.david);
      expect(svc.registrationFor(DemoIds.techNight, DemoIds.paolo)?.status,
          RegistrationStatus.approved); // seeded, unchanged
      svc.toggleFollow(DemoIds.marco, DemoIds.mika);
      expect(svc.registrationFor(DemoIds.sketchWalk, DemoIds.marco), isNull);
    });
  });

  group('Flow 4 · posts and reviews', () {
    test('no-show cannot post or review', () {
      final past = repo.event(DemoIds.pickleballPast)!;
      expect(svc.canPostAbout(DemoIds.paolo, past), isFalse);
      expect(
          () => svc.publishPost(
              authorId: DemoIds.paolo,
              eventId: past.id,
              body: 'I was there!'),
          throwsA(isA<RuleViolation>()));
      expect(() => svc.submitReview(DemoIds.paolo, past.id, 5, 'Nice'),
          throwsA(isA<RuleViolation>()));
    });

    test('host who was not checked in cannot post (rule applies to builders)',
        () {
      final past = repo.event(DemoIds.pickleballPast)!;
      expect(svc.canPostAbout(DemoIds.mika, past), isFalse);
      expect(svc.postBlocker(DemoIds.mika, past), contains('Hosting alone'));
    });

    test('cancelled sessions never qualify', () {
      final c = repo.event(DemoIds.chessCancelled)!;
      expect(svc.canPostAbout(DemoIds.ana, c), isFalse);
    });

    test('private sessions are eligible for their attendees', () {
      expect(svc.eligiblePostEvents(DemoIds.ana).map((e) => e.id),
          containsAll([DemoIds.pickleballPast, DemoIds.clinicPast]));
    });

    test('missing event, unearned event and mismatched tags are rejected', () {
      expect(
          () => svc.publishPost(
              authorId: DemoIds.ana, eventId: null, body: 'hello'),
          throwsA(isA<RuleViolation>()));
      expect(
          () => svc.publishPost(
              authorId: DemoIds.bea,
              eventId: DemoIds.pickleballPast,
              body: 'hello'),
          throwsA(isA<RuleViolation>()));
      expect(
          () => svc.publishPost(
              authorId: DemoIds.ana,
              eventId: DemoIds.pickleballPast,
              body: 'hello',
              taggedIds: [DemoIds.bea]),
          throwsA(isA<RuleViolation>()),
          reason: 'Bea did not attend that session');
      expect(
          () => svc.publishPost(
              authorId: DemoIds.ana,
              eventId: DemoIds.pickleballPast,
              body: 'hello',
              taggedIds: [DemoIds.paolo]),
          throwsA(isA<RuleViolation>()),
          reason: 'Paolo was a no-show, not a checked-in peer');
    });

    test('outsider cannot see a private tagged post anywhere', () {
      final private = repo.post(DemoIds.privatePost)!;
      // Bea follows Mika (who is tagged) but never attended the clinic.
      expect(svc.canViewPost(DemoIds.bea, private), isFalse);
      expect(svc.taggedPosts(DemoIds.bea, DemoIds.mika).map((p) => p.id),
          isNot(contains(private.id)));
      expect(svc.taggedPosts(DemoIds.bea, DemoIds.ana).map((p) => p.id),
          isNot(contains(private.id)));
      expect(svc.authoredPosts(DemoIds.bea, DemoIds.sofia), isEmpty);
      expect(svc.feed(DemoIds.bea).map((p) => p.id),
          isNot(contains(private.id)));
      expect(svc.canViewEvent(DemoIds.bea, repo.event(DemoIds.clinicPast)!),
          isFalse);
      // Signed-out visitor and invited no-show are also excluded.
      expect(svc.canViewPost(null, private), isFalse);
      expect(svc.canViewPost(DemoIds.paolo, private), isFalse);
      // Verified attendees and the host can read it.
      expect(svc.canViewPost(DemoIds.ana, private), isTrue);
      expect(svc.canViewPost(DemoIds.mika, private), isTrue);
    });

    test('likes and comments never create profile posts; no access no like',
        () {
      final before = svc.authoredPosts(DemoIds.bea, DemoIds.bea).length;
      svc.toggleLike(DemoIds.bea, DemoIds.publicPost);
      svc.addComment(DemoIds.bea, DemoIds.publicPost, 'Love this');
      expect(svc.authoredPosts(DemoIds.bea, DemoIds.bea).length, before);
      expect(() => svc.toggleLike(DemoIds.bea, DemoIds.privatePost),
          throwsA(isA<RuleViolation>()));
    });

    test('removing a tag drops only that Tagged placement; delete removes all',
        () {
      svc.removeTag(DemoIds.sofia, DemoIds.publicPost);
      expect(svc.taggedPosts(null, DemoIds.sofia), isEmpty);
      expect(svc.taggedPosts(null, DemoIds.mika).single.id, DemoIds.publicPost);
      expect(() => svc.deletePost(DemoIds.sofia, DemoIds.publicPost),
          throwsA(isA<RuleViolation>()));
      svc.deletePost(DemoIds.ana, DemoIds.publicPost);
      expect(svc.taggedPosts(null, DemoIds.mika), isEmpty);
      expect(svc.eventPosts(null, DemoIds.pickleballPast), isEmpty);
    });

    test('one review per checked-in attendee', () {
      svc.submitReview(DemoIds.ana, DemoIds.pickleballPast, 4, 'Fun');
      expect(
          () => svc.submitReview(DemoIds.ana, DemoIds.pickleballPast, 5, 'x'),
          throwsA(isA<RuleViolation>()));
    });
  });

  group('Flow 2 · hosting', () {
    test('guest invitation to a builder grants no hosting privileges', () {
      expect(svc.guestInvitation(DemoIds.clinicNext, DemoIds.david), isNotNull);
      final event = repo.event(DemoIds.clinicNext)!;
      expect(event.isHostingTeam(DemoIds.david), isFalse);
      final reg = svc.requestToJoin(DemoIds.ana, DemoIds.clinicNext);
      expect(() => svc.decide(DemoIds.david, reg.id, approve: true),
          throwsA(isA<RuleViolation>()));
    });

    test('co-host gets tools only after accepting', () {
      svc.inviteCoHost(DemoIds.mika, live, DemoIds.david);
      final marco = svc.registrationFor(live, DemoIds.marco)!;
      expect(() => svc.decide(DemoIds.david, marco.id, approve: true),
          throwsA(isA<RuleViolation>()));
      final inv = svc.coHostInvitation(live, DemoIds.david)!;
      svc.respondToCoHost(DemoIds.david, inv.id, true);
      svc.decide(DemoIds.david, marco.id, approve: true);
      expect(svc.passFor(live, DemoIds.marco), isNotNull);
    });

    test('notices update the listing without creating posts', () {
      final postsBefore = repo.posts.length;
      svc.postNotice(DemoIds.mika, live, 'Court 4 moved to Court 2');
      expect(repo.event(live)!.notices.first.text, 'Court 4 moved to Court 2');
      expect(repo.posts.length, postsBefore);
    });

    test('private listings are hidden from discovery', () {
      final ids = svc.discoverableEvents(DemoIds.bea).map((e) => e.id);
      expect(ids, isNot(contains(DemoIds.clinicNext)));
      expect(svc.profileEvents(DemoIds.bea, DemoIds.mika).map((e) => e.id),
          isNot(contains(DemoIds.clinicNext)));
    });

    test('analytics: 2 confirmed, 1 arrival, one 4-star review → 50%, 4/5', () {
      final e = svc.createEvent(
        actorId: DemoIds.mika,
        title: 'Test Session',
        description: '',
        topic: 'Pickleball',
        venue: 'Court 1',
        area: 'Bonifacio Global City',
        start: clock.add(const Duration(hours: 2)),
        end: clock.add(const Duration(hours: 4)),
        visibility: EventVisibility.public,
      );
      for (final u in [DemoIds.ana, DemoIds.bea]) {
        final r = svc.requestToJoin(u, e.id);
        svc.decide(DemoIds.mika, r.id, approve: true);
      }
      svc.scan(DemoIds.mika, e.id, svc.passFor(e.id, DemoIds.ana)!.token);
      svc.endEventNow(e.id);
      svc.submitReview(DemoIds.ana, e.id, 4, 'Good');
      final a = svc.analyticsFor(DemoIds.mika, e.id);
      expect(a.turnout, 0.5);
      expect(a.averageRating, 4);
      expect(a.reviewCount, 1);
    });

    test('no-data analytics: Not available and No reviews yet', () {
      final a = svc.analyticsFor(DemoIds.mika, DemoIds.sketchWalk);
      // Bea is approved for the sketch walk but approval was before start.
      expect(a.averageRating, isNull);
      final fresh = svc.createEvent(
        actorId: DemoIds.mika,
        title: 'Empty Session',
        description: '',
        topic: 'Pickleball',
        venue: 'Court 1',
        area: 'Makati',
        start: clock.add(const Duration(days: 1)),
        end: clock.add(const Duration(days: 1, hours: 2)),
        visibility: EventVisibility.public,
      );
      expect(svc.analyticsFor(DemoIds.mika, fresh.id).turnout, isNull);
    });
  });

  group('Flow 5 · admin', () {
    test('attendance correction requires host confirmation and is recorded',
        () {
      final c = svc.casesFor(DemoIds.sam).single;
      expect(
          () => svc.resolveCase(
              adminId: DemoIds.sam,
              caseId: c.id,
              outcome: CaseOutcome.attendanceCorrected,
              note: 'x'),
          throwsA(isA<RuleViolation>()));
      svc.resolveCase(
          adminId: DemoIds.sam,
          caseId: c.id,
          outcome: CaseOutcome.attendanceCorrected,
          note: 'Host confirmed Paolo arrived late without scanning.',
          hostConfirmed: true);
      expect(svc.hasAttended(DemoIds.pickleballPast, DemoIds.paolo), isTrue);
      expect(repo.cases.single.status, CaseStatus.closed);
      expect(svc.notificationsFor(DemoIds.paolo).first.kind,
          NotificationKind.supportUpdate);
    });

    test('non-admins see no cases and cannot resolve', () {
      expect(svc.casesFor(DemoIds.mika), isEmpty);
      expect(
          () => svc.resolveCase(
              adminId: DemoIds.mika,
              caseId: repo.cases.first.id,
              outcome: CaseOutcome.noAction,
              note: 'x'),
          throwsA(isA<RuleViolation>()));
    });

    test('report from Help is assigned to the admin', () {
      final c = svc.reportIssue(DemoIds.bea, 'Safety concern',
          'Someone was rude at the event.',
          link: 'carps.ph/event/${DemoIds.sketchWalk}');
      expect(c.assignedAdminId, DemoIds.sam);
      expect(svc.casesFor(DemoIds.sam).map((x) => x.id), contains(c.id));
    });
  });
}
