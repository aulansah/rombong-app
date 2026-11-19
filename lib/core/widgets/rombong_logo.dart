import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Rombong mark (a striped-awning cart) drawn in code, matching
/// `Logo/Mark` in Figma. [withWordmark] adds the "rombong" wordmark.
class RombongLogo extends StatelessWidget {
  const RombongLogo({super.key, this.size = 40, this.withWordmark = false, this.wordmarkColor});

  final double size;
  final bool withWordmark;
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(dimension: size, child: const CustomPaint(painter: _MarkPainter()));
    if (!withWordmark) return Semantics(label: 'Rombong', child: mark);
    return Semantics(
      label: 'Rombong',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.25),
          Text('rombong', style: AppTextStyles.display.copyWith(fontSize: size * 0.7, height: 1, color: wordmarkColor ?? AppColors.primary)),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    Paint p(Color c) => Paint()..color = c;
    // Awning
    canvas.drawRRect(RRect.fromLTRBR(10, 10, 54, 22, const Radius.circular(4)), p(AppColors.primary));
    canvas.drawRect(const Rect.fromLTWH(21, 10, 11, 12), p(AppColors.accent));
    canvas.drawRect(const Rect.fromLTWH(43, 10, 11, 12), p(AppColors.accent));
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(15.5 + i * 11, 22), 5.5, p(i.isEven ? AppColors.primary : AppColors.accent));
    }
    // Cart body, window, handle
    canvas.drawRRect(RRect.fromLTRBR(12, 30, 52, 48, const Radius.circular(5)), p(AppColors.primaryPressed));
    canvas.drawRRect(RRect.fromLTRBR(18, 35, 32, 43, const Radius.circular(2)), p(AppColors.primaryContainer));
    canvas.drawLine(
      const Offset(52, 36),
      const Offset(58, 36),
      p(AppColors.onPrimaryContainer)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Wheels
    for (final x in [21.0, 43.0]) {
      canvas.drawCircle(Offset(x, 52), 5, p(AppColors.text));
      canvas.drawCircle(Offset(x, 52), 2, p(AppColors.background));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
