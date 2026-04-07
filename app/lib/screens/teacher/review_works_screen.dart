import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ReviewWorksScreen extends StatelessWidget {
  const ReviewWorksScreen({super.key});

  static final _works = [
    _StudentWork(
      studentName: 'สมชาย ใจดี',
      activity: 'กิจกรรมจิตอาสาพัฒนาชุมชน',
      submittedAt: DateTime(2026, 4, 5),
      status: 'รอตรวจ',
      color: const Color(0xFFFBBF24),
    ),
    _StudentWork(
      studentName: 'สมหญิง รักเรียน',
      activity: 'แข่งขันกีฬาสีประจำปี',
      submittedAt: DateTime(2026, 4, 4),
      status: 'ผ่าน',
      color: const Color(0xFF10B981),
    ),
    _StudentWork(
      studentName: 'มานะ พากเพียร',
      activity: 'ค่ายภาษาอังกฤษ English Camp',
      submittedAt: DateTime(2026, 4, 3),
      status: 'แก้ไข',
      color: const Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text('ตรวจงานนักเรียน'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _works.length,
        itemBuilder: (context, i) {
          final w = _works[i];
          return Container(
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
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.studentName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(w.activity,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                          'ส่งเมื่อ ${w.submittedAt.day}/${w.submittedAt.month}/${w.submittedAt.year + 543}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: w.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(w.status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: w.color)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentWork {
  final String studentName;
  final String activity;
  final DateTime submittedAt;
  final String status;
  final Color color;
  const _StudentWork({
    required this.studentName,
    required this.activity,
    required this.submittedAt,
    required this.status,
    required this.color,
  });
}
