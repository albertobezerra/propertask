// lib/screen/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:propertask/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:propertask/core/providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_loading) return;
    setState(() => _loading = true);

    // Capture dependências antes do await para evitar o lint de contexto
    final messenger = ScaffoldMessenger.of(
      context,
    ); // OK após await pois foi capturado antes [web:43]
    final appState = Provider.of<AppState>(context, listen: false);

    final success = await AuthService.login(_email.text.trim(), _senha.text);

    if (!mounted) return; // guarda o uso do State.context após await [web:43]

    if (success) {
      // Salva a senha em memória para reautenticação na criação de convites
      appState.setSenhaUsuario(_senha.text);
      // Não navegar manualmente: AuthWrapper decide a tela seguinte [web:106]
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Email ou senha incorretos'),
          backgroundColor: Colors.red,
        ),
      ); // UI de falha simples; inativos serão bloqueados no AuthWrapper [web:106]
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propertask'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cleaning_services, size: 80, color: Colors.blue),
            const SizedBox(height: 40),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email', Icons.email),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senha,
              obscureText: true,
              decoration: _inputDecoration('Senha', Icons.lock),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }
}
