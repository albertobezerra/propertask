import 'package:flutter/material.dart';
import 'package:propertask/core/services/auth_service.dart';
import 'package:propertask/screen/dashboard_screen.dart';
import 'package:propertask/widgets/custom_text_field.dart';
import 'package:propertask/widgets/loading_widget.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email ou senha incorretos, ou usuário não registrado.',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('✅ Navegando para Dashboard');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      debugPrint('❌ Erro ao fazer login: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer login: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LoginScreen: Iniciando build');
    return Scaffold(
      appBar: AppBar(title: const Text('Propertask - Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const LoadingWidget()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Senha',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Entrar'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
