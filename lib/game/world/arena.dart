import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/platform.dart';
import '../components/scenery_elements.dart';
import '../components/wood_cabin.dart';

/// Defines the 2D arena layout, background grid, platforms, boundaries, and spawn points.
class ArenaComponent extends PositionComponent {
  static const double arenaWidth = 2400.0;
  static const double arenaHeight = 1200.0;

  final List<PlatformComponent> platforms = [];
  final List<Vector2> spawnPoints = [
    Vector2(300, 950),
    Vector2(700, 950),
    Vector2(1200, 950),
    Vector2(1700, 950),
    Vector2(2100, 950),
    Vector2(500, 720),
    Vector2(1100, 720),
    Vector2(1700, 720),
    Vector2(850, 480),
    Vector2(1450, 480),
  ];

  ArenaComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(arenaWidth, arenaHeight),
          anchor: Anchor.topLeft,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Arena Ground
    final ground = PlatformComponent(
      position: Vector2(0, 1000),
      size: Vector2(arenaWidth, 200),
      platformType: PlatformType.ground,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF38BDF8),
    );
    platforms.add(ground);
    add(ground);

    // 2. Ceiling / Top boundary
    final ceiling = PlatformComponent(
      position: Vector2(0, 0),
      size: Vector2(arenaWidth, 40),
      platformType: PlatformType.barrier,
      baseColor: const Color(0xFF0F172A),
      accentColor: const Color(0xFF475569),
    );
    platforms.add(ceiling);
    add(ceiling);

    // 3. Left & Right Boundary Walls
    final leftWall = PlatformComponent(
      position: Vector2(0, 0),
      size: Vector2(40, arenaHeight),
      platformType: PlatformType.wall,
      baseColor: const Color(0xFF0F172A),
      accentColor: const Color(0xFF0284C7),
    );
    final rightWall = PlatformComponent(
      position: Vector2(arenaWidth - 40, 0),
      size: Vector2(40, arenaHeight),
      platformType: PlatformType.wall,
      baseColor: const Color(0xFF0F172A),
      accentColor: const Color(0xFF0284C7),
    );
    platforms.addAll([leftWall, rightWall]);
    add(leftWall);
    add(rightWall);

    // 4. Wood Cabins (Tactical Outposts)
    // Cabin Alpha (Left)
    final cabinLeft = WoodCabinComponent(
      position: Vector2(340, 880),
      size: Vector2(160, 120),
    );
    // Roof Platform for Cabin Alpha
    final cabinLeftRoof = PlatformComponent(
      position: Vector2(340, 880),
      size: Vector2(160, 20),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF78350F),
      accentColor: const Color(0xFFF59E0B),
    );

    // Cabin Bravo (Right)
    final cabinRight = WoodCabinComponent(
      position: Vector2(1840, 880),
      size: Vector2(160, 120),
    );
    // Roof Platform for Cabin Bravo
    final cabinRightRoof = PlatformComponent(
      position: Vector2(1840, 880),
      size: Vector2(160, 20),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF78350F),
      accentColor: const Color(0xFFF59E0B),
    );

    // High Watchtower Cabin (Center Sniper Outpost)
    final cabinCenter = WoodCabinComponent(
      position: Vector2(1120, 380),
      size: Vector2(130, 80),
    );

    add(cabinLeft);
    add(cabinRight);
    add(cabinCenter);
    platforms.addAll([cabinLeftRoof, cabinRightRoof]);
    add(cabinLeftRoof);
    add(cabinRightRoof);

    // 5. Tactical Granite Boulders & Stones
    final stones = [
      StoneComponent(position: Vector2(180, 1000), radius: 22, seed: 1),
      StoneComponent(position: Vector2(560, 1000), radius: 16, seed: 2),
      StoneComponent(position: Vector2(760, 1000), radius: 20, seed: 3),
      StoneComponent(position: Vector2(1100, 1000), radius: 24, seed: 4),
      StoneComponent(position: Vector2(1380, 1000), radius: 19, seed: 5),
      StoneComponent(position: Vector2(1740, 1000), radius: 21, seed: 6),
      StoneComponent(position: Vector2(2080, 1000), radius: 23, seed: 7),
      StoneComponent(position: Vector2(650, 640), radius: 14, seed: 8),
      StoneComponent(position: Vector2(1600, 640), radius: 15, seed: 9),
    ];
    for (final s in stones) {
      add(s);
    }

    // 6. Natural Foliage Camouflage Bushes
    final bushes = [
      BushComponent(position: Vector2(130, 1000), radius: 24, seed: 10),
      BushComponent(position: Vector2(250, 1000), radius: 20, seed: 11),
      BushComponent(position: Vector2(520, 1000), radius: 26, seed: 12),
      BushComponent(position: Vector2(850, 1000), radius: 25, seed: 13),
      BushComponent(position: Vector2(1420, 1000), radius: 23, seed: 14),
      BushComponent(position: Vector2(1700, 1000), radius: 27, seed: 15),
      BushComponent(position: Vector2(2020, 1000), radius: 25, seed: 16),
      BushComponent(position: Vector2(2200, 1000), radius: 22, seed: 17),
      // On platforms
      BushComponent(position: Vector2(380, 840), radius: 18, seed: 18),
      BushComponent(position: Vector2(1200, 820), radius: 20, seed: 19),
      BushComponent(position: Vector2(1900, 840), radius: 18, seed: 20),
      BushComponent(position: Vector2(720, 640), radius: 17, seed: 21),
    ];
    for (final b in bushes) {
      add(b);
    }

    // 7. Low Level Tactical Platforms (Height ~ 820-840)
    final low1 = PlatformComponent(
      position: Vector2(250, 840),
      size: Vector2(380, 26),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF38BDF8),
    );
    final low2 = PlatformComponent(
      position: Vector2(1000, 820),
      size: Vector2(400, 26),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF38BDF8),
    );
    final low3 = PlatformComponent(
      position: Vector2(1750, 840),
      size: Vector2(380, 26),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF38BDF8),
    );
    platforms.addAll([low1, low2, low3]);
    add(low1);
    add(low2);
    add(low3);

    // 8. Mid Level Platforms (Height ~ 640)
    final mid1 = PlatformComponent(
      position: Vector2(520, 640),
      size: Vector2(350, 26),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF22C55E),
    );
    final mid2 = PlatformComponent(
      position: Vector2(1500, 640),
      size: Vector2(350, 26),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF22C55E),
    );
    platforms.addAll([mid1, mid2]);
    add(mid1);
    add(mid2);

    // 9. High Sniper Tower / Center Platform (Height ~ 460)
    final highCenter = PlatformComponent(
      position: Vector2(950, 460),
      size: Vector2(500, 28),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFFF59E0B),
    );
    final highLeft = PlatformComponent(
      position: Vector2(200, 380),
      size: Vector2(260, 24),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFFF59E0B),
    );
    final highRight = PlatformComponent(
      position: Vector2(1940, 380),
      size: Vector2(260, 24),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFFF59E0B),
    );
    platforms.addAll([highCenter, highLeft, highRight]);
    add(highCenter);
    add(highLeft);
    add(highRight);
  }

  @override
  void render(Canvas canvas) {
    // 1. Arena Background Fill (FIRST so it forms the base layer)
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 2. Tactical Combat Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y <= height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // 3. Tactical Sector Markings
    _drawSectorMark(canvas, 'SECTOR ALPHA - COMBAT ZONE', const Offset(150, 100));
    _drawSectorMark(canvas, 'COMMAND CENTER', const Offset(1100, 100));
    _drawSectorMark(canvas, 'SECTOR BRAVO - RESUPPLY', const Offset(1800, 100));

    // 4. Render all children (ground, walls, tactical platforms) ON TOP of background
    super.render(canvas);
  }

  void _drawSectorMark(Canvas canvas, String label, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  /// Get random spawn position
  Vector2 getRandomSpawn(int index) {
    return spawnPoints[index % spawnPoints.length].clone();
  }
}
