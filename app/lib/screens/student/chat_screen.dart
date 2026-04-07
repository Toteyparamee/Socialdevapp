import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ══════════════════════════════════════════════
//  Mock Data
// ══════════════════════════════════════════════

enum TicketStatus { open, inProgress, closed }

class _TicketData {
  final String id;
  final String title;
  final TicketStatus status;
  final String lastMessage;
  final String time;
  final int unread;
  final String adminName;

  const _TicketData({
    required this.id,
    required this.title,
    required this.status,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.adminName = 'แอดมิน',
  });
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final String? imageUrl;
  final bool isRead;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.imageUrl,
    this.isRead = false,
  });
}

// ══════════════════════════════════════════════
//  1. Ticket List Screen (Inbox)
// ══════════════════════════════════════════════

class TicketListScreen extends StatefulWidget {
  final String registrationTitle;
  const TicketListScreen({super.key, required this.registrationTitle});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _shimmerController;

  final _tickets = <_TicketData>[
    _TicketData(
      id: '1',
      title: 'สอบถามรายละเอียดกิจกรรม',
      status: TicketStatus.open,
      lastMessage: 'ขอสอบถามเรื่องเวลาเริ่มกิจกรรมครับ',
      time: '10:30',
      unread: 2,
      adminName: 'อ.สมชาย',
    ),
    _TicketData(
      id: '2',
      title: 'แจ้งปัญหาการลงทะเบียน',
      status: TicketStatus.inProgress,
      lastMessage: 'รับทราบครับ กำลังตรวจสอบให้',
      time: 'เมื่อวาน',
      unread: 0,
      adminName: 'แอดมิน',
    ),
    _TicketData(
      id: '3',
      title: 'ขอเปลี่ยนกลุ่มกิจกรรม',
      status: TicketStatus.closed,
      lastMessage: 'เรียบร้อยแล้วครับ ขอบคุณที่แจ้ง',
      time: '2 เม.ย.',
      unread: 0,
      adminName: 'อ.วิภา',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Simulate loading
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color _statusColor(TicketStatus s) => switch (s) {
    TicketStatus.open => const Color(0xFF10B981),
    TicketStatus.inProgress => const Color(0xFFFBBF24),
    TicketStatus.closed => const Color(0xFF9CA3AF),
  };

  String _statusLabel(TicketStatus s) => switch (s) {
    TicketStatus.open => 'เปิด',
    TicketStatus.inProgress => 'กำลังดำเนินการ',
    TicketStatus.closed => 'ปิดแล้ว',
  };

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? _buildSkeleton()
          : _tickets.isEmpty
          ? _buildEmptyState()
          : _buildTicketList(),
    );
  }

