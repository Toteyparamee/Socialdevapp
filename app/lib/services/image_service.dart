import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class ImageService {
  final AuthService _auth;

  static const _timeout = Duration(seconds: 10);
  String get _base => ApiConfig.imageBase;

  ImageService(this._auth);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${_auth.token}',
        'Content-Type': 'application/json',
      };

  /// Upload image file, returns image metadata including id
  Future<Map<String, dynamic>> upload(File file, {String folder = 'uploads'}) async {
    final uri = Uri.parse(_base);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${_auth.token}'
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(_timeout);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 201) {
      throw Exception('Upload failed: $body');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Get direct image URL — no auth required, served by backend proxy
  String getImageUrl(String imageId) => '$_base/$imageId/data';

  /// List images owned by current user
  Future<List<Map<String, dynamic>>> list() async {
    final res = await http
        .get(Uri.parse(_base), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Failed to list images');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  /// Delete image by id
  Future<void> delete(String imageId) async {
    final res = await http
        .delete(Uri.parse('$_base/$imageId'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Failed to delete image');
  }
}
