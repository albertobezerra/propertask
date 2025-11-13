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
  bool _senhaVisivel = false;
  bool _sendingReset = false;

  // Troque AuthService.login conforme o seu provider!
  Future<void> _login() async {
    if (_loading) return;
    setState(() => _loading = true);

    final messenger = ScaffoldMessenger.of(context);
    final appState = Provider.of<AppState>(context, listen: false);

    final success = await AuthService.login(_email.text.trim(), _senha.text);

    if (!mounted) return;

    if (success) {
      appState.setSenhaUsuario(_senha.text);
      // AuthWrapper decide a tela seguinte
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Email ou senha incorretos'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _esqueciSenha() async {
    final email = _email.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Digite seu email para recuperar a senha'),
        ),
      );
      return;
    }
    setState(() => _sendingReset = true);
    try {
      await AuthService.esqueciSenha(
        email,
      ); // Ou use FirebaseAuth.instance.sendPasswordResetEmail(email: email)
      messenger.showSnackBar(
        SnackBar(content: Text('Email de redefinição enviado para $email')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Falha ao enviar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _sendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Propertask'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cleaning_services, size: 80, color: cs.primary),
                const SizedBox(height: 44),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email', Icons.email),
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _senha,
                  obscureText: !_senhaVisivel,
                  decoration: _inputDecoration('Senha', Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _senhaVisivel
                          ? 'Ocultar senha'
                          : 'Mostrar senha',
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                        color: cs.primary,
                      ),
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _sendingReset ? null : _esqueciSenha,
                    icon: _sendingReset
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.help_outline),
                    label: const Text('Esqueci a senha'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      textStyle: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
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
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }
}
