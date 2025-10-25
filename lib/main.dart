import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:propertask/core/services/auth_service.dart';
import 'package:propertask/screen/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase inicializado com sucesso');

    final authService = AuthService();
    await authService.initializeStructure();
    debugPrint('✅ Inicialização da estrutura concluída');
  } catch (e) {
    debugPrint('❌ Erro ao inicializar Firebase ou estrutura: $e');
  }

  runApp(const PropertaskApp());
}

class PropertaskApp extends StatelessWidget {
  const PropertaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Propertask',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
