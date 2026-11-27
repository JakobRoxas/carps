import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  if (!FirebaseRuntime.enabled) {
    final repo = MockCarpsRepository.seeded(DateTime.now());
    final controller = AppController(repo);
    // Dev convenience for screenshots/demos only:
    //   flutter run --dart-define=CARPS_DEMO_USER=u_ana
    const demoUser = String.fromEnvironment('CARPS_DEMO_USER');
    if (demoUser.isNotEmpty && repo.user(demoUser) != null) {
      controller.signIn(demoUser);
    }
    runApp(CarpsApp(controller: controller));
    return;
  }

  final firebaseApp = await Firebase.initializeApp(
    options: FirebaseRuntime.options,
  );
  final auth = FirebaseAuth.instanceFor(app: firebaseApp);
  final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);
  final functions = FirebaseFunctions.instanceFor(
    app: firebaseApp,
    region: 'asia-southeast1',
  );
  final repo = FirebaseCarpsRepository(
    functions: functions,
    firestore: firestore,
  );
  final authGateway = FirebaseAuthGateway(auth: auth, repository: repo);
  String? restoredUserId;
  try {
    await repo.load();
    restoredUserId = (await authGateway.restoreSession())?.id;
  } on FirebaseFunctionsException {
    // The repository exposes the sync failure in the app banner.
  }
  final controller = AppController(
    repo,
    authGateway: authGateway,
    initialUserId: restoredUserId,
  );
  runApp(CarpsApp(controller: controller, showDemo: false));
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
    return AppScope(
      controller: widget.controller,
      child: MaterialApp.router(
        title: 'CARPS',
        debugShowCheckedModeBanner: false,
        theme: carpsLightTheme,
        // Dark mode is a stretch goal; the light theme ships first.
        themeMode: ThemeMode.light,
        routerConfig: _router,
        builder: (context, child) {
          final error = AppScope.watch(context).repo.persistenceError;
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (widget.showDemo) DemoLauncher(router: _router),
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
    );
  }
}
