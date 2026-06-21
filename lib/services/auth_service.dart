import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'api_config.dart';

class AuthService extends ChangeNotifier {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUsername = 'username';
  static const _keyEmail = 'email';
  static const _keyRole = 'user_role';
  static const _keyToken = 'jwt_token';
  static const _keyAvatarUrl = 'avatar_url';
  static const _keyUserId = 'user_id';
  static const _keySchoolId = 'school_id';
  static const _keySchoolName = 'school_name';

  // ── Config ──
  static String get _baseUrl => ApiConfig.loginUrl;
  static const String _auth0Domain = 'dev-p6m40iaxhz0i543y.us.auth0.com';
  static const String _auth0ClientId = 'aBJe4HwBKfZ98XiWgfVKios2UrGx6PU3';
  static const String _auth0RedirectUri = 'com.socialdev.app://login-callback';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  String? _role;
  String? _token;
  String? _avatarUrl;
  String? _userId;
  int? _schoolId;
  String? _schoolName;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;
  String? get token => _token;
  String? get avatarUrl => _avatarUrl;
  String? get userId => _userId;
  int? get schoolId => _schoolId;
  String? get schoolName => _schoolName;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _username = prefs.getString(_keyUsername);
    _email = prefs.getString(_keyEmail);
    _role = prefs.getString(_keyRole);
    _token = prefs.getString(_keyToken);
    _avatarUrl = prefs.getString(_keyAvatarUrl);
    _userId = prefs.getString(_keyUserId);
    _schoolId = prefs.getInt(_keySchoolId);
    _schoolName = prefs.getString(_keySchoolName);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveSession({
    required String username,
    required String role,
    required String token,
    String? email,
    String? avatarUrl,
    String? userId,
    int? schoolId,
    String? schoolName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyToken, token);
    if (email != null) await prefs.setString(_keyEmail, email);
    if (avatarUrl != null) await prefs.setString(_keyAvatarUrl, avatarUrl);
    if (userId != null) await prefs.setString(_keyUserId, userId);
    if (schoolId != null) await prefs.setInt(_keySchoolId, schoolId);
    if (schoolName != null) await prefs.setString(_keySchoolName, schoolName);

    _isLoggedIn = true;
    _username = username;
    _email = email;
    _role = role;
    _token = token;
    _avatarUrl = avatarUrl;
    _userId = userId;
    _schoolId = schoolId;
    _schoolName = schoolName;
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
        email: data['user']['email'] as String?,
        role: data['user']['role'],
        token: data['token'],
        avatarUrl: data['user']['avatar_url'],
        userId: data['user']['id']?.toString(),
        schoolId: data['user']['school_id'] is int ? data['user']['school_id'] as int : int.tryParse(data['user']['school_id']?.toString() ?? ''),
        schoolName: (data['school_name'] as String?)?.isNotEmpty == true ? data['school_name'] as String : data['user']['school_name'] as String?,
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
    int schoolId = 0,
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
            'school_id': schoolId,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveSession(
        username: data['user']['username'],
        email: data['user']['email'] as String?,
        role: data['user']['role'],
        token: data['token'],
        userId: data['user']['id']?.toString(),
        schoolId: data['user']['school_id'] is int ? data['user']['school_id'] as int : int.tryParse(data['user']['school_id']?.toString() ?? ''),
        schoolName: (data['school_name'] as String?)?.isNotEmpty == true ? data['school_name'] as String : data['user']['school_name'] as String?,
      );
    } else {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'สมัครสมาชิกไม่สำเร็จ');
    }
  }

  // ── Login with Google (ผ่าน Auth0) ──
  Future<void> loginWithGoogle({String role = 'นักเรียน'}) async {
    final AuthorizationTokenResponse result;
    try {
      result = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              _auth0ClientId,
              _auth0RedirectUri,
              issuer: 'https://$_auth0Domain',
              scopes: ['openid', 'profile', 'email'],
              additionalParameters: {'connection': 'google-oauth2'},
            ),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw AuthException('Google login หมดเวลา กรุณาลองใหม่');
    } on PlatformException catch (e) {
      if (e.code == 'org.openid.appauth.general' ||
          (e.message ?? '').contains('cancel') ||
          (e.message ?? '').contains('User cancelled')) {
        throw AuthException('ยกเลิก Google login');
      }
      throw AuthException('Google login ไม่สำเร็จ: ${e.message}');
    }

    if (result.accessToken == null) {
      throw AuthException('Google login ถูกยกเลิก');
    }

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
        email: data['user']['email'] as String?,
        role: data['user']['role'],
        token: data['token'],
        avatarUrl: data['user']['avatar_url'],
        userId: data['user']['id']?.toString(),
        schoolId: data['user']['school_id'] is int ? data['user']['school_id'] as int : int.tryParse(data['user']['school_id']?.toString() ?? ''),
        schoolName: (data['school_name'] as String?)?.isNotEmpty == true ? data['school_name'] as String : data['user']['school_name'] as String?,
      );
    } else {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'Google login ไม่สำเร็จ');
    }
  }

  // ── Update username ──
  Future<void> updateUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    _username = username;
    notifyListeners();
  }

  // ── Update school ──
  Future<void> updateSchool(int schoolId, String schoolName) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/users/profile'),
          headers: authHeaders,
          body: jsonEncode({'school_id': schoolId}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'อัปเดตโรงเรียนไม่สำเร็จ');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySchoolId, schoolId);
    await prefs.setString(_keySchoolName, schoolName);
    _schoolId = schoolId;
    _schoolName = schoolName;
    notifyListeners();
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
    _userId = null;
    _schoolId = null;
    _schoolName = null;
    notifyListeners();
  }

  // ── Helper: สร้าง header สำหรับ protected API ──
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Lookup usernames by IDs (cached) ──
  final Map<String, String> _nameCache = {};

  Future<Map<String, String>> lookupUsers(List<String> ids) async {
    final missing = ids.where((id) => !_nameCache.containsKey(id)).toList();

    if (missing.isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/users/lookup'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'ids': missing}),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          for (final entry in data.entries) {
            _nameCache[entry.key] = (entry.value['username'] as String?) ?? 'User ${entry.key}';
          }
        }
      } catch (_) {}

      for (final id in missing) {
        _nameCache.putIfAbsent(id, () => 'User $id');
      }
    }

    return {for (final id in ids) id: _nameCache[id] ?? 'User $id'};
  }

  String getCachedName(String userId) => _nameCache[userId] ?? userId;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
