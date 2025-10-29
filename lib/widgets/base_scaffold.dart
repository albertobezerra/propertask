// lib/widgets/base_scaffold.dart
import 'package:flutter/material.dart';
import 'app_drawer.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final String currentRoute;
  final FloatingActionButton? fab;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentRoute,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: body,
      floatingActionButton: fab,
    );
  }
}
