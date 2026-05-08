// Logo ServiceFlow (etiqueta com check); texto opcional.
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Marca do app — etiqueta com check.
class AppLogo extends StatelessWidget {
  final double size;
  final bool withText;
  final bool centered;

  const AppLogo({
    super.key,
    this.size = 64,
    this.withText = true,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TagPainter()),
    );

    final text = RichText(
      textAlign: centered ? TextAlign.center : TextAlign.start,
      text: TextSpan(
        style: TextStyle(
          fontSize: centered ? 24 : 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
          letterSpacing: -0.6,
          height: 1.1,
        ),
        children: [
          const TextSpan(text: 'Service'),
          TextSpan(
            text: 'Flow',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        mark,
        if (withText) ...[
          const SizedBox(height: 14),
          text,
          if (centered) ...[
            const SizedBox(height: 6),
            Text(
              'Gestão de ordens de serviço',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Sombra por baixo da etiqueta
    final shadowPath = _tagPath(s, dx: 0, dy: 6);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Etiqueta com degradê
    final tagPath = _tagPath(s);
    final rect = tagPath.getBounds();
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryDark],
    );
    canvas.drawPath(
      tagPath,
      Paint()..shader = gradient.createShader(rect),
    );

    // Buraco do crachá
    final hole = Offset(s * 23 / 64, s * 23 / 64);
    canvas.drawCircle(hole, s * 4.2 / 64, Paint()..color = AppColors.bg);
    canvas.drawCircle(hole, s * 2 / 64, Paint()..color = AppColors.primaryDark);

    // Check
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * 4.5 / 64
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final checkPath = Path()
      ..moveTo(s * 27 / 64, s * 38 / 64)
      ..lineTo(s * 33 / 64, s * 44 / 64)
      ..lineTo(s * 46 / 64, s * 30 / 64);
    canvas.drawPath(checkPath, checkPaint);
  }

  Path _tagPath(double s, {double dx = 0, double dy = 0}) {
    final p = Path();
    final t = (double v) => v / 64 * s;
    p.moveTo(t(8) + dx, t(18) + dy);
    p.lineTo(t(34) + dx, t(8) + dy);
    p.quadraticBezierTo(t(38) + dx, t(6.5) + dy, t(41) + dx, t(9.5) + dy);
    p.lineTo(t(57) + dx, t(25.5) + dy);
    p.quadraticBezierTo(t(60) + dx, t(28.5) + dy, t(58.5) + dx, t(32.5) + dy);
    p.lineTo(t(48) + dx, t(58) + dy);
    p.quadraticBezierTo(t(46.5) + dx, t(62) + dy, t(42.5) + dx, t(60.5) + dy);
    p.lineTo(t(13) + dx, t(49) + dy);
    p.quadraticBezierTo(t(8) + dx, t(47) + dy, t(8) + dx, t(42) + dy);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
