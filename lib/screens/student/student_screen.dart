import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/activity.dart';
import '../../services/auth_service.dart';
import '../../services/activity_service.dart';
import '../../services/image_service.dart';
import '../../widgets/map_view.dart';
import 'school_activities_screen.dart';
import 'my_registrations_screen.dart';
import '../../widgets/settings_screen.dart';
import '../../widgets/calendar_section.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [MapView(), _HomeTab(), _ProfileTab()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: 'แผนที่',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.event_outlined,
                  activeIcon: Icons.event_rounded,
                  label: 'กิจกรรม',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'โปรไฟล์',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Tab: Home ----------
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final PageController _bannerController = PageController();
  Timer? _autoScrollTimer;
  int _currentBanner = 0;
  DateTime? _selectedDate;
  List<Activity> _bannerActivities = [];
  bool _bannerLoaded = false;

  // เมนูลัด
  static const _menus = [
    _MenuData(
      icon: Icons.how_to_reg_rounded,
      label: 'ลงทะเบียน',
      color: Color.fromARGB(255, 107, 166, 255),
    ),
    _MenuData(
      icon: Icons.event_rounded,
      label: 'กิจกรรมโรงเรียน',
      color: Color.fromARGB(255, 107, 166, 255),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanners());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    final svc = context.read<ActivityService>();
    await svc.fetchActivities();
    if (!mounted) return;
    final all = svc.activities;
    final withImages = all.where((a) => a.imageIds.isNotEmpty).toList();
    final source = withImages.isNotEmpty ? withImages : all;
    final picks = source.isEmpty ? [] : (source.toList()..shuffle(Random())).take(5).toList();
    setState(() {
      _bannerActivities = picks.cast<Activity>();
      _bannerLoaded = true;
    });
    if (_bannerActivities.isNotEmpty) _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _bannerActivities.isEmpty) return;
      final next = (_currentBanner + 1) % _bannerActivities.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    context.watch<ActivityService>();

    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      backgroundImage: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                          ? NetworkImage(auth.avatarUrl!)
                          : null,
                      child: auth.avatarUrl == null || auth.avatarUrl!.isEmpty
                          ? const Icon(Icons.person, color: AppTheme.primary, size: 26)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดี, ${auth.username ?? 'ผู้ใช้'} 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.role ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Banner ข่าวสาร (auto-scroll) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 170,
                      child: _bannerActivities.isEmpty
                          ? Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppTheme.primary.withValues(alpha: 0.1),
                              ),
                              alignment: Alignment.center,
                              child: _bannerLoaded
                                  ? const Icon(Icons.event_rounded, size: 48, color: AppTheme.primary)
                                  : const CircularProgressIndicator(),
                            )
                          : PageView.builder(
                              controller: _bannerController,
                              itemCount: _bannerActivities.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentBanner = i),
                              itemBuilder: (context, i) {
                                final act = _bannerActivities[i];
                                final imgSvc = context.read<ImageService>();
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      act.imageIds.isNotEmpty
                                          ? Image.network(
                                              imgSvc.getImageUrl(act.imageIds.first),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(color: const Color(0xFFE8ECF0)),
                                            )
                                          : Container(
                                              color: AppTheme.primary.withValues(alpha: 0.15),
                                              child: const Icon(
                                                Icons.event_rounded,
                                                size: 48,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 16,
                                        right: 16,
                                        bottom: 16,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              act.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              act.location,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.85),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_bannerActivities.length, (i) {
                        final isActive = i == _currentBanner;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primary
                                : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── เมนูลัด ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _menus.map((m) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: m == _menus.last ? 0 : 12,
                      ),
                      child: _MenuCard(m: m, onTap: () {
                        switch (m.label) {
                          case 'กิจกรรมโรงเรียน':
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolActivitiesScreen()));
                          case 'ลงทะเบียน':
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRegistrationsScreen()));
                        }
                      }),
                    ),
                  )).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // ── ปฏิทิน ──
              _buildCalendarSection(),

              const SizedBox(height: 24),

              // ── กิจกรรมที่กำลังมาถึง ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? 'กิจกรรมวันที่ ${_selectedDate!.day} ${_thaiMonthsShort[_selectedDate!.month]}'
                          : 'กิจกรรมที่กำลังมาถึง',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = null),
                        child: Text(
                          'ดูทั้งหมด',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyRegistrationsScreen(),
                          ),
                        ),
                        child: Text(
                          'ดูทั้งหมด',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ..._filteredEvents.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: e.color.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // Left accent bar
                            Container(width: 5, color: e.color),
                            const SizedBox(width: 14),
                            // Date box
                            Container(
                              width: 48,
                              height: 52,
                              decoration: BoxDecoration(
                                color: e.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${e.eventDate.day}',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: e.color),
                                  ),
                                  Text(
                                    _thaiMonthsShort[e.eventDate.month],
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: e.color),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.title,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            e.subtitle,
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: e.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  e.status,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: e.color),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static const _thaiMonthsShort = [
    '',
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  List<Activity> get _upcomingActivities {
    final list = List<Activity>.from(context.read<ActivityService>().activities)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  _UpcomingEvent _activityToEvent(Activity a) {
    final now = DateTime.now();
    final diff = a.startAt.difference(now);
    final Color color;
    final String status;
    if (diff.isNegative) {
      color = Colors.grey;
      status = 'ผ่านไปแล้ว';
    } else if (diff.inDays <= 3) {
      color = const Color(0xFFEF4444);
      status = 'ใกล้ถึงแล้ว';
    } else if (diff.inDays <= 7) {
      color = const Color(0xFFFBBF24);
      status = 'อีก ${diff.inDays} วัน';
    } else {
      color = const Color(0xFF10B981);
      status = 'อีก ${diff.inDays} วัน';
    }
    return _UpcomingEvent(
      title: a.title,
      subtitle: a.location,
      eventDate: a.startAt,
      status: status,
      color: color,
    );
  }

  List<_UpcomingEvent> get _filteredEvents {
    final events = _upcomingActivities.map(_activityToEvent).toList();
    if (_selectedDate == null) return events;
    return events
        .where(
          (e) =>
              e.eventDate.year == _selectedDate!.year &&
              e.eventDate.month == _selectedDate!.month &&
              e.eventDate.day == _selectedDate!.day,
        )
        .toList();
  }

  Widget _buildCalendarSection() {
    return CalendarSection(
      selectedDate: _selectedDate,
      onDateSelected: (date) => setState(() => _selectedDate = date),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuData({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuData m;
  final VoidCallback onTap;
  const _MenuCard({required this.m, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: m.color.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [m.color.withValues(alpha: 0.2), m.color.withValues(alpha: 0.08)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(m.icon, color: m.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                m.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: m.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: m.color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEvent {
  final String title;
  final String subtitle;
  final DateTime eventDate;
  final String status;
  final Color color;
  const _UpcomingEvent({
    required this.title,
    required this.subtitle,
    required this.eventDate,
    required this.status,
    required this.color,
  });
}

// ---------- Tab: โปรไฟล์ ----------
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              backgroundImage: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                  ? NetworkImage(auth.avatarUrl!)
                  : null,
              child: auth.avatarUrl == null || auth.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 44, color: AppTheme.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              auth.username ?? 'ผู้ใช้',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              auth.role ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            label: 'ตั้งค่า',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthService>().logout(),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text(
                'ออกจากระบบ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textPrimary),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
