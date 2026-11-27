import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carps/models/carps_models.dart';
import 'package:carps/repositories/carps_firestore_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = CarpsFirestoreCodec();

  test('event codec stores timestamps and preserves nested notices', () {
    final event = CarpsEvent(
      id: 'event_1',
      hostId: 'user_1',
      title: 'Community run',
      description: 'Easy pace.',
      topic: 'Running & Fitness',
      venue: 'Park',
      area: 'Makati',
      start: DateTime.utc(2026, 12, 1, 10),
      end: DateTime.utc(2026, 12, 1, 12),
      visibility: EventVisibility.private,
      status: EventStatus.cancelled,
      notices: [
        EventNotice(
          id: 'notice_1',
          text: 'Meet at the other entrance.',
          createdAt: DateTime.utc(2026, 11, 30, 8),
          isVenueChange: true,
        ),
      ],
    );

    final encoded = codec.encodeEvent(event);
    final decoded = codec.decodeEvent(Map<String, dynamic>.from(encoded));

    expect(encoded['start'], Timestamp.fromDate(event.start));
    expect(decoded.id, event.id);
    expect(decoded.visibility, event.visibility);
    expect(decoded.status, event.status);
    expect(decoded.start.isAtSameMomentAs(event.start), isTrue);
    expect(decoded.notices.single.text, event.notices.single.text);
    expect(decoded.notices.single.isVenueChange, isTrue);
  });

  test(
    'public profile documents do not contain a member email or password',
    () {
      const user = UserProfile(
        id: 'user_1',
        displayName: 'Member',
        username: 'member_1',
        email: 'member@example.com',
        password: 'mock-only-password',
      );

      final encoded = codec.encodeUser(user);
      final decoded = codec.decodeUser(
        Map<String, dynamic>.from(encoded),
        email: user.email,
      );

      expect(encoded, isNot(contains('email')));
      expect(encoded, isNot(contains('password')));
      expect(decoded.email, user.email);
      expect(decoded.password, isNot(user.password));
    },
  );

  test('codec rejects malformed required fields', () {
    expect(
      () => codec.decodeReview({
        'id': 'review_1',
        'eventId': 'event_1',
        'authorId': 'user_1',
        'rating': 'five',
        'text': '',
        'createdAt': DateTime.utc(2026),
      }),
      throwsFormatException,
    );
  });
}
