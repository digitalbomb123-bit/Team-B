import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A wooden tactical combat cabin / outpost structure.
/// Adds verticality, shelter, and atmospheric frontier detail to the arena.
class WoodCabinComponent extends PositionComponent {
  WoodCabinComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;

    // 1. Cabin Wall Planks (Rustic Timber horizontal logs)
    final wallPaintDark = Paint()..color = const Color(0xFF451A03);
    final wallPaintMed = Paint()..color = const Color(0xFF78350F);
    final wallPaintLight = Paint()..color = const Color(0xFF92400E);
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);

    // Wall background
    canvas.drawRect(Rect.fromLTWH(8, 24, w - 16, h - 24), wallPaintMed);

    // Horizontal timber logs
    const logHeight = 14.0;
    for (double y = 24; y < h; y += logHeight) {
      canvas.drawLine(Offset(8, y), Offset(w - 8, y), wallPaintDark..strokeWidth = 2.0);
      canvas.drawLine(Offset(10, y + 2), Offset(w - 10, y + 2), wallPaintLight..strokeWidth = 1.0);
    }

    // Corner vertical support beams
    canvas.drawRect(Rect.fromLTWH(4, 20, 12, h - 20), wallPaintDark);
    canvas.drawRect(Rect.fromLTWH(w - 16, 20, 12, h - 20), wallPaintDark);

    // 2. Doorway (Dark interior entrance)
    final doorW = w * 0.28;
    final doorH = h * 0.55;
    final doorX = (w - doorW) / 2;
    final doorY = h - doorH;

    canvas.drawRect(Rect.fromLTWH(doorX, doorY, doorW, doorH), Paint()..color = const Color(0xFF0F172A));
    // Door frame
    final framePaint = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(Rect.fromLTWH(doorX, doorY, doorW, doorH), framePaint);

    // 3. Side Windows with Crossbars
    if (w >= 120) {
      final winSize = 22.0;
      final winY = 42.0;

      // Left Window
      _drawWindow(canvas, 24, winY, winSize);
      // Right Window
      _drawWindow(canvas, w - 24 - winSize, winY, winSize);
    }

    // 4. Overhanging Pitched Roof
    final roofPath = Path()
      ..moveTo(0, 24)
      ..lineTo(w / 2, 0)
      ..lineTo(w, 24)
      ..lineTo(w - 6, 28)
      ..lineTo(w / 2, 6)
      ..lineTo(6, 28)
      ..close();

    final roofPaint = Paint()..color = const Color(0xFF291205);
    canvas.drawPath(roofPath, roofPaint);

    // Roof shingles / ridge line
    final ridgePaint = Paint()
      ..color = const Color(0xFFB45309)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 24), Offset(w / 2, 0), ridgePaint);
    canvas.drawLine(Offset(w / 2, 0), Offset(w, 24), ridgePaint);

    // Roof shadow cast down wall
    canvas.drawRect(Rect.fromLTWH(8, 24, w - 16, 6), shadowPaint);

    // 5. Stencil / Signage
    final textSpan = TextSpan(
      text: 'OUTPOST',
      style: TextStyle(
        color: const Color(0xFFFDE68A).withValues(alpha: 0.65),
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, 28));
  }

  void _drawWindow(Canvas canvas, double x, double y, double size) {
    // Glass glow
    canvas.drawRect(
      Rect.fromLTWH(x, y, size, size),
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.35),
    );
    // Wood frame
    final frame = Paint()
      ..color = const Color(0xFF451A03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(x, y, size, size), frame);
    // Crossbars
    canvas.drawLine(Offset(x + size / 2, y), Offset(x + size / 2, y + size), frame);
    canvas.drawLine(Offset(x, y + size / 2), Offset(x + size, y + size / 2), frame);
  }
}
