import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlyingPlane extends StatefulWidget {
  final Color color;
  final double size;

  const FlyingPlane({super.key, this.color = Colors.white, this.size = 40});

  @override
  State<FlyingPlane> createState() => _FlyingPlaneState();
}

class _FlyingPlaneState extends State<FlyingPlane> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _bobController;
  late Animation<double> _moveX;
  late Animation<double> _bobY;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _moveX = Tween<double>(begin: -0.6, end: 0.6).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );

    _bobY = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _bobController]),
      builder: (_, __) {
        final goingRight = _moveController.value < 0.5;
        return Align(
          alignment: Alignment(_moveX.value, 0),
          child: Transform.translate(
            offset: Offset(0, _bobY.value),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(goingRight ? 0 : math.pi),
              child: _buildPlane(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlane() {
    return CustomPaint(
      size: Size(widget.size * 1.8, widget.size),
      painter: _PlanePainter(color: widget.color),
    );
  }
}

class _PlanePainter extends CustomPainter {
  final Color color;
  _PlanePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // fuselage
    final body = Path()
      ..moveTo(w * 0.85, h * 0.5)
      ..quadraticBezierTo(w * 0.6, h * 0.3, w * 0.1, h * 0.45)
      ..lineTo(w * 0.1, h * 0.55)
      ..quadraticBezierTo(w * 0.6, h * 0.7, w * 0.85, h * 0.5)
      ..close();
    canvas.drawPath(body, paint);

    // nose
    final nose = Path()
      ..moveTo(w * 0.85, h * 0.45)
      ..quadraticBezierTo(w * 1.0, h * 0.5, w * 0.85, h * 0.55)
      ..close();
    canvas.drawPath(nose, paint);

    // main wing
    final wing = Path()
      ..moveTo(w * 0.55, h * 0.45)
      ..lineTo(w * 0.3, h * 0.05)
      ..lineTo(w * 0.25, h * 0.05)
      ..lineTo(w * 0.42, h * 0.48)
      ..close();
    canvas.drawPath(wing, paint);

    // tail wing
    final tail = Path()
      ..moveTo(w * 0.18, h * 0.45)
      ..lineTo(w * 0.05, h * 0.2)
      ..lineTo(w * 0.03, h * 0.2)
      ..lineTo(w * 0.13, h * 0.48)
      ..close();
    canvas.drawPath(tail, paint);

    // engine
    final engine = Path()
      ..moveTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.35, h * 0.52)
      ..lineTo(w * 0.33, h * 0.62)
      ..lineTo(w * 0.48, h * 0.62)
      ..close();
    canvas.drawPath(engine, paint..color = color.withValues(alpha: 0.8));

    // window
    canvas.drawCircle(
      Offset(w * 0.65, h * 0.46),
      h * 0.07,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.45),
      h * 0.06,
      Paint()..color = color.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(_PlanePainter old) => old.color != color;
}
