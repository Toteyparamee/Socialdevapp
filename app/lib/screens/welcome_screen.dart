import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _bgAnimController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  final _pages = const [
    _PageData(
      icon: Icons.map_rounded,
      secondaryIcon: Icons.location_on_rounded,
      title: 'แจ้งปัญหาชุมชน',
      subtitle: 'Community Problem Report',
      description: 'แพลตฟอร์มสำหรับแจ้งปัญหาในชุมชน\nให้ทุกคนมีส่วนร่วมพัฒนาท้องถิ่น',
      gradient: [Color(0xFF4A90D9), Color(0xFF7C5CE0)],
    ),
    _PageData(
      icon: Icons.campaign_rounded,
      secondaryIcon: Icons.edit_location_alt_rounded,
      title: 'รายงานปัญหาง่ายๆ',
      subtitle: 'Report Problems Easily',
      description: 'ถ่ายรูป ปักหมุด แจ้งปัญหาได้ทันที\nระบุตำแหน่งผ่านแผนที่อัตโนมัติ',
      gradient: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
    _PageData(
      icon: Icons.track_changes_rounded,
      secondaryIcon: Icons.verified_rounded,
      title: 'ติดตามสถานะ',
      subtitle: 'Track Progress',
      description: 'ติดตามความคืบหน้าแบบเรียลไทม์\nตั้งแต่รับแจ้ง กำลังดำเนินการ จนแก้ไขเสร็จ',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    _PageData(
      icon: Icons.people_alt_rounded,
      secondaryIcon: Icons.volunteer_activism_rounded,
      title: 'ร่วมมือกัน',
      subtitle: 'Work Together',
      description: 'นักเรียน ครู และชุมชน ร่วมมือกัน\nสร้างสังคมที่ดีขึ้นไปด้วยกัน',
      gradient: [Color(0xFFA78BFA), Color(0xFFEC4899)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              final page = _pages[_currentPage];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(_bgAnimController.value * 2 * math.pi) * 0.5,
                      math.sin(_bgAnimController.value * 2 * math.pi) * 0.5 - 0.5,
                    ),
                    end: Alignment(
                      math.sin(_bgAnimController.value * 2 * math.pi) * 0.5,
                      math.cos(_bgAnimController.value * 2 * math.pi) * 0.5 + 0.5,
                    ),
                    colors: page.gradient,
                  ),
                ),
              );
            },
          ),

          // Floating decorative circles
          ..._buildFloatingCircles(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        'ข้าม',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action button
                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final isLast = _currentPage == _pages.length - 1;
                            return Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.1 + _pulseController.value * 0.05,
                                    ),
                                    blurRadius: 20 + _pulseController.value * 8,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLast ? 'เริ่มต้นใช้งาน' : 'ถัดไป',
                                    style: TextStyle(
                                      color: _pages[_currentPage].gradient[0],
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isLast
                                        ? Icons.arrow_forward_rounded
                                        : Icons.chevron_right_rounded,
                                    color: _pages[_currentPage].gradient[0],
                                    size: 22,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_PageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingController.value * 12 - 6),
                child: child,
              );
            },
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      page.icon,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  // Secondary floating icon
                  Positioned(
                    right: 40,
                    top: 20,
                    child: AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            _floatingController.value * 6 - 3,
                            -_floatingController.value * 8 + 4,
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          page.secondaryIcon,
                          size: 26,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  // Small decorative dot
                  Positioned(
                    left: 50,
                    bottom: 30,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.8 + _pulseController.value * 0.4,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingCircles() {
    return [
      _FloatingCircle(
        animation: _bgAnimController,
        size: 200,
        left: -60,
        top: -40,
        opacity: 0.08,
      ),
      _FloatingCircle(
        animation: _bgAnimController,
        size: 150,
        right: -30,
        top: 120,
        opacity: 0.06,
        reverse: true,
      ),
      _FloatingCircle(
        animation: _bgAnimController,
        size: 100,
        left: 30,
        bottom: 180,
        opacity: 0.07,
      ),
      _FloatingCircle(
        animation: _bgAnimController,
        size: 180,
        right: -50,
        bottom: 60,
        opacity: 0.05,
        reverse: true,
      ),
    ];
  }
}

class _FloatingCircle extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double opacity;
  final bool reverse;

  const _FloatingCircle({
    required this.animation,
    required this.size,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.opacity = 0.1,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final val = reverse
            ? 1.0 - animation.value
            : animation.value;
        return Positioned(
          left: left != null
              ? left! + math.sin(val * 2 * math.pi) * 20
              : null,
          right: right != null
              ? right! + math.cos(val * 2 * math.pi) * 15
              : null,
          top: top != null
              ? top! + math.cos(val * 2 * math.pi) * 20
              : null,
          bottom: bottom != null
              ? bottom! + math.sin(val * 2 * math.pi) * 15
              : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}

class _PageData {
  final IconData icon;
  final IconData secondaryIcon;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;

  const _PageData({
    required this.icon,
    required this.secondaryIcon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
  });
}
