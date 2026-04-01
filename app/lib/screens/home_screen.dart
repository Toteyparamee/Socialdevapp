import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../models/problem_report.dart';
import 'map_home_screen.dart';
import 'problem_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          MapHomeScreen(),
          _ActivityTab(),
          _ProfileTab(),
        ],
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

// ---------- Tab: รายการปัญหา ----------
class _ProblemListTab extends StatelessWidget {
  const _ProblemListTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text('ปัญหาทั้งหมด'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleProblems.length,
        itemBuilder: (context, index) {
          final p = sampleProblems[index];
          return _ProblemCard(problem: p);
        },
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final ProblemReport problem;
  const _ProblemCard({required this.problem});

  Color get _statusColor {
    return switch (problem.status) {
      ProblemStatus.pending => Colors.orange,
      ProblemStatus.inProgress => Colors.blue,
      ProblemStatus.resolved => Colors.green,
    };
  }

  IconData get _categoryIcon {
    return switch (problem.category) {
      ProblemCategory.flood => Icons.water_drop,
      ProblemCategory.trash => Icons.delete_outline,
      ProblemCategory.traffic => Icons.traffic,
      ProblemCategory.infrastructure => Icons.build,
      ProblemCategory.other => Icons.info_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProblemDetailScreen(problem: problem),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusMd,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: problem.imageUrls.isNotEmpty
                  ? Image.network(
                      problem.imageUrls.first,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_categoryIcon, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            problem.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      problem.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        problem.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppTheme.inputBg,
      child: Icon(_categoryIcon, size: 32, color: AppTheme.textSecondary),
    );
  }
}

// ---------- Tab: กิจกรรมในโรงเรียน ----------
class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text('กิจกรรมในโรงเรียน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ActivityCard(
            title: 'Big Cleaning Day',
            date: '5 เม.ย. 2569',
            time: '08:00 - 12:00 น.',
            location: 'บริเวณรอบโรงเรียน',
            description: 'กิจกรรมทำความสะอาดครั้งใหญ่ ร่วมกันเก็บขยะและปรับปรุงภูมิทัศน์รอบโรงเรียน',
            icon: Icons.cleaning_services_rounded,
            color: Colors.green,
            tag: 'อาสาสมัคร',
          ),
          _ActivityCard(
            title: 'ประชุมสภานักเรียน',
            date: '8 เม.ย. 2569',
            time: '15:00 - 16:30 น.',
            location: 'ห้องประชุม อาคาร 3',
            description: 'หารือปัญหาในโรงเรียนและติดตามผลการแก้ไขปัญหาที่แจ้งไว้',
            icon: Icons.groups_rounded,
            color: Colors.blue,
            tag: 'ประชุม',
          ),
          _ActivityCard(
            title: 'ซ่อมแซมสนามกีฬา',
            date: '12 เม.ย. 2569',
            time: '09:00 - 15:00 น.',
            location: 'สนามฟุตบอล',
            description: 'โครงการซ่อมแซมสนามกีฬาที่ชำรุด โดยความร่วมมือของนักเรียนและชุมชน',
            icon: Icons.construction_rounded,
            color: Colors.orange,
            tag: 'โครงการ',
          ),
          _ActivityCard(
            title: 'รณรงค์ลดขยะพลาสติก',
            date: '15 เม.ย. 2569',
            time: '08:30 - 11:30 น.',
            location: 'หอประชุมโรงเรียน',
            description: 'กิจกรรมให้ความรู้เรื่องการลดขยะและคัดแยกขยะอย่างถูกวิธี',
            icon: Icons.recycling_rounded,
            color: Colors.teal,
            tag: 'สิ่งแวดล้อม',
          ),
          _ActivityCard(
            title: 'ตรวจสอบอาคารเรียน',
            date: '20 เม.ย. 2569',
            time: '10:00 - 14:00 น.',
            location: 'อาคารเรียนทุกหลัง',
            description: 'สำรวจปัญหาโครงสร้างอาคาร ระบบไฟฟ้า และประปา เพื่อส่งซ่อมบำรุง',
            icon: Icons.domain_rounded,
            color: Colors.deepPurple,
            tag: 'สำรวจ',
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;
  final IconData icon;
  final Color color;
  final String tag;

  const _ActivityCard({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.icon,
    required this.color,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with color accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$date  ·  $time',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
              child: const Icon(Icons.person, size: 44, color: AppTheme.primary),
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

          // Menu items
          _buildMenuItem(
            icon: Icons.history,
            label: 'ประวัติการแจ้ง',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            label: 'การแจ้งเตือน',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            label: 'ตั้งค่า',
            onTap: () {},
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
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
