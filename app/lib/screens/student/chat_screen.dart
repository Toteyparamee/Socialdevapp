import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/chat.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_config.dart';

enum TicketStatus { open, inProgress, closed }

// ══════════════════════════════════════════════
//  1. Ticket List Screen (Inbox)
// ══════════════════════════════════════════════

class TicketListScreen extends StatefulWidget {
  final String registrationTitle;
  const TicketListScreen({super.key, required this.registrationTitle});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  Map<String, String> _names = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatService>().fetchRooms();
      await _loadNames();
    });
  }

  Future<void> _loadNames() async {
    final auth = context.read<AuthService>();
    final myId = auth.userId ?? '';
    final rooms = context.read<ChatService>().rooms;
    final ids = rooms.map((r) => r.userA == myId ? r.userB : r.userA).toSet().toList();
    if (ids.isNotEmpty) {
      final names = await auth.lookupUsers(ids);
      if (mounted) setState(() => _names = names);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();
    final auth = context.read<AuthService>();
    final rooms = chatService.rooms;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'แชท',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: chatService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rooms.isEmpty
          ? _buildEmptyState()
          : _buildRoomList(rooms, auth),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ยังไม่มีแชท',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เริ่มแชทกับผู้ดูแลกิจกรรมได้เลย',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<ChatRoom> rooms, AuthService auth) {
    final myId = auth.userId ?? '';
    return RefreshIndicator(
      onRefresh: () => context.read<ChatService>().fetchRooms(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final otherUser = room.userA == myId ? room.userB : room.userA;
          final displayName = _names[otherUser] ?? otherUser;
          return _RoomTile(
            room: room,
            otherUserName: displayName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  roomId: room.id,
                  toUserId: otherUser,
                  ticketTitle: widget.registrationTitle,
                  adminName: displayName,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Room Tile Widget ──
class _RoomTile extends StatelessWidget {
  final ChatRoom room;
  final String otherUserName;
  final VoidCallback onTap;

  const _RoomTile({
    required this.room,
    required this.otherUserName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${room.updatedAt.hour.toString().padLeft(2, '0')}:${room.updatedAt.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  otherUserName.isNotEmpty
                      ? otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  2. Chat Room Screen
// ══════════════════════════════════════════════

class ChatRoomScreen extends StatefulWidget {
  final String? roomId;
  final String? toUserId;
  final String ticketTitle;
  final String adminName;
  final TicketStatus status;

  const ChatRoomScreen({
    super.key,
    this.roomId,
    this.toUserId,
    required this.ticketTitle,
    required this.adminName,
    this.status = TicketStatus.open,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showSend = false;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _currentRoomId;
  StreamSubscription<ChatMessage>? _wsSub;
  String _resolvedName = '';

  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnScale;

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.roomId;

    _textController.addListener(() {
      final show = _textController.text.trim().isNotEmpty;
      if (show != _showSend) setState(() => _showSend = show);
    });

    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _sendBtnScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.elasticOut),
    );

    _resolvedName = widget.adminName;

    // Resolve real name if adminName looks like an ID
    if (widget.toUserId != null && widget.toUserId!.isNotEmpty) {
      context.read<AuthService>().lookupUsers([widget.toUserId!]).then((names) {
        if (mounted) {
          setState(() => _resolvedName = names[widget.toUserId] ?? widget.adminName);
        }
      });
    }

    // Connect WebSocket & listen for new messages
    final chatService = context.read<ChatService>();
    chatService.connectWebSocket();
    _wsSub = chatService.onMessage.listen(_onNewMessage);

    _initRoom();
  }

  Future<void> _initRoom() async {
    debugPrint('[chat] _initRoom: _currentRoomId=$_currentRoomId toUserId=${widget.toUserId}');

    if (_currentRoomId != null) {
      await _loadMessages();
      return;
    }

    final chatService = context.read<ChatService>();
    final myId = context.read<AuthService>().userId ?? '';
    final toId = widget.toUserId ?? '';

    debugPrint('[chat] _initRoom: myId="$myId" toId="$toId"');

    if (toId.isEmpty) {
      debugPrint('[chat] _initRoom: toId is empty, skip');
      setState(() => _isLoading = false);
      return;
    }

    // Fetch rooms and find matching one
    await chatService.fetchRooms();
    debugPrint('[chat] _initRoom: myId="$myId" toId="$toId" rooms=${chatService.rooms.length}');
    for (final room in chatService.rooms) {
      debugPrint('[chat] room: id=${room.id} userA="${room.userA}" userB="${room.userB}"');
      if ((room.userA == myId && room.userB == toId) ||
          (room.userA == toId && room.userB == myId)) {
        _currentRoomId = room.id;
        break;
      }
    }
    debugPrint('[chat] resolved roomId=$_currentRoomId');

    await _loadMessages();
  }

  void _onNewMessage(ChatMessage msg) {
    debugPrint(
      '[chat] new_message: roomId=${msg.roomId} currentRoom=$_currentRoomId',
    );

    // Accept message if: same room, OR no room yet (first message)
    if (_currentRoomId != null && msg.roomId != _currentRoomId) return;

    // Avoid duplicates
    if (_messages.any((m) => m.id == msg.id)) return;

    _currentRoomId ??= msg.roomId;

    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    if (_currentRoomId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final msgs = await context.read<ChatService>().fetchMessages(
      _currentRoomId!,
    );
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    final toUserId = widget.toUserId;
    if (toUserId == null) return;

    // Send via WebSocket (falls back to REST automatically)
    context.read<ChatService>().sendMessageWs(
      toUserId: toUserId,
      content: text,
    );
  }

  Future<void> _pickAndSendImage() async {
    final toUserId = widget.toUserId;
    if (toUserId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    try {
      // Upload to image service
      final uri = Uri.parse('${ApiConfig.imageUrl}/api/images');
      final request = http.MultipartRequest('POST', uri);
      final auth = context.read<AuthService>();
      request.headers.addAll(auth.authHeaders);
      request.fields['folder'] = 'chat';

      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
          ? 'image/webp'
          : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: picked.name,
          contentType: MediaType.parse(mime),
        ),
      );

      final streamed = await request.send();
      if (streamed.statusCode != 201) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ')));
        }
        return;
      }

      final respBody = await streamed.stream.bytesToString();
      final imgData = jsonDecode(respBody);
      final imageId = imgData['id'] as String;

      // Send message with image via WebSocket
      if (!mounted) return;
      context.read<ChatService>().sendMessageWs(
        toUserId: toUserId,
        content: '',
        imageId: imageId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เชื่อมต่อ image service ไม่ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthService>().userId ?? '';

    if (_showSend) {
      _sendBtnController.forward();
    } else {
      _sendBtnController.reverse();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _resolvedName.isNotEmpty
                      ? _resolvedName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _resolvedName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: Column(
        children: [
          // Ticket title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(Icons.label_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.ticketTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'ยังไม่มีข้อความ เริ่มพิมพ์ได้เลย',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == myId;
                      final prevMsg = index > 0 ? _messages[index - 1] : null;
                      final showSender =
                          prevMsg == null || (prevMsg.senderId == myId) != isMe;

                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showSender: showSender,
                        adminName: _resolvedName,
                        timeStr: _formatTime(msg.createdAt),
                      );
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach image
                GestureDetector(
                  onTap: _pickAndSendImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.image_rounded,
                      size: 22,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Send button
                ScaleTransition(
                  scale: _sendBtnScale,
                  child: GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ──
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final String adminName;
  final String timeStr;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSender,
    required this.adminName,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showSender ? 12 : 4,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Sender label
          if (showSender && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                adminName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),

          // Image bubble
          if (message.imageId != null)
            Container(
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(
                    message.content.isNotEmpty ? 4 : (isMe ? 18 : 4),
                  ),
                  bottomRight: Radius.circular(
                    message.content.isNotEmpty ? 4 : (isMe ? 4 : 18),
                  ),
                ),
                boxShadow: isMe
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _ChatImageWidget(imageId: message.imageId!),
              ),
            ),

          // Text bubble
          if (message.content.isNotEmpty)
            Container(
              margin: message.imageId != null
                  ? const EdgeInsets.only(top: 2)
                  : EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isMe
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),

          // Time + read status
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readAt != null
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: message.readAt != null
                        ? AppTheme.primary
                        : Colors.grey.shade400,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Image Widget — fetches presigned URL then displays ──
class _ChatImageWidget extends StatefulWidget {
  final String imageId;
  const _ChatImageWidget({required this.imageId});

  @override
  State<_ChatImageWidget> createState() => _ChatImageWidgetState();
}

class _ChatImageWidgetState extends State<_ChatImageWidget> {
  String? _imageUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  Future<void> _fetchUrl() async {
    try {
      final auth = context.read<AuthService>();
      final resp = await http.get(
        Uri.parse('${ApiConfig.imageUrl}/api/images/${widget.imageId}/url'),
        headers: auth.authHeaders,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) setState(() => _imageUrl = data['url']);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: 220,
        height: 165,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_imageUrl == null) {
      return Container(
        width: 220,
        height: 165,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.broken_image_rounded,
          size: 40,
          color: Color(0xFFD1D5DB),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        _imageUrl!,
        width: 220,
        height: 165,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 165,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.broken_image_rounded,
            size: 40,
            color: Color(0xFFD1D5DB),
          ),
        ),
      ),
    );
  }
}
