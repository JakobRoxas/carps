import 'package:carps/controllers/app_controller.dart';
import 'package:carps/models/carps_models.dart';
import 'package:carps/repositories/mock_carps_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 24, 15);

  late MockCarpsRepository repository;
  late AppController app;

  setUp(() {
    repository = MockCarpsRepository.seeded(now);
    app = AppController(repository, clock: () => now);
  });

  tearDown(() => app.dispose());

  test('event and registration controllers share repository data', () {
    final event = app.events.eventById(DemoIds.pickleballLive);
    expect(event, isNotNull);

    final registration = app.events.requestToJoin(
      DemoIds.ana,
      DemoIds.pickleballLive,
      note: 'Looking forward to joining.',
    );

    expect(registration.status, RegistrationStatus.pending);
    expect(
      app.registrations.registrationFor(
        DemoIds.pickleballLive,
        DemoIds.ana,
      )?.id,
      registration.id,
    );
    expect(
      app.data.registrations.any((item) => item.id == registration.id),
      isTrue,
    );
  });

  test('feed controller reads posts through its feature service', () {
    final post = app.feed.postById(DemoIds.publicPost);

    expect(post, isNotNull);
    expect(app.feed.canViewPost(DemoIds.ana, post!), isTrue);
    expect(
      app.feed.feed(DemoIds.ana).any((item) => item.id == post.id),
      isTrue,
    );
  });

  test('profile controller writes update the shared repository cache', () {
    final current = app.profiles.userById(DemoIds.ana);
    expect(current, isNotNull);

    app.profiles.updateUser(current!.copyWith(displayName: 'Ana Updated'));

    expect(
      app.data.userById(DemoIds.ana)?.displayName,
      'Ana Updated',
    );
  });

  test('auth controller uses the mock account service when no gateway exists',
      () async {
    final created = await app.auth.signUp(
      'mvc-test@example.com',
      'longpassword',
    );
    app.signIn(created.id);

    expect(app.me?.email, 'mvc-test@example.com');
    expect(app.auth.firebaseEnabled, isFalse);
  });
}
