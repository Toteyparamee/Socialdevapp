import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/problem_report.dart';

class ProblemService extends ChangeNotifier {
  final AuthService _auth;
  List<ProblemReport> _problems = [];
  bool _isLoading = false;
  String? _error;

  List<ProblemReport> get problems => _problems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProblemService(this._auth);

  static const _timeout = Duration(seconds: 10);

  String get _baseUrl => '${ApiConfig.problemUrl}/api/problems';

  Future<void> fetchProblems({String? category, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (category != null) params['category'] = category;
      if (status != null) params['status'] = status;

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _problems = list.map((j) => ProblemReport.fromJson(j)).toList();
      } else {
        _error = 'ไม่สามารถโหลดข้อมูลได้';
      }
    } catch (e) {
      _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ProblemReport?> getProblem(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$id')).timeout(_timeout);
      if (response.statusCode == 200) {
        return ProblemReport.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> createProblem(ProblemReport problem) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _auth.authHeaders,
            body: jsonEncode(problem.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        await fetchProblems();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/$id/status'),
            headers: _auth.authHeaders,
            body: jsonEncode({'status': status}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        await fetchProblems();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteProblem(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/$id'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        await fetchProblems();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
