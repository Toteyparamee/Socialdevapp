import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';

class SchoolActivitiesScreen extends StatefulWidget {
  const SchoolActivitiesScreen({super.key});

  @override
  State<SchoolActivitiesScreen> createState() => _SchoolActivitiesScreenState();
}

class _SchoolActivitiesScreenState extends State<SchoolActivitiesScreen> {
  static const String _schoolName = 'โรงเรียนสาธิตมหาวิทยาลัย';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityService>().fetchActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityService = context.watch<ActivityService>();
    final activities = activityService.activities;

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
      body: activityService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activityService.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(activityService.error!, style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => activityService.fetchActivities(),
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : ListView(
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
                                  'กิจกรรมทั้งหมด ${activities.length} รายการ',
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
                      'กิจกรรมที่กำลังจะมาถึง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (activities.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('ยังไม่มีกิจกรรม', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(activities.length, (index) {
                        final activity = activities[index];
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

String _formatThaiDate(DateTime dt) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year + 543}';
}

// ── Activity Card ──
class _ActivityCard extends StatelessWidget {
  final Activity activity;
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
            // Placeholder image
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(Icons.event_rounded, size: 48, color: AppTheme.primary.withValues(alpha: 0.4)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Max slots chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'รับ ${activity.maxSlots} คน',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
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
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatThaiDate(activity.startAt),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
class _ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  const _ActivityDetailScreen({required this.activity});

  @override
  State<_ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<_ActivityDetailScreen> {
  GoogleMapController? _mapController;
  double _currentZoom = 16;

  Activity get activity => widget.activity;

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(1, 20);
    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(1, 20);
    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

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
              background: Container(
                color: AppTheme.primary.withValues(alpha: 0.15),
                child: Center(
                  child: Icon(Icons.event_rounded, size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
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
                  // Slots chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'รับ ${activity.maxSlots} คน',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInfoRow(
                    Icons.calendar_today_rounded,
                    'วันที่',
                    _formatThaiDate(activity.startAt),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    'สถานที่',
                    activity.location,
                  ),
                  _buildInfoRow(
                    Icons.people_outline_rounded,
                    'จำนวนรับ',
                    '${activity.maxSlots} คน',
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
                  const SizedBox(height: 24),

                  // Map section
                  const Text(
                    'สถานที่จัดกิจกรรม',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 200,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: const LatLng(13.7563, 100.5018),
                              zoom: 16,
                            ),
                            onMapCreated: (controller) =>
                                _mapController = controller,
                            markers: {
                              Marker(
                                markerId: const MarkerId('activity_location'),
                                position: const LatLng(13.7563, 100.5018),
                                infoWindow: InfoWindow(
                                  title: activity.title,
                                  snippet: activity.location,
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                          // Zoom buttons
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Column(
                              children: [
                                _buildZoomButton(Icons.add, _zoomIn),
                                const SizedBox(height: 6),
                                _buildZoomButton(Icons.remove, _zoomOut),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ActivityRegisterScreen(
                                activityId: activity.id,
                                activityTitle: activity.title,
                              ),
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

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
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

// ── Activity Register Screen ──
enum _ContactChannel { line, facebook, instagram }

class _ActivityRegisterScreen extends StatefulWidget {
  final String activityId;
  final String activityTitle;
  const _ActivityRegisterScreen({required this.activityId, required this.activityTitle});

  @override
  State<_ActivityRegisterScreen> createState() =>
      _ActivityRegisterScreenState();
}

class _ActivityRegisterScreenState extends State<_ActivityRegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactIdController = TextEditingController();

  _ContactChannel? _selectedChannel;
  bool _isSending = false;
  bool _sendComplete = false;

  late AnimationController _entranceController;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _airplaneController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _airplaneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _buttonController.dispose();
    _airplaneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _contactIdController.dispose();
    super.dispose();
  }

  String get _contactHint {
    return switch (_selectedChannel) {
      _ContactChannel.line => 'Line ID',
      _ContactChannel.facebook => 'ชื่อ Facebook',
      _ContactChannel.instagram => '@username',
      null => 'เลือกช่องทางติดต่อก่อน',
    };
  }

  IconData get _channelIcon {
    return switch (_selectedChannel) {
      _ContactChannel.line => Icons.chat_bubble_rounded,
      _ContactChannel.facebook => Icons.facebook_rounded,
      _ContactChannel.instagram => Icons.camera_alt_rounded,
      null => Icons.contact_mail_rounded,
    };
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกช่องทางติดต่อ'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    // เรียก API ลงทะเบียน
    final success = await context.read<ActivityService>().registerForActivity(widget.activityId);

    if (!mounted) return;

    if (success) {
      await _airplaneController.forward();
      setState(() {
        _isSending = false;
        _sendComplete = true;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลงทะเบียนไม่สำเร็จ ลองใหม่อีกครั้ง'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isSending || _sendComplete
            ? _buildAnimationView()
            : _buildFormView(),
      ),
    );
  }

  // ── Airplane Animation ──
  Widget _buildAnimationView() {
    final envelopeScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _airplaneController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    final airplaneFly = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _airplaneController,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    final airplaneOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(
          CurvedAnimation(
            parent: _airplaneController,
            curve: const Interval(0.1, 0.7),
          ),
        );
    final airplaneRotation = Tween<double>(begin: 0.0, end: -0.4).animate(
      CurvedAnimation(
        parent: _airplaneController,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
      ),
    );
    final successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _airplaneController,
        curve: const Interval(0.7, 0.9, curve: Curves.elasticOut),
      ),
    );
    final successOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _airplaneController,
        curve: const Interval(0.7, 0.85, curve: Curves.easeOut),
      ),
    );

    return Center(
      child: AnimatedBuilder(
        animation: _airplaneController,
        builder: (context, _) {
          return SizedBox(
            width: 280,
            height: 340,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Envelope
                Transform.scale(
                  scale: envelopeScale.value,
                  child: Container(
                    width: 100,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.mail_rounded,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),

                // Airplane
                Opacity(
                  opacity: airplaneOpacity.value,
                  child: Transform.translate(
                    offset: Offset(
                      airplaneFly.value * 160 - 40,
                      -airplaneFly.value * 200 + 20,
                    ),
                    child: Transform.rotate(
                      angle: airplaneRotation.value,
                      child: Icon(
                        Icons.send_rounded,
                        size: 48 + airplaneFly.value * 8,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),

                // Trail particles
                ..._buildTrailParticles(airplaneFly.value),

                // Success
                Opacity(
                  opacity: successOpacity.value,
                  child: Transform.scale(
                    scale: successScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 44,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ลงทะเบียนสำเร็จ!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'คุณได้ลงทะเบียนเข้าร่วมกิจกรรมแล้ว',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildTrailParticles(double flyValue) {
    return List.generate(5, (i) {
      final delay = 0.2 + i * 0.06;
      final endDelay = math.min(delay + 0.3, 0.7);
      final particleOpacity = Tween<double>(begin: 0.6, end: 0.0)
          .animate(
            CurvedAnimation(
              parent: _airplaneController,
              curve: Interval(delay, endDelay, curve: Curves.easeIn),
            ),
          )
          .value
          .clamp(0.0, 1.0);
      final particleProgress = Tween<double>(begin: 0.0, end: 1.0)
          .animate(
            CurvedAnimation(
              parent: _airplaneController,
              curve: Interval(delay, endDelay, curve: Curves.easeOut),
            ),
          )
          .value;

      final baseX = flyValue * 160 - 40;
      final baseY = -flyValue * 200 + 20;

      return Opacity(
        opacity: particleOpacity,
        child: Transform.translate(
          offset: Offset(
            baseX - 20 - i * 12 + (math.sin(i * 1.5) * 8 * particleProgress),
            baseY + 15 + i * 8 + (particleProgress * 20),
          ),
          child: Container(
            width: 6.0 - i * 0.6,
            height: 6.0 - i * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    });
  }

  // ── Form View ──
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1A1A2E),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Header
          AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              final opacity = CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
              ).value;
              return Opacity(opacity: opacity, child: child);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ลงทะเบียนเข้าร่วม',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.activityTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'กรอกข้อมูลเพื่อลงทะเบียนเข้าร่วมกิจกรรม',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Form fields
          AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              final opacity = CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
              ).value;
              return Opacity(opacity: opacity, child: child);
            },
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First name
                  _buildLabel('ชื่อ'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _firstNameController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: _inputDecoration(hintText: 'กรอกชื่อ'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'กรุณากรอกชื่อ' : null,
                  ),
                  const SizedBox(height: 18),

                  // Last name
                  _buildLabel('นามสกุล'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lastNameController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: _inputDecoration(hintText: 'กรอกนามสกุล'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'กรุณากรอกนามสกุล' : null,
                  ),
                  const SizedBox(height: 18),

                  // Phone
                  _buildLabel('เบอร์โทรศัพท์'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: _inputDecoration(
                      hintText: '0xx-xxx-xxxx',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 8),
                        child: Icon(
                          Icons.phone_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณากรอกเบอร์โทร';
                      if (v.length < 9) return 'เบอร์โทรไม่ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Contact channel
                  _buildLabel('ช่องทางติดต่อ'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChannelChip(
                        channel: _ContactChannel.line,
                        label: 'Line',
                        icon: Icons.chat_bubble_rounded,
                        color: const Color(0xFF06C755),
                      ),
                      const SizedBox(width: 10),
                      _buildChannelChip(
                        channel: _ContactChannel.facebook,
                        label: 'Facebook',
                        icon: Icons.facebook_rounded,
                        color: const Color(0xFF1877F2),
                      ),
                      const SizedBox(width: 10),
                      _buildChannelChip(
                        channel: _ContactChannel.instagram,
                        label: 'IG',
                        icon: Icons.camera_alt_rounded,
                        color: const Color(0xFFE4405F),
                      ),
                    ],
                  ),

                  // Contact ID (animated appearance)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: _selectedChannel != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contactIdController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1A1A2E),
                                ),
                                decoration: _inputDecoration(
                                  hintText: _contactHint,
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 14,
                                      right: 8,
                                    ),
                                    child: Icon(
                                      _channelIcon,
                                      color: const Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'กรุณากรอกข้อมูลติดต่อ'
                                    : null,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  ScaleTransition(
                    scale: _buttonScale,
                    child: GestureDetector(
                      onTapDown: (_) => _buttonController.forward(),
                      onTapUp: (_) {
                        _buttonController.reverse();
                        _handleSubmit();
                      },
                      onTapCancel: () => _buttonController.reverse(),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90D9), Color(0xFF7C5CE0)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4A90D9,
                              ).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'ส่งข้อมูลลงทะเบียน',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelChip({
    required _ContactChannel channel,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedChannel == channel;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedChannel = channel;
          _contactIdController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE8ECF0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade400,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? color : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );
  }
}

// ── Data model ──
