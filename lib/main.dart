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
// IMPORT OFICIAL DAS LOCALIZAÇÕES
import 'package:flutter_localizations/flutter_localizations.dart';

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
      // Delegates de localização oficiais
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // textos/material widgets
        GlobalWidgetsLocalizations.delegate, // direções/formatos
        GlobalCupertinoLocalizations.delegate, // componentes iOS
      ], // [web:150]
      // Idiomas suportados pelo app
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ], // [web:166]
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _sub;
  bool _authReady = false; // aguarda o 1º evento do auth

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);

    _sub = FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        if (!mounted) return;
        appState.setUser(user);
        if (user != null) {
          await appState.carregarPerfil(user);
        }
        if (mounted && !_authReady) setState(() => _authReady = true);
      },
      onError: (_) {
        if (mounted && !_authReady) setState(() => _authReady = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!_authReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (appState.user == null) {
      return const LoginScreen();
    }
    if (appState.usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appState.usuario!.ativo != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acesso bloqueado'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Sua conta está inativa.\nEntre em contato com o administrador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const DashboardScreen();
  }
}
