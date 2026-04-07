import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class ReviewWorksScreen extends StatelessWidget {
  const ReviewWorksScreen({super.key});

  // Mock: กิจกรรมที่ครูคนนี้สร้างเอง (ในระบบจริงดึงจาก API ตาม owner)
  static final List<_TeacherActivity> _myActivities = [
    _TeacherActivity(
      title: 'กิจกรรมจิตอาสาพัฒนาชุมชน',
      date: '15 เม.ย. 2569',
      location: 'หอประชุมโรงเรียน',
      image: 'https://picsum.photos/seed/tact1/400/200',
      category: 'จิตอาสา',
      categoryColor: const Color(0xFF10B981),
      submissions: [
        _Submission(
          studentName: 'สมชาย ใจดี',
          studentId: '64010001',
          className: 'ม.5/2',
          submittedAt: DateTime(2026, 4, 5),
          status: 'รอตรวจ',
          color: const Color(0xFFFBBF24),
          workTitle: 'รายงานกิจกรรมจิตอาสาพัฒนาชุมชน',
          workDescription:
              'เข้าร่วมกิจกรรมทำความสะอาดวัดในชุมชน ร่วมกับเพื่อน ๆ และอาจารย์ ใช้เวลา 4 ชั่วโมง',
          workImage: 'https://picsum.photos/seed/work1/600/400',
        ),
        _Submission(
          studentName: 'สมหญิง รักเรียน',
          studentId: '64010002',
          className: 'ม.5/2',
          submittedAt: DateTime(2026, 4, 6),
          status: 'ผ่าน',
          color: const Color(0xFF10B981),
          workTitle: 'สรุปกิจกรรมจิตอาสา',
          workDescription: 'ร่วมปลูกต้นไม้บริเวณหน้าโรงเรียน',
          workImage: 'https://picsum.photos/seed/work2/600/400',
          score: 9,
        ),
      ],
    ),
    _TeacherActivity(
      title: 'แข่งขันกีฬาสีประจำปี',
      date: '20-22 เม.ย. 2569',
      location: 'สนามกีฬาโรงเรียน',
      image: 'https://picsum.photos/seed/tact2/400/200',
      category: 'กีฬา',
      categoryColor: const Color(0xFFF59E0B),
      submissions: [
        _Submission(
          studentName: 'มานะ พากเพียร',
          studentId: '64010003',
          className: 'ม.6/1',
          submittedAt: DateTime(2026, 4, 3),
          status: 'แก้ไข',
          color: const Color(0xFFEF4444),
          workTitle: 'รายงานการแข่งขันกีฬาสี',
          workDescription: 'เข้าร่วมแข่งขันวิ่ง 100 เมตร',
          workImage: 'https://picsum.photos/seed/work3/600/400',
          feedback: 'รายละเอียดน้อยเกินไป กรุณาเพิ่มภาพและสรุปประสบการณ์',
        ),
      ],
    ),
    _TeacherActivity(
      title: 'ค่ายภาษาอังกฤษ English Camp',
      date: '10-12 พ.ค. 2569',
      location: 'ห้องประชุมอาคาร C',
      image: 'https://picsum.photos/seed/tact3/400/200',
      category: 'ภาษา',
      categoryColor: const Color(0xFF8B5CF6),
      submissions: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final teacherName = auth.username ?? 'ครู';

    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text(
          'ตรวจงานนักเรียน',
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
          // Header
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
                    Icons.fact_check_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'อ.$teacherName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'กิจกรรมของฉัน ${_myActivities.length} รายการ',
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

          const Text(
            'กิจกรรมที่ฉันสร้าง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          if (_myActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ยังไม่มีกิจกรรมที่สร้าง',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._myActivities.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityCard(activity: a),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Activity Card ──
class _ActivityCard extends StatelessWidget {
  final _TeacherActivity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final pending = activity.submissions
        .where((s) => s.status == 'รอตรวจ')
        .length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SubmissionsScreen(activity: activity),
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
            Stack(
              children: [
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
                if (pending > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'รอตรวจ $pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'งานที่ส่ง ${activity.submissions.length} ชิ้น',
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
      ),
    );
  }
}

// ── Submissions Screen ──
class _SubmissionsScreen extends StatefulWidget {
  final _TeacherActivity activity;
  const _SubmissionsScreen({required this.activity});

  @override
  State<_SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<_SubmissionsScreen> {
  _TeacherActivity get activity => widget.activity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: activity.submissions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ยังไม่มีนักเรียนส่งงาน',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activity.submissions.length,
              itemBuilder: (context, i) {
                final s = activity.submissions[i];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _StudentWorkDetailScreen(
                          submission: s,
                          activityTitle: activity.title,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.studentName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ส่งเมื่อ ${s.submittedAt.day}/${s.submittedAt.month}/${s.submittedAt.year + 543}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: s.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Student Work Detail Screen ──
class _StudentWorkDetailScreen extends StatefulWidget {
  final _Submission submission;
  final String activityTitle;
  const _StudentWorkDetailScreen({
    required this.submission,
    required this.activityTitle,
  });

  @override
  State<_StudentWorkDetailScreen> createState() =>
      _StudentWorkDetailScreenState();
}

class _StudentWorkDetailScreenState extends State<_StudentWorkDetailScreen> {
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.submission.score != null) {
      _scoreController.text = widget.submission.score.toString();
    }
    if (widget.submission.feedback != null) {
      _feedbackController.text = widget.submission.feedback!;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _grade(bool pass) {
    final s = widget.submission;
    if (!pass && _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อเสนอแนะเมื่อไม่ผ่าน')),
      );
      return;
    }
    setState(() {
      if (pass) {
        s.status = 'ผ่าน';
        s.color = const Color(0xFF10B981);
        s.score = int.tryParse(_scoreController.text);
        s.feedback = _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim();
      } else {
        s.status = 'แก้ไข';
        s.color = const Color(0xFFEF4444);
        s.feedback = _feedbackController.text.trim();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pass ? 'บันทึกผล: ผ่าน' : 'ส่งกลับให้แก้ไข'),
        backgroundColor: pass
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text(
          'รายละเอียดนักเรียน',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Student info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.studentName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัส ${s.studentId}  •  ${s.className}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: s.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Work content
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    s.workImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'กิจกรรม: ${widget.activityTitle}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.workTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.workDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ส่งเมื่อ ${s.submittedAt.day}/${s.submittedAt.month}/${s.submittedAt.year + 543}',
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
          ),
          const SizedBox(height: 16),

          // Grading
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ให้คะแนน',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _scoreController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'คะแนน (0-10)',
                    filled: true,
                    fillColor: AppTheme.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ข้อเสนอแนะ (จำเป็นเมื่อไม่ผ่าน)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'พิมพ์ข้อเสนอแนะให้นักเรียน...',
                    filled: true,
                    fillColor: AppTheme.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _grade(false),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFEF4444),
                        ),
                        label: const Text(
                          'ไม่ผ่าน',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _grade(true),
                        icon: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'ผ่าน',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

class _TeacherActivity {
  final String title;
  final String date;
  final String location;
  final String image;
  final String category;
  final Color categoryColor;
  final List<_Submission> submissions;
  const _TeacherActivity({
    required this.title,
    required this.date,
    required this.location,
    required this.image,
    required this.category,
    required this.categoryColor,
    required this.submissions,
  });
}

class _Submission {
  final String studentName;
  final String studentId;
  final String className;
  final DateTime submittedAt;
  String status;
  Color color;
  final String workTitle;
  final String workDescription;
  final String workImage;
  int? score;
  String? feedback;
  _Submission({
    required this.studentName,
    required this.studentId,
    required this.className,
    required this.submittedAt,
    required this.status,
    required this.color,
    required this.workTitle,
    required this.workDescription,
    required this.workImage,
    this.score,
    this.feedback,
  });
}
