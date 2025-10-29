// lib/screen/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:propertask/widgets/app_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final userRef = FirebaseFirestore.instance
        .collection('propertask')
        .doc('usuarios')
        .collection('usuarios')
        .doc(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      drawer: const AppDrawer(currentRoute: '/perfil'),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  data['nome']?[0].toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 50, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),
              _info('Nome', data['nome'] ?? 'Não informado'),
              _info('Email', data['email'] ?? user.email ?? 'Não informado'),
              _info('Cargo', data['cargo'] ?? 'Colaborador'),
              _info('Telefone', data['telefone'] ?? 'Não informado'),
            ],
          );
        },
      ),
    );
  }

  Widget _info(String label, String value) {
    return Card(
      child: ListTile(
        leading: Icon(_icon(label), color: Colors.blue),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  IconData _icon(String label) {
    switch (label) {
      case 'Nome':
        return Icons.person;
      case 'Email':
        return Icons.email;
      case 'Cargo':
        return Icons.work;
      case 'Telefone':
        return Icons.phone;
      default:
        return Icons.info;
    }
  }
}
