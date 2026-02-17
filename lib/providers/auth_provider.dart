import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/models.barrel.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUser();
  }

  void _loadUser() {
    final box = Hive.box('auth');
    final raw = box.get('auth_user') as String?;
    if (raw != null && raw.isNotEmpty) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _currentUser = UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        dailyGoal: json['daily_goal'] as int? ?? 120,
        streak: json['streak'] as int? ?? 0,
      );
    }
  }

  Future<void> _saveUser() async {
    final box = Hive.box('auth');
    if (_currentUser != null) {
      final json = {
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'name': _currentUser!.name,
        'daily_goal': _currentUser!.dailyGoal,
        'streak': _currentUser!.streak,
      };
      await box.put('auth_user', jsonEncode(json));
    } else {
      await box.delete('auth_user');
    }
  }

  // Mock login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      _currentUser = UserProfile(
        id: 'mock_user_123',
        email: email,
        name: email.split('@')[0],
        dailyGoal: 120,
        streak: 5,
      );
      await _saveUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mock signup
  Future<void> signup(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = UserProfile(
        id: 'mock_user_new',
        email: email,
        name: email.split('@')[0],
      );
      await _saveUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Anonymous login
  // Future<void> loginAnonymously() async {
  //   _isLoading = true;
  //   notifyListeners();

  //   try {
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     _currentUser = UserProfile(
  //       id: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
  //       email: 'anonymous@flow.app',
  //       name: 'Guest User',
  //     );
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> logout() async {
    _currentUser = null;
    await _saveUser();
    notifyListeners();
  }
}
