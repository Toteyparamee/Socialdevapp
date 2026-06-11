import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

enum UserRole { student, teacher, general }

class RegisterScreen extends StatefulWidget {
  final UserRole? initialRole;

  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newSchoolController = TextEditingController();

  UserRole? _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  String? _errorMessage;
  String? _successMessage;

  // School dropdown state
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchoolId;
  bool _isAddingNewSchool = false;
  bool _isLoadingSchools = false;
  bool _isCreatingSchool = false;

  late AnimationController _entranceController;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;

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

    _loadSchools();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _buttonController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _newSchoolController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.schoolsUrl));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _schools = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      // ใช้รายการว่างถ้าโหลดไม่ได้
    } finally {
      setState(() => _isLoadingSchools = false);
    }
  }

  Future<void> _createSchool() async {
    final name = _newSchoolController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreatingSchool = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.schoolsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (res.statusCode == 201) {
        final school = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _schools.add(school);
          _schools.sort((a, b) =>
              (a['name'] as String).compareTo(b['name'] as String));
          _selectedSchoolId = school['id'].toString();
          _isAddingNewSchool = false;
          _newSchoolController.clear();
        });
      } else if (res.statusCode == 409) {
        // โรงเรียนมีอยู่แล้ว — เลือกโรงเรียนนั้นแทน
        final existing = _schools.firstWhere(
          (s) => (s['name'] as String).toLowerCase() == name.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (existing.isNotEmpty) {
          setState(() {
            _selectedSchoolId = existing['id'].toString();
            _isAddingNewSchool = false;
            _newSchoolController.clear();
          });
        } else {
          await _loadSchools();
          setState(() => _isAddingNewSchool = false);
        }
      }
    } catch (_) {
      // silent — ผู้ใช้ยังเพิ่มได้ใหม่
    } finally {
      setState(() => _isCreatingSchool = false);
    }
  }

  String get _usernameLabel {
    return switch (_selectedRole ?? UserRole.student) {
      UserRole.student => 'Gmail',
      UserRole.teacher => 'อีเมล',
      UserRole.general => 'เบอร์โทร หรือ อีเมล',
    };
  }

  String get _usernameHint {
    return switch (_selectedRole ?? UserRole.student) {
      UserRole.student => '@gmail.com หรือ @.ac.th',
      UserRole.teacher => '@gmail.com หรือ @.ac.th',
      UserRole.general => '@gmail.com',
    };
  }

  String get _roleName {
    return switch (_selectedRole ?? UserRole.student) {
      UserRole.student => 'นักเรียน',
      UserRole.teacher => 'ครู',
      UserRole.general => 'หน่วยงาน',
    };
  }

  String? get _selectedSchoolName {
    if (_selectedSchoolId == null) return null;
    final school = _schools.firstWhere(
      (s) => s['id'].toString() == _selectedSchoolId,
      orElse: () => <String, dynamic>{},
    );
    return school['name'] as String?;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() => _errorMessage = 'กรุณายอมรับเงื่อนไขการใช้งาน');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.register(
        username: _nameController.text.trim(),
        email: _usernameController.text.trim(),
        password: _passwordController.text,
        role: _roleName,
        schoolId: int.tryParse(_selectedSchoolId ?? '') ?? 0,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _successMessage = 'สมัครสมาชิกสำเร็จ!';
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาลองใหม่';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      'สมัครสมาชิก',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'สร้างบัญชีใหม่เพื่อเริ่มต้นใช้งาน',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Role selector
              _buildRoleSelector(),
              const SizedBox(height: 28),
              // Form
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final opacity = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
        ).value;
        return Opacity(opacity: opacity, child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เลือกบทบาท',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildRoleChip(
                UserRole.student,
                'นักเรียน',
                Icons.school_rounded,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              _buildRoleChip(
                UserRole.teacher,
                'ครู',
                Icons.workspace_premium_rounded,
                const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              _buildRoleChip(
                UserRole.general,
                'หน่วยงาน',
                Icons.people_alt_rounded,
                const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(
    UserRole role,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = role;
          _usernameController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                size: 22,
              ),
              const SizedBox(height: 4),
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

  Widget _buildForm() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final opacity = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
        ).value;
        return Opacity(opacity: opacity, child: child);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display name
            _buildLabel(
              _selectedRole == UserRole.general ? 'ชื่อหน่วยงาน' : 'ชื่อที่แสดง',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
              decoration: _inputDecoration(
                hintText: _selectedRole == UserRole.general
                    ? 'ชื่อหน่วยงาน'
                    : 'ชื่อ-นามสกุล',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return _selectedRole == UserRole.general
                      ? 'กรุณากรอกชื่อหน่วยงาน'
                      : 'กรุณากรอกชื่อ';
                }
                return null;
              },
            ),
            // School dropdown (นักเรียน / ครู เท่านั้น)
            if (_selectedRole == UserRole.student ||
                _selectedRole == UserRole.teacher) ...[
              const SizedBox(height: 18),
              _buildLabel('โรงเรียน'),
              const SizedBox(height: 8),
              _buildSchoolSelector(),
            ],
            const SizedBox(height: 18),
            // Username
            _buildLabel(_usernameLabel),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
              decoration: _inputDecoration(hintText: _usernameHint),
              validator: (v) {
                if (v == null || v.isEmpty) return 'กรุณากรอกข้อมูล';
                if ((_selectedRole == UserRole.student ||
                        _selectedRole == UserRole.teacher) &&
                    !v.contains('@')) {
                  return 'กรุณากรอกอีเมลที่ถูกต้อง';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            // Password
            _buildLabel('รหัสผ่าน'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
              decoration: _inputDecoration(
                hintText: 'รหัสผ่านอย่างน้อย 6 ตัว',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                if (v.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว';
                return null;
              },
            ),
            const SizedBox(height: 18),
            // Confirm password
            _buildLabel('ยืนยันรหัสผ่าน'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
              decoration: _inputDecoration(
                hintText: 'กรอกรหัสผ่านอีกครั้ง',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                if (v != _passwordController.text) {
                  return 'รหัสผ่านไม่ตรงกัน';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Terms checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _acceptTerms,
                    onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                    child: Text(
                      'ยอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade400, fontSize: 13),
              ),
            ],
            // Success message
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Register button
            ScaleTransition(
              scale: _buttonScale,
              child: GestureDetector(
                onTapDown: (_) => _buttonController.forward(),
                onTapUp: (_) {
                  _buttonController.reverse();
                  _handleRegister();
                },
                onTapCancel: () => _buttonController.reverse(),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Already have account
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'มีบัญชีอยู่แล้ว? ',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown
        FormField<String>(
          validator: (_) {
            if (!_isAddingNewSchool && _selectedSchoolId == null) {
              return 'กรุณาเลือกโรงเรียน';
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _isAddingNewSchool
                      ? null
                      : () => _showSchoolBottomSheet(context),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _isAddingNewSchool
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: state.hasError
                            ? Colors.red.shade400
                            : const Color(0xFFE8ECF0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isLoadingSchools
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'กำลังโหลด...',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _isAddingNewSchool
                                      ? 'กำลังเพิ่มโรงเรียนใหม่...'
                                      : (_selectedSchoolId != null
                                          ? (_selectedSchoolName ?? '')
                                          : 'เลือกโรงเรียน'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedSchoolId != null &&
                                            !_isAddingNewSchool
                                        ? const Color(0xFF1A1A2E)
                                        : Colors.grey.shade400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // ปุ่มเพิ่มโรงเรียนใหม่ / ยกเลิก
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _isAddingNewSchool
              ? _buildNewSchoolInput()
              : GestureDetector(
                  key: const ValueKey('add-btn'),
                  onTap: () => setState(() => _isAddingNewSchool = true),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'เพิ่มโรงเรียนใหม่',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNewSchoolInput() {
    return Column(
      key: const ValueKey('new-school-input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _newSchoolController,
                autofocus: true,
                style:
                    const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
                decoration: _inputDecoration(hintText: 'ชื่อโรงเรียนใหม่'),
                validator: (_) {
                  if (_isAddingNewSchool &&
                      _newSchoolController.text.trim().isEmpty) {
                    return 'กรุณากรอกชื่อโรงเรียน';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _createSchool(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isCreatingSchool ? null : _createSchool,
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isCreatingSchool
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() {
            _isAddingNewSchool = false;
            _newSchoolController.clear();
          }),
          child: Text(
            'ยกเลิก',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  void _showSchoolBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final searchController = TextEditingController();
        List<Map<String, dynamic>> filtered = List.from(_schools);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void onSearch(String q) {
              setModalState(() {
                filtered = _schools
                    .where((s) => (s['name'] as String)
                        .toLowerCase()
                        .contains(q.toLowerCase()))
                    .toList();
              });
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'เลือกโรงเรียน',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      onChanged: onSearch,
                      decoration: _inputDecoration(hintText: 'ค้นหาโรงเรียน'),
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'ไม่พบโรงเรียน',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final school = filtered[i];
                                final id = school['id'].toString();
                                final isSelected = _selectedSchoolId == id;
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  title: Text(
                                    school['name'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : const Color(0xFF1A1A2E),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(Icons.check_rounded,
                                          color: AppTheme.primary, size: 20)
                                      : null,
                                  onTap: () {
                                    setState(() => _selectedSchoolId = id);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    );
  }
}
