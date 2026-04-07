import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

// ── ข้อมูลการลงทะเบียน ──
class _RegistrationData {
  final String title;
  final String organization;
  final String date;
  final DateTime eventDate;
  final String supervisor;
  final String phone;
  final String contactChannel;
  final String contactId;
  final String status;
  final Color statusColor;
  final double lat;
  final double lng;
  final String description;

  const _RegistrationData({
    required this.title,
    required this.organization,
    required this.date,
    required this.eventDate,
    required this.supervisor,
    required this.phone,
    required this.contactChannel,
    required this.contactId,
    required this.status,
    required this.statusColor,
    required this.lat,
    required this.lng,
    required this.description,
  });
}

// ══════════════════════════════════════════════
// หน้า List รายการที่ลงทะเบียน
// ══════════════════════════════════════════════
class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  static final List<_RegistrationData> _registrations = [
    _RegistrationData(
      title: 'กิจกรรมจิตอาสาพัฒนาชุมชน',
      organization: 'สำนักงานเขตพื้นที่การศึกษา',
      date: '15 เม.ย. 2569',
      eventDate: DateTime(2026, 4, 15),
      supervisor: 'อ.สมชาย ใจดี',
      phone: '081-234-5678',
      contactChannel: 'Line',
      contactId: '@somchai_j',
      status: 'รอดำเนินการ',
      statusColor: Color(0xFFFBBF24),
      lat: 13.7563,
      lng: 100.5018,
      description:
          'กิจกรรมจิตอาสาพัฒนาชุมชนรอบโรงเรียน เปิดรับนักเรียนทุกระดับชั้น '
          'ร่วมทำความสะอาดและปลูกต้นไม้ในพื้นที่สาธารณะ',
    ),
    _RegistrationData(
      title: 'แข่งขันกีฬาสีประจำปี',
      organization: 'ฝ่ายกิจกรรมนักเรียน',
      date: '20-22 เม.ย. 2569',
      eventDate: DateTime(2026, 4, 20),
      supervisor: 'อ.วิภา รักกีฬา',
      phone: '089-876-5432',
      contactChannel: 'Facebook',
      contactId: 'Wipa Raksport',
      status: 'อนุมัติแล้ว',
      statusColor: Color(0xFF10B981),
      lat: 13.7570,
      lng: 100.5025,
      description:
          'การแข่งขันกีฬาสีประจำปีการศึกษา 2569 มีกีฬาหลากหลายประเภท '
          'ทั้งฟุตบอล บาสเกตบอล วอลเลย์บอล และกรีฑา',
    ),
    _RegistrationData(
      title: 'ค่ายภาษาอังกฤษ English Camp',
      organization: 'กลุ่มสาระภาษาต่างประเทศ',
      date: '10-12 พ.ค. 2569',
      eventDate: DateTime(2026, 5, 10),
      supervisor: 'อ.แนนซี่ สมิธ',
      phone: '092-111-2233',
      contactChannel: 'IG',
      contactId: '@nancy_english',
      status: 'รอส่งงาน',
      statusColor: Color(0xFF3B82F6),
      lat: 13.7580,
      lng: 100.5030,
      description:
          'ค่ายภาษาอังกฤษ 3 วัน 2 คืน เรียนรู้ผ่านกิจกรรมสนุกสนาน '
          'ฝึกทักษะการฟัง พูด อ่าน เขียน กับครูเจ้าของภาษา',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: _registrations.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรายการลงทะเบียน',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _registrations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RegistrationCard(
                      registration: _registrations[index]),
                );
              },
            ),
    );
  }

}

// ── Card แต่ละรายการ ──
class _RegistrationCard extends StatelessWidget {
  final _RegistrationData registration;
  const _RegistrationCard({required this.registration});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _RegistrationDetailScreen(registration: registration),
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
            // Status + Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    registration.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: registration.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    registration.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: registration.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Organization
            Row(
              children: [
                const Icon(Icons.business_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  registration.organization,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  registration.date,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Supervisor
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  registration.supervisor,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
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
  final _RegistrationData registration;
  const _RegistrationDetailScreen({required this.registration});

  @override
  State<_RegistrationDetailScreen> createState() =>
      _RegistrationDetailScreenState();
}

class _RegistrationDetailScreenState extends State<_RegistrationDetailScreen> {
  GoogleMapController? _mapController;
  double _currentZoom = 16;
  final List<PlatformFile> _attachedFiles = [];

  _RegistrationData get reg => widget.registration;

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันส่งงาน',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'ส่งไฟล์ทั้งหมด ${_attachedFiles.length} ไฟล์\nสำหรับกิจกรรม "${reg.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก',
                style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
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
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ส่งงาน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('รายละเอียด',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              ticketTitle: reg.title,
              status: TicketStatus.open,
              adminName: reg.supervisor,
            ),
          ),
        ),
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
                    reg.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: reg.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reg.status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: reg.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              reg.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // ── ข้อมูลรายละเอียด ──
            _buildSection('ข้อมูลกิจกรรม'),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.business_rounded, 'หน่วยงาน', reg.organization),
            _buildInfoTile(
                Icons.calendar_today_rounded, 'วันที่', reg.date),
            _buildInfoTile(
                Icons.person_outline_rounded, 'ผู้ดูแล', reg.supervisor),
            _buildInfoTile(Icons.phone_rounded, 'เบอร์ติดต่อ', reg.phone),
            _buildInfoTile(
              _contactIcon(reg.contactChannel),
              'ช่องทางติดต่อ (${reg.contactChannel})',
              reg.contactId,
            ),
            const SizedBox(height: 24),

            // ── แผนที่ ──
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
                        target: LatLng(reg.lat, reg.lng),
                        zoom: 16,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      markers: {
                        Marker(
                          markerId: const MarkerId('reg_location'),
                          position: LatLng(reg.lat, reg.lng),
                          infoWindow: InfoWindow(
                            title: reg.title,
                            snippet: reg.organization,
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
                    Icon(Icons.cloud_upload_rounded,
                        size: 36, color: AppTheme.primary),
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
                          fontSize: 12, color: Colors.grey.shade500),
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
                        child: Icon(_fileIcon(ext),
                            size: 22, color: _fileColor(ext)),
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
                                  color: AppTheme.textSecondary),
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
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: Colors.red),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
                      fontSize: 12, color: AppTheme.textSecondary),
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

  IconData _contactIcon(String channel) {
    return switch (channel) {
      'Line' => Icons.chat_bubble_rounded,
      'Facebook' => Icons.facebook_rounded,
      'IG' => Icons.camera_alt_rounded,
      _ => Icons.contact_mail_rounded,
    };
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
