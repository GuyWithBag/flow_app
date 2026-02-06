import 'package:flutter/foundation.dart';

import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

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
    notifyListeners();
  }
}
