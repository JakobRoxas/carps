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

GoRoute _appRoute(String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    builder: (_, state) =>
        AppShell(location: state.uri.path, child: builder(state)),
  );
}

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
      _appRoute('/home', (_) => const HomeView()),
      _appRoute('/feed', (_) => const FeedView()),
      _appRoute('/profile', (_) => const ProfileView()),
      _appRoute('/settings', (_) => const SettingsView()),
      _appRoute('/search', (_) => const SearchView()),
      _appRoute('/create', (_) => const EventFormView()),
      _appRoute('/event/:id',
          (s) => EventDetailView(eventId: s.pathParameters['id']!)),
      _appRoute('/event/:id/edit',
          (s) => EventFormView(eventId: s.pathParameters['id'])),
      _appRoute('/event/:id/invites',
          (s) => InvitesView(eventId: s.pathParameters['id']!)),
      _appRoute('/event/:id/roster',
          (s) => RosterView(eventId: s.pathParameters['id']!)),
      _appRoute('/event/:id/scan',
          (s) => ScannerView(eventId: s.pathParameters['id']!)),
      _appRoute('/event/:id/analytics',
          (s) => AnalyticsView(eventId: s.pathParameters['id']!)),
      _appRoute('/event/:id/reviews',
          (s) => ReviewsView(eventId: s.pathParameters['id']!)),
      _appRoute('/pass/:eventId',
          (s) => PassView(eventId: s.pathParameters['eventId']!)),
      _appRoute('/compose',
          (s) => ComposePostView(initialEventId: s.uri.queryParameters['event'])),
      _appRoute('/post/:id',
          (s) => PostDetailView(postId: s.pathParameters['id']!)),
      _appRoute('/user/:id',
          (s) => ProfileView(userId: s.pathParameters['id'])),
      _appRoute('/rsvps', (_) => const RsvpsView()),
      _appRoute('/history', (_) => const HistoryView()),
      _appRoute('/followed', (_) => const FollowedView()),
      _appRoute('/edit-profile', (_) => const EditProfileView()),
      _appRoute('/builder-setup', (_) => const BuilderSetupView()),
      _appRoute('/notifications', (_) => const NotificationsView()),
      _appRoute('/admin', (_) => const AdminView()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
}
