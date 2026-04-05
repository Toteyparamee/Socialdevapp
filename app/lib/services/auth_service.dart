import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';

class AuthService extends ChangeNotifier {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUsername = 'username';
  static const _keyRole = 'user_role';
  static const _keyToken = 'jwt_token';
  static const _keyAvatarUrl = 'avatar_url';

  // ── Config ──
  static final String _baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8000' // Android emulator
      : 'http://localhost:8000'; // iOS simulator
  static const String _auth0Domain = 'dev-p6m40iaxhz0i543y.us.auth0.com';
  static const String _auth0ClientId = 'aBJe4HwBKfZ98XiWgfVKios2UrGx6PU3';
  static const String _auth0RedirectUri = 'com.socialdev.app://login-callback';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  bool _isLoggedIn = false;
  String? _username;
  String? _role;
  String? _token;
  String? _avatarUrl;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get role => _role;
  String? get token => _token;
  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _username = prefs.getString(_keyUsername);
    _role = prefs.getString(_keyRole);
    _token = prefs.getString(_keyToken);
    _avatarUrl = prefs.getString(_keyAvatarUrl);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveSession({
    required String username,
    required String role,
    required String token,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyToken, token);
    if (avatarUrl != null) {
      await prefs.setString(_keyAvatarUrl, avatarUrl);
    }

    _isLoggedIn = true;
    _username = username;
    _role = role;
    _token = token;
    _avatarUrl = avatarUrl;
    notifyListeners();
  }

  static const _timeout = Duration(seconds: 10);

  // ── Login ธรรมดา (username + password) ──
  Future<void> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSession(
        username: data['user']['username'],
        role: data['user']['role'],
        token: data['token'],
        avatarUrl: data['user']['avatar_url'],
      );
    } else {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
    }
  }

  // ── สมัครสมาชิก ──
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'role': role,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveSession(
        username: data['user']['username'],
        role: data['user']['role'],
        token: data['token'],
      );
    } else {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'สมัครสมาชิกไม่สำเร็จ');
    }
  }

  // ── Login with Google (ผ่าน Auth0) ──
  Future<void> loginWithGoogle({String role = 'นักเรียน'}) async {
    // Step 1: เปิด Auth0 login → ได้ access_token
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _auth0ClientId,
        _auth0RedirectUri,
        issuer: 'https://$_auth0Domain',
        scopes: ['openid', 'profile', 'email'],
        additionalParameters: {'connection': 'google-oauth2'},
      ),
    );

    if (result.accessToken == null) {
      throw AuthException('Google login ถูกยกเลิก');
    }

    // Step 2: ส่ง access_token ไป backend เพื่อ verify + สร้าง JWT
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'access_token': result.accessToken, 'role': role}),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSession(
        username: data['user']['username'],
        role: data['user']['role'],
        token: data['token'],
        avatarUrl: data['user']['avatar_url'],
      );
    } else {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'Google login ไม่สำเร็จ');
    }
  }

  // ── Logout ──
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _username = null;
    _role = null;
    _token = null;
    _avatarUrl = null;
    notifyListeners();
  }

  // ── Helper: สร้าง header สำหรับ protected API ──
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
