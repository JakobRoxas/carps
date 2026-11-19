import 'package:flutter/material.dart';
import 'controllers/event_social_controller.dart';
import 'controllers/feed_controller.dart';
import 'controllers/group_controller.dart';
import 'models/user_model.dart';
import 'repositories/event_repository.dart';
import 'repositories/group_repository.dart';

void main() {
  // TODO: swap these with firebase later
  final eventRepo = MockEventRepository();
  final groupRepo = MockGroupRepository();

  const mockUser = AppUser(
    id: 'user_1',
    name: 'Jakob',
    email: 'jakob@iscool.com',
    location: 'Manila',
    interestTags: ['tech', 'flutter', 'music'],
    followedGroupIds: ['grp_1'],
  );

  final feedController = FeedController(
    eventRepository: eventRepo,
    currentUser: mockUser,
  )..loadFeed();

  final groupController = GroupController(
    groupRepository: groupRepo,
    eventRepository: eventRepo,
    currentUser: mockUser,
  )..loadGroups();

  final socialController = EventSocialController(
    eventRepository: eventRepo,
    currentUser: mockUser,
  );

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BackendSmokeTestView(
      feedController: feedController,
      groupController: groupController,
      socialController: socialController,
    ),
  ));
}

class BackendSmokeTestView extends StatelessWidget {
  final FeedController feedController;
  final GroupController groupController;
  final EventSocialController socialController;

  const BackendSmokeTestView({
    super.key,
    required this.feedController,
    required this.groupController,
    required this.socialController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carps — MVC Backend Smoke Test')),
      body: ListenableBuilder(
        listenable: Listenable.merge([feedController, groupController]),
        builder: (context, _) {
          if (feedController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = feedController.personalizedFeed;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isGoing =
                  event.attendeeIds.contains(feedController.currentUser.id);
              return ListTile(
                title: Text(event.title),
                subtitle: Text(
                  '${event.location} • ${feedController.socialProofLabel(event)}',
                ),
                trailing: ElevatedButton(
                  onPressed: () => feedController.toggleRsvp(event.id),
                  child: Text(isGoing ? 'Going ✓' : 'RSVP'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}