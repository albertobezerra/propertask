import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsuarioDetalheScreen extends StatelessWidget {
  final DocumentSnapshot usuario;
  const UsuarioDetalheScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final data = usuario.data() as Map<String, dynamic>;
    final nome = data['nome'] ?? 'Sem nome';
    final email = data['email'] ?? 'Sem email';
    final cargo = data['cargo'] ?? 'LIMPEZA';
    final ativo = data['ativo'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(nome)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Nome', nome),
            _infoRow('Email', email),
            _infoRow('Cargo', cargo),
            _infoRow(
              'Status',
              ativo ? 'Ativo' : 'Inativo',
              color: ativo ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
