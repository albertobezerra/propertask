// lib/main.dart
import 'dart:async';

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

//
// ✅ NOVO AUTHWRAPPER — 100% funcional e sem erros
//
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<AppState>(context, listen: false);

    // OUVIR APENAS UMA VEZ
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;

      appState.setUser(user);

      if (user != null) {
        await appState.carregarPerfil(user);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.user == null) {
      return const LoginScreen();
    }

    if (appState.usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const DashboardScreen();
  }
}
