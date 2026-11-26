import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'controllers/app_controller.dart';
import 'core/theme/carps_theme.dart';
import 'repositories/mock_carps_repository.dart';
import 'router.dart';
import 'views/demo/demo_panel.dart';

void main() {
  // TODO(firebase): replace MockCarpsRepository with a Firestore-backed
  // CarpsRepository. Widgets and rules do not need to change.
  final repo = MockCarpsRepository.seeded(DateTime.now());
  final controller = AppController(repo);
  // Dev convenience for screenshots/demos only:
  //   flutter run --dart-define=CARPS_DEMO_USER=u_ana
  const demoUser = String.fromEnvironment('CARPS_DEMO_USER');
  if (demoUser.isNotEmpty && repo.user(demoUser) != null) {
    controller.signIn(demoUser);
  }
  runApp(CarpsApp(controller: controller));
}

class CarpsApp extends StatefulWidget {
  const CarpsApp({super.key, required this.controller});
  final AppController controller;

  @override
  State<CarpsApp> createState() => _CarpsAppState();
}

class _CarpsAppState extends State<CarpsApp> {
  late final GoRouter _router = buildRouter(widget.controller);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: widget.controller,
      child: MaterialApp.router(
        title: 'CARPS',
        debugShowCheckedModeBanner: false,
        theme: carpsLightTheme,
        // Dark mode is a stretch goal; the light theme ships first.
        themeMode: ThemeMode.light,
        routerConfig: _router,
        builder: (context, child) => Stack(
          children: [
            child ?? const SizedBox.shrink(),
            DemoLauncher(router: _router),
          ],
        ),
      ),
    );
  }
}
