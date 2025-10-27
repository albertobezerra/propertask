import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState with ChangeNotifier {
  User? _user;
  bool _isDarkMode = false;

  User? get user => _user;
  bool get isDarkMode => _isDarkMode;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
