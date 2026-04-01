import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUsername = 'username';
  static const _keyRole = 'user_role';

  bool _isLoggedIn = false;
  String? _username;
  String? _role;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get role => _role;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _username = prefs.getString(_keyUsername);
    _role = prefs.getString(_keyRole);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, role);

    _isLoggedIn = true;
    _username = username;
    _role = role;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _username = null;
    _role = null;
    notifyListeners();
  }
}