  // ── Skeleton Loading ──
  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Avatar skeleton
                  _shimmerBox(48, 48, isCircle: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(14, 160),
                        const SizedBox(height: 8),
                        _shimmerBox(12, 220),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _shimmerBox(double h, double w, {bool isCircle = false}) {
    final progress = _shimmerController.value;
    final shimmerOpacity = 0.06 + 0.06 * math.sin(progress * math.pi * 2);
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Color.lerp(
          const Color(0xFFE8ECF0),
          const Color(0xFFF3F4F6),
          shimmerOpacity * 10,
        ),
        borderRadius: isCircle ? null : BorderRadius.circular(6),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }

  // ── Empty State ──
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

  // ── Ticket List ──
  Widget _buildTicketList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _TicketTile(
          ticket: ticket,
          statusColor: _statusColor(ticket.status),
          statusLabel: _statusLabel(ticket.status),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                ticketTitle: ticket.title,
                status: ticket.status,
                adminName: ticket.adminName,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Ticket Tile Widget ──
class _TicketTile extends StatelessWidget {
  final _TicketData ticket;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _TicketTile({
    required this.ticket,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: ticket.unread > 0
              ? Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
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
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  ticket.adminName.characters.first,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: ticket.unread > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticket.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: ticket.unread > 0
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                          fontWeight: ticket.unread > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ticket.lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: ticket.unread > 0
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: ticket.unread > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Unread badge
                      if (ticket.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${ticket.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
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
  final String ticketTitle;
  final TicketStatus status;
  final String adminName;

  const ChatRoomScreen({
    super.key,
    required this.ticketTitle,
    required this.status,
    required this.adminName,
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

  final _messages = <_ChatMessage>[
    _ChatMessage(
      text: 'สวัสดีครับ มีอะไรให้ช่วยไหมครับ?',
      isMe: false,
      time: '10:00',
    ),
    _ChatMessage(
      text: 'สวัสดีครับ อยากสอบถามเรื่องเวลาเริ่มกิจกรรมครับ',
      isMe: true,
      time: '10:02',
      isRead: true,
    ),
    _ChatMessage(
      text: 'กิจกรรมเริ่ม 9:00 น. ลงทะเบียนหน้างาน 8:30 น. ครับ',
      isMe: false,
      time: '10:05',
    ),
    _ChatMessage(
      text: 'ต้องเตรียมอะไรไปบ้างครับ?',
      isMe: true,
      time: '10:06',
      isRead: true,
    ),
    _ChatMessage(
      text: '',
      isMe: false,
      time: '10:08',
      imageUrl: 'https://picsum.photos/seed/chat1/400/300',
    ),
    _ChatMessage(
      text: 'นี่คือรายการสิ่งของที่ต้องเตรียมครับ ดูจากรูปได้เลย',
      isMe: false,
      time: '10:08',
    ),
    _ChatMessage(
      text: 'รับทราบครับ ขอบคุณมากครับ 🙏',
      isMe: true,
      time: '10:10',
      isRead: false,
    ),
  ];

  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnScale;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isMe: true,
          time: TimeOfDay.now().format(context),
        ),
      );
      _textController.clear();
    });

    // Scroll to bottom
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

  Color _statusColor(TicketStatus s) => switch (s) {
    TicketStatus.open => const Color(0xFF10B981),
    TicketStatus.inProgress => const Color(0xFFFBBF24),
    TicketStatus.closed => const Color(0xFF9CA3AF),
  };

  String _statusLabel(TicketStatus s) => switch (s) {
    TicketStatus.open => 'เปิด',
    TicketStatus.inProgress => 'กำลังดำเนินการ',
    TicketStatus.closed => 'ปิดแล้ว',
  };

  @override
  Widget build(BuildContext context) {
    if (_showSend) {
      _sendBtnController.forward();
    } else {
      _sendBtnController.reverse();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      // ── Header ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            // Admin avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.adminName.characters.first,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.adminName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _statusColor(widget.status),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(widget.status),
                        style: TextStyle(
                          fontSize: 11,
                          color: _statusColor(widget.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
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
          // ── Ticket title bar ──
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

          // ── Messages ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final prevMsg = index > 0 ? _messages[index - 1] : null;
                final showTime = prevMsg == null || prevMsg.isMe != msg.isMe;

                return _MessageBubble(
                  message: msg,
                  showTime: showTime,
                  adminName: widget.adminName,
                );
              },
            ),
          ),

          // ── Input Area ──
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
                  onTap: () {},
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
class _MessageBubble extends StatefulWidget {
  final _ChatMessage message;
  final bool showTime;
  final String adminName;

  const _MessageBubble({
    required this.message,
    required this.showTime,
    required this.adminName,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation =
        Tween<Offset>(
          begin: Offset(widget.message.isMe ? 0.3 : -0.3, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMe = msg.isMe;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: widget.showTime ? 12 : 4,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Sender label
              if (widget.showTime && !isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    widget.adminName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),

              // Image bubble
              if (msg.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    msg.imageUrl!,
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
                ),

              // Text bubble
              if (msg.text.isNotEmpty)
                Container(
                  margin: msg.imageUrl != null
                      ? const EdgeInsets.only(top: 4)
                      : EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
                    msg.text,
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
                      msg.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: msg.isRead
                            ? AppTheme.primary
                            : Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
