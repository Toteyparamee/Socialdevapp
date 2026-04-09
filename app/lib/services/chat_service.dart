import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';
import 'auth_service.dart';
import '../models/chat.dart';

class ChatService extends ChangeNotifier {
  final AuthService _auth;
  List<ChatRoom> _rooms = [];
  bool _isLoading = false;
  String? _error;

  // WebSocket
  WebSocketChannel? _channel;
  bool _wsReady = false; // true only after server sends "connected"
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final _messageController = StreamController<ChatMessage>.broadcast();

  List<ChatRoom> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get wsConnected => _wsReady;
  Stream<ChatMessage> get onMessage => _messageController.stream;

  ChatService(this._auth);

  static const _timeout = Duration(seconds: 10);

  String get _baseUrl => '${ApiConfig.chatUrl}/api/chat';

  String get _wsUrl {
    final httpUrl = ApiConfig.chatUrl;
    final wsScheme = httpUrl.startsWith('https') ? 'wss' : 'ws';
    final host = httpUrl.replaceFirst(RegExp(r'https?://'), '');
    return '$wsScheme://$host/ws?token=${_auth.token}';
  }

  // ── WebSocket ──

  void connectWebSocket() {
    if (_wsReady || _auth.token == null) return;
    // Prevent duplicate connect attempts
    if (_channel != null) return;

    try {
      debugPrint('[ws] connecting to ${_wsUrl.split('?').first}...');
      final uri = Uri.parse(_wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onWsData,
        onError: (e) {
          debugPrint('[ws] stream error: $e');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('[ws] stream done');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('[ws] connect error: $e');
      _handleDisconnect();
    }
  }

  void _onWsData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'connected':
          // Server confirmed WebSocket is ready
          _wsReady = true;
          _pingTimer?.cancel();
          _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
            _wsSend({'type': 'ping'});
          });
          debugPrint('[ws] ready as user ${json['user_id']}');
          notifyListeners();
          break;

        case 'new_message':
          final msg = ChatMessage.fromJson(json['message']);
          _messageController.add(msg);
          fetchRooms(); // update room list order
          break;

        case 'pong':
          break;
      }
    } catch (e) {
      debugPrint('[ws] parse error: $e');
    }
  }

  void _handleDisconnect() {
    _wsReady = false;
    _pingTimer?.cancel();
    _channel = null;
    notifyListeners();

    // Auto-reconnect after 3s
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_wsReady && _auth.token != null) {
        debugPrint('[ws] reconnecting...');
        connectWebSocket();
      }
    });
  }

  void _wsSend(Map<String, dynamic> data) {
    if (_channel != null && _wsReady) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Send message: WS if ready, otherwise REST fallback
  Future<void> sendMessageWs({
    required String toUserId,
    required String content,
    String? imageId,
  }) async {
    final payload = <String, dynamic>{
      'to_user_id': toUserId,
      'content': content,
    };
    if (imageId != null && imageId.isNotEmpty) {
      payload['image_id'] = imageId;
    }

    if (_wsReady) {
      // Client → WebSocket → Backend → DB → Broadcast → Client
      debugPrint('[ws] sending via WebSocket');
      _wsSend({'type': 'send_message', 'payload': payload});
    } else {
      // Fallback: REST → DB, then reload
      debugPrint('[ws] not ready (_wsReady=$_wsReady), using REST fallback');
      final result = await sendMessage(
        toUserId: toUserId,
        content: content,
        imageId: imageId,
      );
      if (result != null) {
        _messageController.add(result);
      }
    }
  }

  void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _wsReady = false;
    _channel?.sink.close();
    _channel = null;
  }

  // ── REST API (history + fallback) ──

  Future<void> fetchRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/rooms'), headers: _auth.authHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _rooms = list.map((j) => ChatRoom.fromJson(j)).toList();
      } else {
        _error = 'ไม่สามารถโหลดแชทได้';
      }
    } catch (e) {
      _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<ChatMessage>> fetchMessages(String roomId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/rooms/$roomId/messages'),
            headers: _auth.authHeaders,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((j) => ChatMessage.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<ChatMessage?> sendMessage({
    required String toUserId,
    required String content,
    String? imageId,
  }) async {
    try {
      final body = <String, dynamic>{
        'to_user_id': toUserId,
        'content': content,
      };
      if (imageId != null) body['image_id'] = imageId;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/messages'),
            headers: _auth.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await fetchRooms();
        return ChatMessage.fromJson(data['message']);
      } else {
        debugPrint('sendMessage failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('sendMessage error: $e');
    }
    return null;
  }

  @override
  void dispose() {
    disconnectWebSocket();
    _messageController.close();
    super.dispose();
  }
}
