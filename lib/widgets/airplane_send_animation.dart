import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AirplaneSendAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const AirplaneSendAnimation({super.key, this.onComplete});

  @override
  State<AirplaneSendAnimation> createState() => _AirplaneSendAnimationState();
}

class _AirplaneSendAnimationState extends State<AirplaneSendAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward().whenComplete(() => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final envelopeScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );
    final airplaneFly = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic)),
    );
    final airplaneOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7)));
    final airplaneRotation = Tween<double>(begin: 0.0, end: -0.4).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.7, curve: Curves.easeOut)),
    );
    final successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 0.9, curve: Curves.elasticOut)),
    );
    final successOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 0.85, curve: Curves.easeOut)),
    );

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 280,
            height: 340,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Envelope
                Transform.scale(
                  scale: envelopeScale.value,
                  child: Container(
                    width: 100,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.mail_rounded, size: 40, color: Color(0xFF9CA3AF)),
                  ),
                ),

                // Airplane
                Opacity(
                  opacity: airplaneOpacity.value,
                  child: Transform.translate(
                    offset: Offset(airplaneFly.value * 160 - 40, -airplaneFly.value * 200 + 20),
                    child: Transform.rotate(
                      angle: airplaneRotation.value,
                      child: Icon(Icons.send_rounded, size: 48 + airplaneFly.value * 8, color: AppTheme.primary),
                    ),
                  ),
                ),

                // Trail particles
                ..._buildTrailParticles(airplaneFly.value),

                // Success
                Opacity(
                  opacity: successOpacity.value,
                  child: Transform.scale(
                    scale: successScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 44, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ลงทะเบียนสำเร็จ!',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'คุณได้ลงทะเบียนเข้าร่วมกิจกรรมแล้ว',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildTrailParticles(double flyValue) {
    return List.generate(5, (i) {
      final delay = 0.2 + i * 0.06;
      final endDelay = math.min(delay + 0.3, 0.7);
      final particleOpacity = Tween<double>(begin: 0.6, end: 0.0)
          .animate(CurvedAnimation(parent: _controller, curve: Interval(delay, endDelay, curve: Curves.easeIn)))
          .value
          .clamp(0.0, 1.0);
      final particleProgress = Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: _controller, curve: Interval(delay, endDelay, curve: Curves.easeOut)))
          .value;

      final baseX = flyValue * 160 - 40;
      final baseY = -flyValue * 200 + 20;

      return Opacity(
        opacity: particleOpacity,
        child: Transform.translate(
          offset: Offset(
            baseX - 20 - i * 12 + (math.sin(i * 1.5) * 8 * particleProgress),
            baseY + 15 + i * 8 + (particleProgress * 20),
          ),
          child: Container(
            width: 6.0 - i * 0.6,
            height: 6.0 - i * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    });
  }
}
