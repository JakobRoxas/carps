import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'controllers/app_controller.dart';
import 'views/admin/admin_view.dart';
import 'views/auth/login_view.dart';
import 'views/auth/recovery_view.dart';
import 'views/events/analytics_view.dart';
import 'views/events/event_detail_view.dart';
import 'views/events/event_form_view.dart';
import 'views/events/invites_view.dart';
import 'views/events/pass_view.dart';
import 'views/events/reviews_view.dart';
import 'views/events/roster_view.dart';
import 'views/events/scanner_view.dart';
import 'views/feed/compose_post_view.dart';
import 'views/feed/feed_view.dart';
import 'views/feed/post_detail_view.dart';
import 'views/home/home_view.dart';
import 'views/home/search_view.dart';
import 'views/notifications/notifications_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/profile/builder_setup_view.dart';
import 'views/profile/edit_profile_view.dart';
import 'views/profile/followed_view.dart';
import 'views/profile/history_view.dart';
import 'views/profile/profile_view.dart';
import 'views/profile/rsvps_view.dart';
import 'views/settings/settings_view.dart';
import 'views/shell/app_shell.dart';

GoRouter buildRouter(AppController app) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: app,
    redirect: (context, state) {
      final path = state.uri.path;
      final publicPaths = {'/login', '/recover'};
      final me = app.me;
      if (me == null) {
        // Public event listings support signed-out viewing.
        if (publicPaths.contains(path) || path.startsWith('/event/')) {
          return null;
        }
        return '/login';
      }
      // Returning users skip completed setup.
      if (!me.onboardingComplete) {
        return path == '/onboarding' ? null : '/onboarding';
      }
      if (publicPaths.contains(path) || path == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginView()),
      GoRoute(path: '/recover', builder: (_, _) => const RecoveryView()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingView()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeView()),
          GoRoute(path: '/feed', builder: (_, _) => const FeedView()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileView()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsView()),
        ],
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchView()),
      GoRoute(path: '/create', builder: (_, _) => const EventFormView()),
      GoRoute(
          path: '/event/:id',
          builder: (_, s) => EventDetailView(eventId: s.pathParameters['id']!)),
      GoRoute(
          path: '/event/:id/edit',
          builder: (_, s) => EventFormView(eventId: s.pathParameters['id'])),
      GoRoute(
          path: '/event/:id/invites',
          builder: (_, s) => InvitesView(eventId: s.pathParameters['id']!)),
      GoRoute(
          path: '/event/:id/roster',
          builder: (_, s) => RosterView(eventId: s.pathParameters['id']!)),
      GoRoute(
          path: '/event/:id/scan',
          builder: (_, s) => ScannerView(eventId: s.pathParameters['id']!)),
      GoRoute(
          path: '/event/:id/analytics',
          builder: (_, s) => AnalyticsView(eventId: s.pathParameters['id']!)),
      GoRoute(
          path: '/event/:id/reviews',
          builder: (_, s) => ReviewsView(eventId: s.pathParameters['id']!)),
      GoRoute(
          path: '/pass/:eventId',
          builder: (_, s) => PassView(eventId: s.pathParameters['eventId']!)),
      GoRoute(
          path: '/compose',
          builder: (_, s) =>
              ComposePostView(initialEventId: s.uri.queryParameters['event'])),
      GoRoute(
          path: '/post/:id',
          builder: (_, s) => PostDetailView(postId: s.pathParameters['id']!)),
      GoRoute(
          path: '/user/:id',
          builder: (_, s) => ProfileView(userId: s.pathParameters['id'])),
      GoRoute(path: '/rsvps', builder: (_, _) => const RsvpsView()),
      GoRoute(path: '/history', builder: (_, _) => const HistoryView()),
      GoRoute(path: '/followed', builder: (_, _) => const FollowedView()),
      GoRoute(path: '/edit-profile', builder: (_, _) => const EditProfileView()),
      GoRoute(
          path: '/builder-setup', builder: (_, _) => const BuilderSetupView()),
      GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsView()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminView()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
}
