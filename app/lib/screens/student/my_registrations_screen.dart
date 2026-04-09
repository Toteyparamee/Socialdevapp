import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import 'chat_screen.dart';

// ══════════════════════════════════════════════
// หน้า List รายการที่ลงทะเบียน
// ══════════════════════════════════════════════
class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({super.key});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityService>().fetchMyRegistrations();
  }

  String _statusLabel(String status) {
    return switch (status) {
      'registered' => 'ลงทะเบียนแล้ว',
      'submitted' => 'ส่งงานแล้ว',
      'passed' => 'ผ่าน',
      'failed' => 'ไม่ผ่าน',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'registered' => const Color(0xFFFBBF24),
      'submitted' => const Color(0xFF3B82F6),
      'passed' => const Color(0xFF10B981),
      'failed' => const Color(0xFFEF4444),
      _ => Colors.grey,
    };
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ActivityService>();
    final registrations = service.myRegistrations;

    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text(
          'รายการลงทะเบียน',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator())
          : registrations.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรายการลงทะเบียน',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => service.fetchMyRegistrations(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: registrations.length,
                itemBuilder: (context, index) {
                  final reg = registrations[index];
                  final activity = reg.activity;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RegistrationCard(
                      registration: reg,
                      activity: activity,
                      statusLabel: _statusLabel(reg.status),
                      statusColor: _statusColor(reg.status),
                      dateLabel: activity != null
                          ? _formatDate(activity.startAt)
                          : '',
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── Card แต่ละรายการ ──
class _RegistrationCard extends StatelessWidget {
  final Registration registration;
  final Activity? activity;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;

  const _RegistrationCard({
    required this.registration,
    required this.activity,
    required this.statusLabel,
    required this.statusColor,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final title = activity?.title ?? 'กิจกรรม';
    final location = activity?.location ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _RegistrationDetailScreen(
            registration: registration,
            activity: activity,
            statusLabel: statusLabel,
            statusColor: statusColor,
            dateLabel: dateLabel,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// หน้ารายละเอียดการลงทะเบียน
// ══════════════════════════════════════════════
class _RegistrationDetailScreen extends StatefulWidget {
  final Registration registration;
  final Activity? activity;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;

  const _RegistrationDetailScreen({
    required this.registration,
    required this.activity,
    required this.statusLabel,
    required this.statusColor,
    required this.dateLabel,
  });

  @override
  State<_RegistrationDetailScreen> createState() =>
      _RegistrationDetailScreenState();
}

class _RegistrationDetailScreenState extends State<_RegistrationDetailScreen> {
  GoogleMapController? _mapController;
  double _currentZoom = 16;
  final List<PlatformFile> _attachedFiles = [];

  Registration get reg => widget.registration;
  Activity? get activity => widget.activity;

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(1, 20);
    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(1, 20);
    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );

    if (result != null) {
      setState(() {
        _attachedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _attachedFiles.removeAt(index));
  }

  IconData _fileIcon(String? ext) {
    return switch (ext?.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'xls' || 'xlsx' => Icons.table_chart_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  Color _fileColor(String? ext) {
    return switch (ext?.toLowerCase()) {
      'pdf' => const Color(0xFFEF4444),
      'doc' || 'docx' => const Color(0xFF3B82F6),
      'xls' || 'xlsx' => const Color(0xFF10B981),
      _ => const Color(0xFF6B7280),
    };
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  void _handleSubmit() {
    if (_attachedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาแนบไฟล์ก่อนส่งงาน'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final title = activity?.title ?? 'กิจกรรม';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยืนยันส่งงาน',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'ส่งไฟล์ทั้งหมด ${_attachedFiles.length} ไฟล์\nสำหรับกิจกรรม "$title"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final fileNames = _attachedFiles.map((f) => f.name).join(', ');
              await context.read<ActivityService>().submitWork(
                reg.id,
                content: 'ส่งไฟล์: $fileNames',
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ส่งงานสำเร็จ!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF10B981),
                ),
              );
              setState(() => _attachedFiles.clear());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ส่งงาน'),
          ),
        ],
      ),
    );
  }

  void _handleUnregister() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ถอนการลงทะเบียน',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'ต้องการถอนการลงทะเบียน "${activity?.title ?? 'กิจกรรม'}" หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ActivityService>().unregister(
                reg.id,
              );
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ถอนการลงทะเบียนสำเร็จ'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ถอนการลงทะเบียนไม่สำเร็จ'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = activity?.title ?? 'กิจกรรม';
    final description = activity?.description ?? '';
    final location = activity?.location ?? '';
    final lat = activity?.latitude;
    final lng = activity?.longitude;
    final hasMap = lat != null && lng != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'รายละเอียด',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final teacherId = activity?.teacherId;
          if (teacherId == null || teacherId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่พบข้อมูลผู้ดูแลกิจกรรม')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                toUserId: teacherId,
                ticketTitle: title,
                status: TicketStatus.open,
                adminName: title,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        elevation: 4,
        child: const Icon(Icons.chat_rounded, color: Colors.white, size: 24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            if (description.isNotEmpty)
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: AppTheme.textSecondary,
                ),
              ),
            if (description.isNotEmpty) const SizedBox(height: 24),

            // ── ข้อมูลรายละเอียด ──
            _buildSection('ข้อมูลกิจกรรม'),
            const SizedBox(height: 12),
            if (location.isNotEmpty)
              _buildInfoTile(Icons.location_on_rounded, 'สถานที่', location),
            if (widget.dateLabel.isNotEmpty)
              _buildInfoTile(
                Icons.calendar_today_rounded,
                'วันที่',
                widget.dateLabel,
              ),
            _buildInfoTile(
              Icons.info_outline_rounded,
              'สถานะ',
              widget.statusLabel,
            ),
            const SizedBox(height: 24),

            // ── แผนที่ ──
            if (hasMap) ...[
              _buildSection('สถานที่'),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(lat, lng),
                          zoom: 16,
                        ),
                        onMapCreated: (c) => _mapController = c,
                        markers: {
                          Marker(
                            markerId: const MarkerId('reg_location'),
                            position: LatLng(lat, lng),
                            infoWindow: InfoWindow(title: title),
                          ),
                        },
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Column(
                          children: [
                            _buildZoomBtn(Icons.add, _zoomIn),
                            const SizedBox(height: 6),
                            _buildZoomBtn(Icons.remove, _zoomOut),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── แนบไฟล์ส่งงาน ──
            _buildSection('ส่งงาน'),
            const SizedBox(height: 12),

            // Pick file button
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      size: 36,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'แตะเพื่อเลือกไฟล์',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'รองรับ PDF, Word, Excel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // File list
            if (_attachedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...List.generate(_attachedFiles.length, (i) {
                final file = _attachedFiles[i];
                final ext = file.extension;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _fileColor(ext).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _fileIcon(ext),
                          size: 22,
                          color: _fileColor(ext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ext?.toUpperCase() ?? ''} • ${_formatSize(file.size)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeFile(i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),

            // Submit button
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
                child: ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text(
                    'ส่งงาน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Unregister button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _handleUnregister,
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text(
                  'ถอนการลงทะเบียน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  Widget _buildZoomBtn(IconData icon, VoidCallback onTap) {
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
}
