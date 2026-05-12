import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: AppColors.background),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _OrbPainter(_controller.value),
              );
            },
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  _OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      _Orb(
        center: Offset(size.width * 0.2, size.height * 0.15),
        radius: size.width * 0.35,
        color: AppColors.primary.withValues(alpha: 0.06),
        speed: 1.0,
      ),
      _Orb(
        center: Offset(size.width * 0.8, size.height * 0.3),
        radius: size.width * 0.3,
        color: AppColors.secondary.withValues(alpha: 0.05),
        speed: 0.7,
      ),
      _Orb(
        center: Offset(size.width * 0.5, size.height * 0.7),
        radius: size.width * 0.4,
        color: AppColors.primary.withValues(alpha: 0.04),
        speed: 0.5,
      ),
      _Orb(
        center: Offset(size.width * 0.1, size.height * 0.85),
        radius: size.width * 0.25,
        color: AppColors.secondary.withValues(alpha: 0.05),
        speed: 0.8,
      ),
    ];

    for (final orb in orbs) {
      final angle = progress * 2 * pi * orb.speed;
      final dx = cos(angle) * 30;
      final dy = sin(angle) * 20;
      final center = orb.center + Offset(dx, dy);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orb.color, orb.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: orb.radius));

      canvas.drawCircle(center, orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.progress != progress;
}

class _Orb {
  final Offset center;
  final double radius;
  final Color color;
  final double speed;

  const _Orb({
    required this.center,
    required this.radius,
    required this.color,
    required this.speed,
  });
}
