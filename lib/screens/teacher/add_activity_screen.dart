import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../services/api_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_map/app_map.dart';
import '../../widgets/app_map/app_map_types.dart';
import '../../models/evaluation.dart';
import '../../widgets/evaluation/evaluation_form_editor.dart';

class AddActivityScreen extends StatefulWidget {
  final Activity? editActivity;
  const AddActivityScreen({super.key, this.editActivity});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _supervisorCtrl = TextEditingController();
  final _supervisorPhoneCtrl = TextEditingController();
  DateTime? _date;
  AppLatLng? _pickedLocation;
  final List<XFile> _images = [];
  List<String> _existingImageIds = [];
  bool _isSubmitting = false;
  bool _isPublic = false;
  int? _targetSchoolId; // null = ทุกโรงเรียน (organization เท่านั้น)
  List<Map<String, dynamic>> _schools = [];
  bool _evalEnabled = false;
  List<EvaluationQuestion> _evalQuestions = [];

  bool get _isEditing => widget.editActivity != null;

  @override
  void initState() {
    super.initState();
    final a = widget.editActivity;
    if (a != null) {
      _titleCtrl.text = a.title;
      _descCtrl.text = a.description;
      _locationCtrl.text = a.location;
      _seatsCtrl.text = a.maxSlots.toString();
      _supervisorCtrl.text = a.supervisor;
      _supervisorPhoneCtrl.text = a.supervisorPhone;
      _date = a.startAt.toLocal();
      if (a.latitude != null && a.longitude != null) {
        _pickedLocation = AppLatLng(a.latitude!, a.longitude!);
      }
      _existingImageIds = List.from(a.imageIds);
      _isPublic = a.isPublic;
      final sid = int.tryParse(a.schoolId);
      _targetSchoolId = (sid != null && sid != 0) ? sid : null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchoolsIfOrg());
    if (_isEditing) _loadEvaluationForm();
  }

  Future<void> _loadEvaluationForm() async {
    final form = await context.read<ActivityService>().getEvaluationForm(
      widget.editActivity!.id,
    );
    if (mounted && form != null && form.questions.isNotEmpty) {
      setState(() {
        _evalEnabled = true;
        _evalQuestions = form.questions;
      });
    }
  }

