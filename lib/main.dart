// lib/main.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:propertask/conf/app_theme.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/screen/dashboard/dashboard_screen.dart';
import 'package:propertask/screen/login/login_screen.dart';
import 'package:propertask/screen/tarefas/tarefa_detalhe_screen.dart';

// Plugins globais
final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handler de mensagens em background (Android)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pode adicionar logging/analytics se quiser!
}

Future<void> _initPush() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const initAndroid = AndroidInitializationSettings('ic_notification');
  const initSettings = InitializationSettings(android: initAndroid);
  await notifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (resp) {
      final route = resp.payload ?? '';
      _openRoute(route);
    },
  );

  final android = notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'tarefas_channel',
      'Tarefas',
      description: 'Alertas de tarefas atribuídas',
      importance: Importance.high,
    ),
  );

  FirebaseMessaging.onMessage.listen((msg) async {
    final title = msg.notification?.title ?? 'Nova tarefa';
    final body = msg.notification?.body ?? '';
    final route = msg.data['route'] ?? '';
    await notifications.show(
      msg.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tarefas_channel',
          'Tarefas',
          channelDescription: 'Alertas de tarefas atribuídas',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: route,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    final route = msg.data['route'] ?? '';
    _openRoute(route);
  });

  final initialMsg = await messaging.getInitialMessage();
  if (initialMsg != null) {
    _openRoute(initialMsg.data['route'] ?? '');
  }
}

void _openRoute(String route) {
  if (route.isEmpty) return;
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  if (route.startsWith('/tarefas/')) {
    final id = route.split('/').last;
    nav.push(
      MaterialPageRoute(builder: (_) => TarefaDetalheScreen(tarefaId: id)),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initPush();
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
      navigatorKey: navigatorKey,
      title: 'Propertask',
      theme: appTheme,
      darkTheme: ThemeData.dark(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
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
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);

    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      appState.setUser(user);

      if (user != null) {
        // carrega perfil e empresaId do usuário SEM collectionGroup
        await appState.carregarPerfil(user);
        if (appState.usuario != null) {
          await _saveFcmToken(user, appState.usuario!.empresaId);
        }
      }

      if (mounted && !_authReady) setState(() => _authReady = true);
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

  Future<void> _saveFcmToken(User user, String empresaId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('usuarios')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .set({
            'token': token,
            'plataforma': Platform.operatingSystem,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('empresas')
            .doc(empresaId)
            .collection('usuarios')
            .doc(user.uid)
            .collection('tokens')
            .doc(newToken)
            .set({
              'token': newToken,
              'plataforma': Platform.operatingSystem,
              'atualizadoEm': FieldValue.serverTimestamp(),
            });
      });
    } catch (_) {
      // silencioso
    }
  }
}
