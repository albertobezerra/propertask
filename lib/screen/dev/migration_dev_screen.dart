import 'package:flutter/material.dart';
import 'package:propertask/core/services/migration_service.dart';

class MigrationDevScreen extends StatefulWidget {
  const MigrationDevScreen({super.key});

  @override
  State<MigrationDevScreen> createState() => _MigrationDevScreenState();
}

class _MigrationDevScreenState extends State<MigrationDevScreen> {
  String status = '';

  Future<void> migrar() async {
    setState(() => status = 'Iniciando migração...');
    try {
      final migrationService = MigrationService();
      await migrationService.migrarEmpresaUnicaParaMultiEmpresa(
        empresaId: 'Kilometros',
      );
      setState(() => status = 'Migração concluída!');
    } catch (e) {
      setState(() => status = 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Migração DEV')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: migrar,
              child: const Text(
                'Rodar Migração',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(status, style: const TextStyle(fontSize: 17)),
          ],
        ),
      ),
    );
  }
}
