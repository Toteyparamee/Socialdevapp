import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

enum UserRole { student, teacher, general }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  UserRole? _selectedRole;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _buttonController.dispose();
    _entranceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
      _usernameController.clear();
      _passwordController.clear();
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
    _fadeController.reset();
    _fadeController.forward();
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
    setState(() => _errorMessage = null);
  }

  String get _usernameHint {
    return switch (_selectedRole ?? UserRole.student) {
      UserRole.student => 'รหัสนักเรียน',
      UserRole.teacher => 'อีเมล',
      UserRole.general => 'เบอร์โทร หรือ อีเมล',
    };
  }

  String? get _helperText {
    if (_selectedRole == UserRole.student) return 'ตัวอย่าง: 65012345';
    return null;
  }

  String get _roleLabel {
    return switch (_selectedRole) {
      UserRole.student => 'นักเรียน',
      UserRole.teacher => 'ครู',
      UserRole.general => 'บุคคลทั่วไป',
      null => '',
    };
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Mock credentials
    const mockAccounts = {
      UserRole.student: {'username': '65012345', 'password': '1234'},
      UserRole.teacher: {'username': 'teacher@school.ac.th', 'password': '1234'},
      UserRole.general: {'username': '0812345678', 'password': '1234'},
    };

    final mock = mockAccounts[_selectedRole]!;
    if (_usernameController.text != mock['username'] ||
        _passwordController.text != mock['password']) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
      });
      return;
    }

    final roleName = switch (_selectedRole!) {
      UserRole.student => 'student',
      UserRole.teacher => 'teacher',
      UserRole.general => 'general',
    };

    await context.read<AuthService>().login(
          username: _usernameController.text,
          role: roleName,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Pop LoginScreen so AuthGate rebuilds to HomeScreen
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            _buildRolePage(),
            _buildLoginPage(),
          ],
        ),
      ),
    );
  }

  // ─── Page 1: เลือกบทบาท ──────────────────────────────────────────────

  Widget _buildRolePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // Step indicator
          _buildStepBadge('ขั้นตอนที่ 1'),
          const SizedBox(height: 24),
          // Title
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
                  'คุณเป็นใคร?',
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
                  'เลือกบทบาทของคุณเพื่อเริ่มต้นใช้งาน',
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
          const SizedBox(height: 40),
          // Role options
          Expanded(
            child: Column(
              children: [
                _buildRoleTile(
                  role: UserRole.student,
                  label: 'นักเรียน',
                  subtitle: 'Student',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF3B82F6),
                  index: 0,
                ),
                const SizedBox(height: 12),
                _buildRoleTile(
                  role: UserRole.teacher,
                  label: 'ครู / อาจารย์',
                  subtitle: 'Teacher',
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFF8B5CF6),
                  index: 1,
                ),
                const SizedBox(height: 12),
                _buildRoleTile(
                  role: UserRole.general,
                  label: 'บุคคลทั่วไป',
                  subtitle: 'General',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF10B981),
                  index: 2,
                ),
              ],
            ),
          ),
          // Page dots
          Center(child: _buildDots()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRoleTile({
    required UserRole role,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final interval = Interval(
          0.15 + index * 0.12,
          0.55 + index * 0.12,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<double>(begin: 30.0, end: 0.0)
            .animate(CurvedAnimation(
              parent: _entranceController,
              curve: interval,
            ))
            .value;
        final opacity = CurvedAnimation(
          parent: _entranceController,
          curve: interval,
        ).value;

        return Transform.translate(
          offset: Offset(0, slide),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _selectRole(role),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 2: เข้าสู่ระบบ ─────────────────────────────────────────────

  Widget _buildLoginPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Back button
          GestureDetector(
            onTap: _goBack,
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
          _buildStepBadge('ขั้นตอนที่ 2'),
          const SizedBox(height: 24),
          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                // Role chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // Form
          FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username label
                  Text(
                    _selectedRole == UserRole.student
                        ? 'รหัสนักเรียน'
                        : _selectedRole == UserRole.teacher
                            ? 'อีเมล'
                            : 'เบอร์โทร / อีเมล',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: _selectedRole == UserRole.student
                        ? TextInputType.number
                        : TextInputType.emailAddress,
                    inputFormatters: _selectedRole == UserRole.student
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      hintText: _usernameHint,
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
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      helperText: _helperText,
                      helperStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณากรอกข้อมูล';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password label
                  const Text(
                    'รหัสผ่าน',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'รหัสผ่าน',
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
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
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
                      if (v.length < 4) return 'รหัสผ่านต้องมีอย่างน้อย 4 ตัว';
                      return null;
                    },
                  ),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                      ),
                      child: Text(
                        'ลืมรหัสผ่าน?',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  // Error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Login button
                  ScaleTransition(
                    scale: _buttonScale,
                    child: GestureDetector(
                      onTapDown: (_) => _buttonController.forward(),
                      onTapUp: (_) {
                        _buttonController.reverse();
                        _handleLogin();
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
                                  'เข้าสู่ระบบ',
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
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE8ECF0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'หรือ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE8ECF0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Google sign in
                  GestureDetector(
                    onTap: () {
                      // TODO: implement Google sign in
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8ECF0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(
                              painter: _GoogleLogoPainter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'เข้าสู่ระบบด้วย Google',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sign up
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ยังไม่มีบัญชี? ',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'สมัครสมาชิก',
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
                  const SizedBox(height: 16),
                  // Page dots
                  Center(child: _buildDots()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared ───────────────────────────────────────────────────────────

  Widget _buildStepBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    // Blue (top-right arc)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.6, // ~-34 deg
      -1.8, // ~-103 deg
      true,
      bluePaint,
    );

    // Green (bottom-right arc)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.9, // ~52 deg
      1.2, // ~69 deg
      true,
      greenPaint,
    );

    // Yellow (bottom-left arc)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      2.1, // ~120 deg
      1.0, // ~57 deg
      true,
      yellowPaint,
    );

    // Red (top-left arc)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.1, // ~178 deg
      0.9, // ~52 deg
      true,
      redPaint,
    );

    // White center circle
    final whitePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, whitePaint);

    // Blue right bar (the "notch")
    final barRect = RRect.fromLTRBR(
      cx - w * 0.03,
      cy - h * 0.12,
      w + w * 0.02,
      cy + h * 0.12,
      const Radius.circular(1),
    );
    canvas.drawRRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
