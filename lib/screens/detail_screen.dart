import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../services/image_service.dart';
import '../widgets/activity_register_form.dart';

class DetailScreen extends StatelessWidget {
  final Activity activity;

  const DetailScreen.activity({super.key, required this.activity});

  String _fmt(DateTime dt) {
    final months = ['ม.ค.','ก.พ.','มี.ค.','เม.ย.','พ.ค.','มิ.ย.','ก.ค.','ส.ค.','ก.ย.','ต.ค.','พ.ย.','ธ.ค.'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year + 543} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ActivityRegisterForm(
            activityId: activity.id,
            activityTitle: activity.title,
            onSuccess: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const activityColor = Color(0xFF6C63FF);
    final a = activity;

    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: activityColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context, a, activityColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.radiusLg,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: activityColor.withValues(alpha: 0.1),
                                borderRadius: AppTheme.radiusMd,
                              ),
                              child: const Icon(Icons.school_rounded, color: activityColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: activityColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      a.isPublic ? 'กิจกรรมทั่วไป' : 'กิจกรรมโรงเรียน',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activityColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          a.description,
                          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.radiusLg,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ข้อมูลกิจกรรม',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _infoRow(Icons.location_on_outlined, 'สถานที่', a.location),
                        _infoRow(Icons.play_circle_outline, 'เริ่ม', _fmt(a.startAt)),
                        _infoRow(Icons.stop_circle_outlined, 'สิ้นสุด', _fmt(a.endAt)),
                        _infoRow(Icons.people_outline, 'รับสมัคร', '${a.maxSlots} คน (เหลือ ${a.maxSlots - a.currentSlots} คน)'),
                        if (a.supervisor.isNotEmpty)
                          _infoRow(Icons.person_outline, 'ผู้ดูแล', a.supervisor),
                        if (a.supervisorPhone.isNotEmpty)
                          _infoRow(Icons.phone_outlined, 'เบอร์ติดต่อ', a.supervisorPhone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openRegister(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: activityColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                      ),
                      child: const Text('ลงทะเบียน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Activity a, Color activityColor) {
    final imageService = context.read<ImageService>();
    if (a.imageIds.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageService.getImageUrl(a.imageIds.first),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackHeader(activityColor),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, activityColor.withValues(alpha: 0.6)],
              ),
            ),
          ),
        ],
      );
    }
    return _fallbackHeader(activityColor);
  }

  Widget _fallbackHeader(Color activityColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [activityColor.withValues(alpha: 0.7), activityColor],
        ),
      ),
      child: Icon(Icons.school_rounded, size: 80, color: Colors.white.withValues(alpha: 0.3)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
