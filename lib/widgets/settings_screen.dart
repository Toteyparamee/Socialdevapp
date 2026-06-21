import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;

  List<Map<String, dynamic>> _schools = [];
  int? _selectedSchoolId;
  String _selectedSchoolName = '';
  bool _isSaving = false;
  bool _loadingSchools = true;
  bool _notifyAnnouncement = true;
  bool _notifyActivity = true;
  bool _notifyProblem = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _usernameCtrl = TextEditingController(text: auth.username ?? '');
    _selectedSchoolId = (auth.schoolId ?? 0) != 0 ? auth.schoolId : null;
    _selectedSchoolName = auth.schoolName ?? '';
    _fetchSchools();
    _fetchNotifyPrefs();
  }

  Future<void> _fetchNotifyPrefs() async {
    final auth = context.read<AuthService>();
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.loginUrl}/users/profile'), headers: auth.authHeaders)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final user = jsonDecode(res.body)['user'] as Map<String, dynamic>;
        setState(() {
          _notifyAnnouncement = user['notify_announcement'] as bool? ?? true;
          _notifyActivity = user['notify_activity'] as bool? ?? true;
          _notifyProblem = user['notify_problem'] as bool? ?? true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSchools() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.schoolsUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() {
          _schools = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        });
      }
    } catch (_) {}
    setState(() => _loadingSchools = false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'ลบบัญชี',
      desc: 'คุณต้องการลบบัญชีนี้ถาวรหรือไม่?\nข้อมูลทั้งหมดจะถูกลบและไม่สามารถกู้คืนได้',
      btnCancelText: 'ยกเลิก',
      btnCancelOnPress: () {},
      btnOkText: 'ลบบัญชี',
      btnOkColor: Colors.red,
      btnOkOnPress: () {},
    ).show();

    if (confirmed == null) return;

    final auth = context.read<AuthService>();
    final headers = auth.authHeaders;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.loginUrl}/users/account'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        await auth.logout();
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('ลบบัญชีไม่สำเร็จ'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('เชื่อมต่อไม่ได้: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthService>();
    try {
      final body = <String, dynamic>{};
      if (_usernameCtrl.text.trim().isNotEmpty) {
        body['username'] = _usernameCtrl.text.trim();
      }
      if (_selectedSchoolId != null) {
        body['school_id'] = _selectedSchoolId;
      }

      // Save notify prefs in parallel
      http.put(
        Uri.parse('${ApiConfig.loginUrl}/users/notify-prefs'),
        headers: auth.authHeaders,
        body: jsonEncode({
          'notify_announcement': _notifyAnnouncement,
          'notify_activity': _notifyActivity,
          'notify_problem': _notifyProblem,
        }),
      );

      final response = await http
          .put(
            Uri.parse('${ApiConfig.loginUrl}/users/profile'),
            headers: auth.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newUsername = data['user']['username'] as String?;
        if (_selectedSchoolId != null) {
          await auth.updateSchool(_selectedSchoolId!, _selectedSchoolName);
        }
        if (newUsername != null) {
          await auth.updateUsername(newUsername);
        }
        if (!mounted) return;
        setState(() => _isSaving = false);
        await AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: 'บันทึกสำเร็จ',
          desc: 'อัปเดตข้อมูลของคุณเรียบร้อยแล้ว',
          btnOkText: 'ตกลง',
          btnOkOnPress: () => Navigator.of(context).pop(),
        ).show();
        return;
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'เกิดข้อผิดพลาด';
        if (!mounted) return;
        setState(() => _isSaving = false);
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
          title: 'เกิดข้อผิดพลาด',
          desc: err,
          btnOkText: 'ตกลง',
          btnOkOnPress: () {},
        ).show();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'เชื่อมต่อไม่ได้',
        desc: e.toString(),
        btnOkText: 'ตกลง',
        btnOkOnPress: () {},
      ).show();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.inputBg,
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  backgroundImage: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                      ? NetworkImage(auth.avatarUrl!)
                      : null,
                  child: auth.avatarUrl == null || auth.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 44, color: AppTheme.primary)
                      : null,
                ),
              ),
              const SizedBox(height: 28),

              // Info fields (readonly)
              _buildInfoTile(Icons.email_outlined, 'อีเมล', auth.email ?? '-'),
              _buildInfoTile(Icons.badge_outlined, 'บทบาท', auth.role ?? '-'),
              const SizedBox(height: 24),

              // Editable fields
              _label('ชื่อแสดง'),
              TextFormField(
                controller: _usernameCtrl,
                decoration: _dec('ชื่อที่ต้องการแสดง'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),

              _label('โรงเรียน'),
              _loadingSchools
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedSchoolId,
                      hint: const Text('เลือกโรงเรียน'),
                      isExpanded: true,
                      decoration: InputDecoration(
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      items: _schools
                          .map((s) => DropdownMenuItem<int>(
                                value: s['id'] as int,
                                child: Text(s['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedSchoolId = v;
                          _selectedSchoolName = _schools
                              .firstWhere((s) => s['id'] == v)['name'] as String;
                        });
                      },
                    ),
              const SizedBox(height: 24),

              // การแจ้งเตือน
              _label('การแจ้งเตือน'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECF0)),
                ),
                child: Column(
                  children: [
                    _buildNotificationTile(
                      Icons.campaign_outlined,
                      'ประกาศและข่าวสาร',
                      'รับการแจ้งเตือนเมื่อมีประกาศใหม่',
                      _notifyAnnouncement,
                      (v) => setState(() => _notifyAnnouncement = v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildNotificationTile(
                      Icons.event_outlined,
                      'กิจกรรม',
                      'รับการแจ้งเตือนเมื่อมีกิจกรรมใหม่',
                      _notifyActivity,
                      (v) => setState(() => _notifyActivity = v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildNotificationTile(
                      Icons.report_outlined,
                      'สถานะการแจ้งปัญหา',
                      'รับการแจ้งเตือนเมื่อสถานะเปลี่ยน',
                      _notifyProblem,
                      (v) => setState(() => _notifyProblem = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('บันทึก', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('ลบบัญชี', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        child: Text(t,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      );

  Widget _buildInfoTile(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              ],
            ),
          ],
        ),
      );

  Widget _buildNotificationTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      SwitchListTile(
        secondary: Icon(icon, color: AppTheme.primary, size: 22),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