  Future<void> _loadSchoolsIfOrg() async {
    final auth = context.read<AuthService>();
    debugPrint('AddActivity role=${auth.role}');
    if (auth.role != 'หน่วยงาน') return;
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.schoolsUrl), headers: auth.authHeaders)
          .timeout(const Duration(seconds: 10));
      debugPrint('schools status=${res.statusCode} body=${res.body}');
      if (res.statusCode == 200 && mounted) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _schools = list.map((s) => {'id': s['id'], 'name': s['name']}).toList();
        });
        debugPrint('schools loaded ${_schools.length}');
      }
    } catch (e) {
      debugPrint('schools error: $e');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _seatsCtrl.dispose();
    _supervisorCtrl.dispose();
    _supervisorPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    AppLatLng? initial = _pickedLocation;
    if (initial == null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm == LocationPermission.whileInUse ||
              perm == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition();
            initial = AppLatLng(pos.latitude, pos.longitude);
          }
        }
      } catch (_) {}
    }
    final AppLatLng startAt = initial ?? const AppLatLng(13.8200, 100.5700);

    final result = await Navigator.of(context).push<AppLatLng>(
      MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(initial: startAt),
      ),
    );

    if (result != null) {
      setState(() => _pickedLocation = result);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _images.add(picked));
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_images.isEmpty) return const [];
    final auth = context.read<AuthService>();
    final uri = Uri.parse(ApiConfig.imageBase);
    final ids = <String>[];

    for (final img in _images) {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(auth.authHeaders);
      request.fields['folder'] = 'activity';

      final bytes = await img.readAsBytes();
      final ext = img.path.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
          ? 'image/webp'
          : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: img.name,
          contentType: MediaType.parse(mime),
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 201) {
        throw Exception(
          'upload failed: HTTP ${streamed.statusCode} — $body',
        );
      }
      ids.add(jsonDecode(body)['id'] as String);
    }
    return ids;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
      return;
    }

    setState(() => _isSubmitting = true);

    List<String> newImageIds;
    try {
      newImageIds = await _uploadImages();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปโหลดรูปไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    if (!mounted) return;

    final allImageIds = [..._existingImageIds, ...newImageIds];
    final startAt = _date!;
    final endAt = startAt.add(const Duration(hours: 8));
    final svc = context.read<ActivityService>();

    String? activityId;
    bool success;
    if (_isEditing) {
      activityId = widget.editActivity!.id;
      success = await svc.updateActivity(
        id: activityId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
        supervisor: _supervisorCtrl.text.trim(),
        supervisorPhone: _supervisorPhoneCtrl.text.trim(),
        startAt: startAt,
        endAt: endAt,
        maxSlots: int.tryParse(_seatsCtrl.text.trim()) ?? 30,
        imageIds: allImageIds,
        isPublic: _isPublic,
        targetSchoolId: _targetSchoolId,
      );
    } else {
      final created = await svc.createActivity(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
        supervisor: _supervisorCtrl.text.trim(),
        supervisorPhone: _supervisorPhoneCtrl.text.trim(),
        startAt: startAt,
        endAt: endAt,
        maxSlots: int.tryParse(_seatsCtrl.text.trim()) ?? 30,
        imageIds: allImageIds,
        isPublic: _isPublic,
        targetSchoolId: _targetSchoolId,
      );
      activityId = created?.id;
      success = created != null;
    }

    if (success && activityId != null) {
      await svc.saveEvaluationForm(
        activityId,
        _evalEnabled ? _evalQuestions : const [],
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'แก้ไขกิจกรรมสำเร็จ' : 'สร้างกิจกรรมสำเร็จ')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'แก้ไขกิจกรรมไม่สำเร็จ' : 'สร้างกิจกรรมไม่สำเร็จ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขกิจกรรม' : 'เพิ่มกิจกรรม'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('ชื่อกิจกรรม'),
              TextFormField(
                controller: _titleCtrl,
                decoration: _dec('เช่น ค่ายอาสาพัฒนาชุมชน'),
                validator: (v) => (v == null || v.isEmpty) ? 'กรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),
              _label('รายละเอียด'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: _dec('อธิบายกิจกรรม...'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'กรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 16),
              _label('สถานที่'),
              TextFormField(
                controller: _locationCtrl,
                decoration: _dec('เช่น หอประชุมโรงเรียน'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'กรอกสถานที่' : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _pickedLocation != null
                          ? AppTheme.primary
                          : const Color(0xFFE8ECF0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pickedLocation != null
                            ? Icons.check_circle_rounded
                            : Icons.map_rounded,
                        size: 20,
                        color: _pickedLocation != null
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedLocation != null
                              ? 'ปักหมุดแล้ว (${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)})'
                              : 'ปักหมุดบนแผนที่',
                          style: TextStyle(
                            fontSize: 14,
                            color: _pickedLocation != null
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      if (_pickedLocation != null)
                        GestureDetector(
                          onTap: () => setState(() => _pickedLocation = null),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('ครูผู้ดูแล'),
              TextFormField(
                controller: _supervisorCtrl,
                decoration: _dec('เช่น อ.สมชาย ใจดี'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'กรอกชื่อครูผู้ดูแล' : null,
              ),
              const SizedBox(height: 16),
              _label('เบอร์ติดต่อครูผู้ดูแล'),
              TextFormField(
                controller: _supervisorPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec('เช่น 081-234-5678'),
              ),
              const SizedBox(height: 16),
              _label('จำนวนรับ'),
              TextFormField(
                controller: _seatsCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('เช่น 30'),
                validator: (v) => (v == null || v.isEmpty) ? 'กรอกจำนวน' : null,
              ),
              const SizedBox(height: 16),
              _label('วันที่จัดกิจกรรม'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _date == null
                            ? 'เลือกวันที่'
                            : '${_date!.day}/${_date!.month}/${_date!.year + 543}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('รูปภาพกิจกรรม'),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildAddImageButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'ถ่ายรูป',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 10),
                    _buildAddImageButton(
                      icon: Icons.photo_library_outlined,
                      label: 'เลือกรูป',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    ..._images.map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(img.path),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _images.remove(img)),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
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
              ),
              const SizedBox(height: 16),
              _buildVisibilitySection(context),
              const SizedBox(height: 16),
              EvaluationFormEditor(
                enabled: _evalEnabled,
                onEnabledChanged: (v) => setState(() => _evalEnabled = v),
                questions: _evalQuestions,
                onQuestionsChanged: (qs) => setState(() => _evalQuestions = qs),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'บันทึกการแก้ไข' : 'สร้างกิจกรรม',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  Widget _buildAddImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8ECF0), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySection(BuildContext context) {
    final auth = context.read<AuthService>();
    final isOrg = auth.role == 'หน่วยงาน';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('การมองเห็นกิจกรรม'),
          if (!isOrg) ...[
            // ครู: toggle เฉพาะโรงเรียน / ทุกโรงเรียน
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isPublic ? 'ทุกโรงเรียน' : 'เฉพาะโรงเรียนฉัน',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ),
                Switch(
                  value: _isPublic,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ],
            ),
          ] else ...[
            // Organization: dropdown เลือกโรงเรียน หรือ ทุกโรงเรียน
            const SizedBox(height: 4),
            DropdownButtonFormField<int?>(
              initialValue: _targetSchoolId,
              decoration: _dec('เลือกโรงเรียน'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('ทุกโรงเรียน'),
                ),
                ..._schools.map(
                  (s) => DropdownMenuItem<int?>(
                    value: s['id'] as int,
                    child: Text(s['name'] as String),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _targetSchoolId = v;
                _isPublic = v == null; // null = ทุกโรงเรียน = is_public true
              }),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
    ),
  );
}

class _LocationPickerScreen extends StatefulWidget {
  final AppLatLng initial;
  const _LocationPickerScreen({required this.initial});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  late AppLatLng _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปักหมุดสถานที่'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text(
              'ยืนยัน',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AppMap(
            initialCenter: widget.initial,
            initialZoom: 15,
            markers: [
              AppMarker(
                id: 'picked',
                position: _selected,
                hue: 210, // azure
              ),
            ],
            myLocationEnabled: true,
            onTap: (pos) => setState(() => _selected = pos),
          ),
          // Hint at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'แตะบนแผนที่เพื่อปักหมุด',
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
