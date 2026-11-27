import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'controllers/app_controller.dart';
import 'core/theme/carps_theme.dart';
import 'firebase/firebase_runtime.dart';
import 'repositories/firebase_carps_repository.dart';
import 'router.dart';
import 'services/firebase_auth_gateway.dart';
import 'views/demo/demo_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseApp = await Firebase.initializeApp(
    options: FirebaseRuntime.options,
    name: FirebaseRuntime.useEmulators ? 'carps-emulator' : null,
  );
  final auth = FirebaseAuth.instanceFor(app: firebaseApp);
  final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);
  if (FirebaseRuntime.useEmulators) {
    await auth.useAuthEmulator('localhost', 9099);
    firestore.useFirestoreEmulator('localhost', 8080);
  }
  final repo = FirebaseCarpsRepository(
    firestore: firestore,
  );
  final authGateway = FirebaseAuthGateway(auth: auth, repository: repo);
  final restoredUserId = (await authGateway.restoreSession())?.id;
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
