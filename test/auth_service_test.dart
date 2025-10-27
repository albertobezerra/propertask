import 'package:flutter_test/flutter_test.dart';
import 'package:propertask/core/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    final authService = AuthService();

    test('Login com credenciais válidas', () async {
      final result = await authService.login(
        email: 'albertofbezerra@gmail.com',
        password: '2532547890', // Substitua pela senha correta
      );
      expect(result, true);
    });

    test('Login com credenciais inválidas', () async {
      final result = await authService.login(
        email: 'invalido@exemplo.com',
        password: 'invalido',
      );
      expect(result, false);
    });
  });
}
