import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/activity.dart';
import '../models/evaluation.dart';

class ActivityService extends ChangeNotifier {
  final AuthService _auth;
  List<Activity> _activities = [];
  List<Registration> _myRegistrations = [];
  bool _isLoading = false;
  String? _error;

  List<Activity> get activities => _activities;
  List<Registration> get myRegistrations => _myRegistrations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ActivityService(this._auth);

  static const _timeout = Duration(seconds: 10);

  String get _baseUrl => ApiConfig.activityBase;

  Future<void> fetchActivities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse(_baseUrl), headers: _auth.authHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _activities = list.map((j) => Activity.fromJson(j)).toList();
      } else {
        _error = 'ไม่สามารถโหลดกิจกรรมได้';
      }
    } catch (e) {
      _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Activity?> getActivity(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$id'), headers: _auth.authHeaders)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return Activity.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<Activity?> createActivity({
    required String title,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
    String supervisor = '',
    String supervisorPhone = '',
    required DateTime startAt,
    required DateTime endAt,
    required int maxSlots,
    List<String> imageIds = const [],
    bool isPublic = false,
    int? targetSchoolId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'title': title,
        'description': description,
        'location': location,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
        'max_slots': maxSlots,
        'image_ids': imageIds,
        'supervisor': supervisor,
        'supervisor_phone': supervisorPhone,
        'is_public': isPublic,
      };
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (targetSchoolId != null) body['school_id'] = targetSchoolId;

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _auth.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        await fetchActivities();
        return Activity.fromJson(jsonDecode(response.body));
      } else {
        debugPrint(
          'createActivity failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('createActivity error: $e');
    }
    return null;
  }

  Future<void> fetchMyRegistrations() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/my-registrations'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _myRegistrations = list.map((j) => Registration.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('fetchMyRegistrations error: $e');
    }
    notifyListeners();
  }

  Future<bool> deleteActivity(String activityId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/$activityId'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        _activities.removeWhere((a) => a.id == activityId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateActivity({
    required String id,
    required String title,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
    String supervisor = '',
    String supervisorPhone = '',
    required DateTime startAt,
    required DateTime endAt,
    required int maxSlots,
    List<String> imageIds = const [],
    bool isPublic = false,
    int? targetSchoolId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'title': title,
        'description': description,
        'location': location,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
        'max_slots': maxSlots,
        'image_ids': imageIds,
        'supervisor': supervisor,
        'supervisor_phone': supervisorPhone,
        'is_public': isPublic,
      };
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (targetSchoolId != null) body['school_id'] = targetSchoolId;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/$id'),
            headers: _auth.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        await fetchActivities();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> registerForActivity(String activityId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/$activityId/register'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        await fetchActivities();
        return true;
      }
      return false;
    } catch (_) {}
    return false;
  }

  Future<bool> unregister(String registrationId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/registrations/$registrationId'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _myRegistrations.removeWhere((r) => r.id == registrationId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> submitWork(
    String registrationId, {
    required String content,
    List<String> imageIds = const [],
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/registrations/$registrationId/submit'),
            headers: _auth.authHeaders,
            body: jsonEncode({'content': content, 'image_ids': imageIds}),
          )
          .timeout(_timeout);

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<Submission?> getMySubmission(String registrationId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/registrations/$registrationId/submission'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Submission.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> reviewSubmission(
    String submissionId, {
    required String status,
    required int score,
    required String feedback,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/submissions/$submissionId/review'),
            headers: _auth.authHeaders,
            body: jsonEncode({
              'status': status,
              'score': score,
              'feedback': feedback,
            }),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<ActivityWithSubmissions>> fetchMyActivitySubmissions() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/my-submissions'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((j) => ActivityWithSubmissions.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('fetchMyActivitySubmissions error: $e');
    }
    return [];
  }

  Future<EvaluationForm?> getEvaluationForm(String activityId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$activityId/evaluation-form'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return EvaluationForm.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('getEvaluationForm error: $e');
    }
    return null;
  }

  Future<bool> saveEvaluationForm(
    String activityId,
    List<EvaluationQuestion> questions,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/$activityId/evaluation-form'),
            headers: _auth.authHeaders,
            body: jsonEncode({
              'questions': questions.map((q) => q.toJson()).toList(),
            }),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('saveEvaluationForm error: $e');
    }
    return false;
  }

  Future<EvaluationSubmitResult> submitEvaluationResponse(
    String activityId, {
    required String registrationId,
    required List<EvaluationAnswer> answers,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/$activityId/evaluation-response'),
            headers: _auth.authHeaders,
            body: jsonEncode({
              'registration_id': registrationId,
              'answers': answers.map((a) => a.toJson()).toList(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) return EvaluationSubmitResult.success;
      if (response.statusCode == 409) {
        return EvaluationSubmitResult.alreadySubmitted;
      }
    } catch (e) {
      debugPrint('submitEvaluationResponse error: $e');
    }
    return EvaluationSubmitResult.error;
  }
}

class ActivityWithSubmissions {
  final Activity activity;
  final List<Submission> submissions;

  ActivityWithSubmissions({required this.activity, required this.submissions});

  factory ActivityWithSubmissions.fromJson(Map<String, dynamic> json) {
    final subs = (json['submissions'] as List?) ?? [];
    return ActivityWithSubmissions(
      activity: Activity.fromJson(json),
      submissions: subs.map((s) => Submission.fromJson(s)).toList(),
    );
  }
}
