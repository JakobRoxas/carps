import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseOptions;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/app_controller.dart';
import 'core/theme/carps_theme.dart';
import 'firebase/firebase_runtime.dart';
import 'repositories/firebase_carps_repository.dart';
import 'repositories/mock_carps_repository.dart';
import 'router.dart';
import 'services/firebase_auth_gateway.dart';
import 'views/demo/demo_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  if (FirebaseRuntime.useMockData) {
    final controller = AppController(
      MockCarpsRepository.seeded(DateTime.now()),
      clock: DateTime.now,
      initialDarkMode:
          preferences.getBool(AppController.darkModePreferenceKey) ?? false,
      preferences: preferences,
    );
    runApp(CarpsApp(controller: controller));
    return;
  }

  late final FirebaseOptions options;
  try {
    options = FirebaseRuntime.options;
  } on UnsupportedError {
    runApp(const FirebaseSetupRequiredApp());
    return;
  }

  final firebaseApp = await Firebase.initializeApp(
    options: options,
    name: FirebaseRuntime.useEmulators ? 'carps-emulator' : null,
  );
  final auth = FirebaseAuth.instanceFor(app: firebaseApp);
  final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);
  if (FirebaseRuntime.useEmulators) {
    await auth.useAuthEmulator('localhost', 9099);
    firestore.useFirestoreEmulator('localhost', 8080);
  }
  final repo = FirebaseCarpsRepository(firestore: firestore);
  final authGateway = FirebaseAuthGateway(auth: auth, repository: repo);
  final restoredUserId = (await authGateway.restoreSession())?.id;
  final controller = AppController(
    repo,
    authGateway: authGateway,
    initialUserId: restoredUserId,
    initialDarkMode:
        preferences.getBool(AppController.darkModePreferenceKey) ?? false,
    preferences: preferences,
  );
  runApp(CarpsApp(controller: controller, showDemo: false));
}

class FirebaseSetupRequiredApp extends StatelessWidget {
  const FirebaseSetupRequiredApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase mobile setup required',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Android and iOS Firebase apps are not configured. Register both apps in Firebase, run flutterfire configure for this project, then rebuild without USE_MOCK_DATA.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'For camera-only testing with sample accounts, build with --dart-define=USE_MOCK_DATA=true. That mode does not sign in to Firebase.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CarpsApp extends StatefulWidget {
  const CarpsApp({super.key, required this.controller, this.showDemo = true});

  final AppController controller;
  final bool showDemo;

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
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => AppScope(
        controller: widget.controller,
        child: MaterialApp.router(
          title: 'CARPS',
          debugShowCheckedModeBanner: false,
          theme: carpsLightTheme,
          darkTheme: carpsDarkTheme,
          themeMode: widget.controller.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          routerConfig: _router,
          builder: (context, child) {
            final error = AppScope.watch(context).persistenceError;
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (widget.showDemo) DemoLauncher(router: _router),
                if (FirebaseRuntime.useMockData)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: MediaQuery.paddingOf(context).top + 8,
                    child: IgnorePointer(
                      child: Material(
                        color: const Color(0xFFFFE7B3),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'LOCAL DEMO — Firebase sign-in is disabled',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF3D2B00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (error != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: MediaQuery.paddingOf(context).top + 8,
                    child: Material(
                      color: const Color(0xFF8F1D1D),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Server sync issue: $error',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
