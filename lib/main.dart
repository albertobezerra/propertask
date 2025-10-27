import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';
import 'package:propertask/core/services/auth_service.dart';
import 'package:propertask/screen/login_screen.dart';
import 'package:propertask/screen/dashboard_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notificação em segundo plano: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    debugPrint('✅ Firebase inicializado com sucesso');

    // Configurar notificações em segundo plano (adiado)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final authService = AuthService();
    await authService.initializeStructure();
    debugPrint('✅ Inicialização da estrutura concluída');
  } catch (e) {
    debugPrint('❌ Erro ao inicializar Firebase ou estrutura: $e');
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
  }

  // Configurar emulador para testes
  if (const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

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
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'Propertask',
      theme: appState.isDarkMode
          ? ThemeData.dark().copyWith(primaryColor: Colors.blue)
          : ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthWrapper: Aguardando estado de autenticação');
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          debugPrint(
            'AuthWrapper: Usuário autenticado, navegando para Dashboard',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appState.setUser(snapshot.data);
            // Configurar notificações (adiado)
            /*
            FirebaseMessaging.instance.requestPermission();
            FirebaseMessaging.instance.getToken().then((token) {
              if (token != null) {
                debugPrint('Token FCM: $token');
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(snapshot.data!.uid)
                    .set({'fcmToken': token}, SetOptions(merge: true))
                    .catchError((e) {
                  debugPrint('❌ Erro ao salvar token FCM: $e');
                });
              }
            });
            */
          });
          return const DashboardScreen();
        }
        debugPrint(
          'AuthWrapper: Nenhum usuário autenticado, navegando para Login',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.setUser(null);
        });
        return const LoginScreen();
      },
    );
  }
}
