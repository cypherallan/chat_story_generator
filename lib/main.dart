import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app/app_initializer.dart';
import 'core/auth/auth_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home_management/presentation/pages/home_page.dart';
import 'injection_container.dart' as di;
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInitializer.initialize();

  // REAL system bars - no fake
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // dark icons for light status
    statusBarBrightness: Brightness.light, // iOS
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Story Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final authService = di.sl<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Authentication error:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return LoginPage(
            authService: authService,
          );
        }

        return const HomePage();
      },
    );
  }
}
