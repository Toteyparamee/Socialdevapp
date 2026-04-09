import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/activity_service.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

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
  LatLng? _pickedLocation;

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
    // Get current location as starting point
    LatLng initial = const LatLng(13.8200, 100.5700);
    if (_pickedLocation != null) {
      initial = _pickedLocation!;
    } else {
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
            initial = LatLng(pos.latitude, pos.longitude);
          }
        }
      } catch (_) {}
    }

    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(initial: initial),
      ),
    );

    if (result != null) {
      setState(() => _pickedLocation = result);
    }
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

    final startAt = _date!;
    final endAt = startAt.add(const Duration(hours: 8));

    final success = await context.read<ActivityService>().createActivity(
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
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างกิจกรรมสำเร็จ')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สร้างกิจกรรมไม่สำเร็จ ลองใหม่อีกครั้ง'),
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
        title: const Text('เพิ่มกิจกรรม'),
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
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'สร้างกิจกรรม',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
  final LatLng initial;
  const _LocationPickerScreen({required this.initial});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  late LatLng _selected;

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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initial,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: _selected,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
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
