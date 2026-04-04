import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SchoolActivitiesScreen extends StatelessWidget {
  const SchoolActivitiesScreen({super.key});

  static const String _schoolName = 'โรงเรียนสาธิตมหาวิทยาลัย';

  static final List<_ActivityData> _activities = [
    _ActivityData(
      title: 'กิจกรรมจิตอาสาพัฒนาชุมชน',
      date: '15 เม.ย. 2569',
      location: 'หอประชุมโรงเรียน',
      image: 'https://picsum.photos/seed/act1/400/200',
      description:
          'กิจกรรมจิตอาสาพัฒนาชุมชนรอบโรงเรียน เปิดรับนักเรียนทุกระดับชั้น '
          'ร่วมทำความสะอาดและปลูกต้นไม้ในพื้นที่สาธารณะ',
      category: 'จิตอาสา',
      categoryColor: Color(0xFF10B981),
    ),
    _ActivityData(
      title: 'แข่งขันกีฬาสีประจำปี',
      date: '20-22 เม.ย. 2569',
      location: 'สนามกีฬาโรงเรียน',
      image: 'https://picsum.photos/seed/act2/400/200',
      description:
          'การแข่งขันกีฬาสีประจำปีการศึกษา 2569 มีกีฬาหลากหลายประเภท '
          'ทั้งฟุตบอล บาสเกตบอล วอลเลย์บอล และกรีฑา',
      category: 'กีฬา',
      categoryColor: Color(0xFFF59E0B),
    ),
    _ActivityData(
      title: 'นิทรรศการวิทยาศาสตร์',
      date: '1 พ.ค. 2569',
      location: 'อาคาร A ชั้น 3',
      image: 'https://picsum.photos/seed/act3/400/200',
      description:
          'นิทรรศการแสดงผลงานวิทยาศาสตร์ของนักเรียน ระดับชั้น ม.1 - ม.6 '
          'พร้อมการทดลองสดและบูธกิจกรรม',
      category: 'วิชาการ',
      categoryColor: Color(0xFF3B82F6),
    ),
    _ActivityData(
      title: 'ค่ายภาษาอังกฤษ English Camp',
      date: '10-12 พ.ค. 2569',
      location: 'ห้องประชุมอาคาร C',
      image: 'https://picsum.photos/seed/act4/400/200',
      description:
          'ค่ายภาษาอังกฤษ 3 วัน 2 คืน เรียนรู้ผ่านกิจกรรมสนุกสนาน '
          'ฝึกทักษะการฟัง พูด อ่าน เขียน กับครูเจ้าของภาษา',
      category: 'ภาษา',
      categoryColor: Color(0xFF8B5CF6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text(
          'กิจกรรมโรงเรียน',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // School name header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        _schoolName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'กิจกรรมทั้งหมด ${_activities.length} รายการ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section title
          const Text(
            'กิจกรรมที่กำลังจะมาถึง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          // Activity list
          ...List.generate(_activities.length, (index) {
            final activity = _activities[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityCard(activity: activity),
            );
          }),
        ],
      ),
    );
  }
}

// ── Activity Card ──
class _ActivityCard extends StatelessWidget {
  final _ActivityData activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ActivityDetailScreen(activity: activity),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                activity.image,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppTheme.inputBg,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activity.categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: activity.categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date & location
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

// ── Activity Detail Screen ──
class _ActivityDetailScreen extends StatelessWidget {
  final _ActivityData activity;
  const _ActivityDetailScreen({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                activity.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.inputBg,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: activity.categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: activity.categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info rows
                  _buildInfoRow(
                    Icons.calendar_today_rounded,
                    'วันที่',
                    activity.date,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    'สถานที่',
                    activity.location,
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'รายละเอียดกิจกรรม',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.buttonGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ลงทะเบียนเข้าร่วมกิจกรรมสำเร็จ'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'ลงทะเบียนเข้าร่วม',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Data model ──
class _ActivityData {
  final String title;
  final String date;
  final String location;
  final String image;
  final String description;
  final String category;
  final Color categoryColor;

  const _ActivityData({
    required this.title,
    required this.date,
    required this.location,
    required this.image,
    required this.description,
    required this.category,
    required this.categoryColor,
  });
}
