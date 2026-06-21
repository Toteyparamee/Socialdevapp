import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';
import 'airplane_send_animation.dart';

enum ContactChannel { line, facebook, instagram }

class ActivityRegisterForm extends StatefulWidget {
  final String activityId;
  final String activityTitle;
  final VoidCallback? onSuccess;

  const ActivityRegisterForm({
    super.key,
    required this.activityId,
    required this.activityTitle,
    this.onSuccess,
  });

  @override
  State<ActivityRegisterForm> createState() => _ActivityRegisterFormState();
}

class _ActivityRegisterFormState extends State<ActivityRegisterForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactIdController = TextEditingController();

  ContactChannel? _selectedChannel;
  bool _isSending = false;
  bool _sendComplete = false;

  late AnimationController _entranceController;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

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
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _buttonController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _contactIdController.dispose();
    super.dispose();
  }

  String get _contactHint => switch (_selectedChannel) {
    ContactChannel.line => 'Line ID',
    ContactChannel.facebook => 'ชื่อ Facebook',
    ContactChannel.instagram => '@username',
    null => 'เลือกช่องทางติดต่อก่อน',
  };

  IconData get _channelIcon => switch (_selectedChannel) {
    ContactChannel.line => Icons.chat_bubble_rounded,
    ContactChannel.facebook => Icons.facebook_rounded,
    ContactChannel.instagram => Icons.camera_alt_rounded,
    null => Icons.contact_mail_rounded,
  };

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณาเลือกช่องทางติดต่อ'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSending = true);
    final ok = await context.read<ActivityService>().registerForActivity(widget.activityId);
    if (!mounted) return;

    if (ok) {
      setState(() { _isSending = false; _sendComplete = true; });
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ลงทะเบียนไม่สำเร็จ ลองใหม่อีกครั้ง'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSending || _sendComplete) {
      return AirplaneSendAnimation(
        onComplete: () => widget.onSuccess?.call(),
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E), size: 20),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _entranceController,
            builder: (_, child) => Opacity(
              opacity: CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)).value,
              child: child,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ลงทะเบียนเข้าร่วม', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), letterSpacing: -0.5, height: 1.1)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.activityTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                ),
                const SizedBox(height: 8),
                Text('กรอกข้อมูลเพื่อลงทะเบียนเข้าร่วมกิจกรรม', style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AnimatedBuilder(
            animation: _entranceController,
            builder: (_, child) => Opacity(
              opacity: CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)).value,
              child: child,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('ชื่อ'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _firstNameController,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
                    decoration: _inputDeco(hintText: 'กรอกชื่อ'),
                    validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกชื่อ' : null,
                  ),
                  const SizedBox(height: 18),
                  _label('นามสกุล'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lastNameController,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
                    decoration: _inputDeco(hintText: 'กรอกนามสกุล'),
                    validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกนามสกุล' : null,
                  ),
                  const SizedBox(height: 18),
                  _label('เบอร์โทรศัพท์'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
                    decoration: _inputDeco(
                      hintText: '0xx-xxx-xxxx',
                      prefixIcon: const Padding(padding: EdgeInsets.only(left: 14, right: 8), child: Icon(Icons.phone_rounded, color: Color(0xFF9CA3AF), size: 20)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณากรอกเบอร์โทร';
                      if (v.length < 9) return 'เบอร์โทรไม่ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _label('ช่องทางติดต่อ'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _channelChip(ContactChannel.line, 'Line', Icons.chat_bubble_rounded, const Color(0xFF06C755)),
                      const SizedBox(width: 10),
                      _channelChip(ContactChannel.facebook, 'Facebook', Icons.facebook_rounded, const Color(0xFF1877F2)),
                      const SizedBox(width: 10),
                      _channelChip(ContactChannel.instagram, 'IG', Icons.camera_alt_rounded, const Color(0xFFE4405F)),
                    ],
                  ),
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
                                style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
                                decoration: _inputDeco(
                                  hintText: _contactHint,
                                  prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: Icon(_channelIcon, color: const Color(0xFF9CA3AF), size: 20)),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกข้อมูลติดต่อ' : null,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
                  ScaleTransition(
                    scale: _buttonScale,
                    child: GestureDetector(
                      onTapDown: (_) => _buttonController.forward(),
                      onTapUp: (_) { _buttonController.reverse(); _handleSubmit(); },
                      onTapCancel: () => _buttonController.reverse(),
                      child: Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4A90D9), Color(0xFF7C5CE0)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: const Color(0xFF4A90D9).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text('ส่งข้อมูลลงทะเบียน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
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

  Widget _channelChip(ContactChannel channel, String label, IconData icon, Color color) {
    final isSelected = _selectedChannel == channel;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _selectedChannel = channel; _contactIdController.clear(); }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : const Color(0xFFE8ECF0), width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? color : Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)));

  InputDecoration _inputDeco({required String hintText, Widget? suffixIcon, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8ECF0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8ECF0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );
  }
}
