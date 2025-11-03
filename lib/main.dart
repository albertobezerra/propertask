// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:propertask/screen/dashboard/dashboard_screen.dart';
import 'package:propertask/screen/login/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const android = AndroidInitializationSettings('ic_notification');
  await notifications.initialize(
    const InitializationSettings(android: android),
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PropertaskApp(),
    ),
  );
}

class PropertaskApp extends StatelessWidget {
  const PropertaskApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Propertask',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          final appState = Provider.of<AppState>(context, listen: false);
          if (appState.user == null) {
            appState.setUser(user);
          }

          return Consumer<AppState>(
            builder: (context, appState, child) {
              if (appState.user != null && appState.usuario != null) {
                return const DashboardScreen();
              }
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando perfil...'),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // LIMPA AppState NO LOGOUT
        Provider.of<AppState>(context, listen: false).setUser(null);
        return const LoginScreen();
      },
    );
  }
}
