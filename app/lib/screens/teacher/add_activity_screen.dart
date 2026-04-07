import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
  DateTime? _date;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate() || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สร้างกิจกรรมสำเร็จ')),
    );
    Navigator.pop(context);
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
                validator: (v) => (v == null || v.isEmpty) ? 'กรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 16),
              _label('สถานที่'),
              TextFormField(
                controller: _locationCtrl,
                decoration: _dec('เช่น หอประชุมโรงเรียน'),
                validator: (v) => (v == null || v.isEmpty) ? 'กรอกสถานที่' : null,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 20, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        _date == null
                            ? 'เลือกวันที่'
                            : '${_date!.day}/${_date!.month}/${_date!.year + 543}',
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textPrimary),
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
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('สร้างกิจกรรม',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
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
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
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
