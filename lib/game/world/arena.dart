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
    Vector2(520, 950),
    Vector2(1000, 950),
    Vector2(1250, 950),
    Vector2(1800, 950),
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
        ) {
    _initPlatforms();
  }

  void _initPlatforms() {
    // 1. Arena Ground with Tactical Abyss Pits/Gaps
    // Ground Section Alpha (Left)
    final groundLeft = PlatformComponent(
      position: Vector2(0, 1000),
      size: Vector2(650, 200),
      platformType: PlatformType.ground,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF38BDF8),
    );
    // Ground Section Center (Island)
    final groundCenter = PlatformComponent(
      position: Vector2(880, 1000),
      size: Vector2(540, 200),
      platformType: PlatformType.ground,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF38BDF8),
    );
    // Ground Section Bravo (Right)
    final groundRight = PlatformComponent(
      position: Vector2(1660, 1000),
      size: Vector2(740, 200),
      platformType: PlatformType.ground,
      baseColor: const Color(0xFF1E293B),
      accentColor: const Color(0xFF38BDF8),
    );

    // 2. Ceiling / Top boundary
    final ceiling = PlatformComponent(
      position: Vector2(0, 0),
      size: Vector2(arenaWidth, 40),
      platformType: PlatformType.barrier,
      baseColor: const Color(0xFF0F172A),
      accentColor: const Color(0xFF475569),
    );

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

    // 4. Roof Platforms for Cabins
    final cabinLeftRoof = PlatformComponent(
      position: Vector2(340, 880),
      size: Vector2(160, 20),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF78350F),
      accentColor: const Color(0xFFF59E0B),
    );
    final cabinRightRoof = PlatformComponent(
      position: Vector2(1840, 880),
      size: Vector2(160, 20),
      platformType: PlatformType.floating,
      baseColor: const Color(0xFF78350F),
      accentColor: const Color(0xFFF59E0B),
    );

    // 7. Low Level Tactical Platforms
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

    // 8. Mid Level Platforms
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

    // 9. High Sniper Tower / Center Platform
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

    platforms.addAll([
      groundLeft,
      groundCenter,
      groundRight,
      ceiling,
      leftWall,
      rightWall,
      cabinLeftRoof,
      cabinRightRoof,
      low1,
      low2,
      low3,
      mid1,
      mid2,
      highCenter,
      highLeft,
      highRight,
    ]);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (final p in platforms) {
      add(p);
    }

    // 1. Wood Cabins (Tactical Outposts)
    final cabinLeft = WoodCabinComponent(
      position: Vector2(340, 880),
      size: Vector2(160, 120),
    );
    final cabinRight = WoodCabinComponent(
      position: Vector2(1840, 880),
      size: Vector2(160, 120),
    );
    final cabinCenter = WoodCabinComponent(
      position: Vector2(1120, 380),
      size: Vector2(130, 80),
    );

    add(cabinLeft);
    add(cabinRight);
    add(cabinCenter);

    // 2. Tactical Granite Boulders & Stones
    final stones = [
      StoneComponent(position: Vector2(180, 1000), radius: 22, seed: 1),
      StoneComponent(position: Vector2(450, 1000), radius: 16, seed: 2),
      StoneComponent(position: Vector2(560, 1000), radius: 20, seed: 3),
      StoneComponent(position: Vector2(1000, 1000), radius: 24, seed: 4),
      StoneComponent(position: Vector2(1180, 1000), radius: 19, seed: 5),
      StoneComponent(position: Vector2(1340, 1000), radius: 21, seed: 6),
      StoneComponent(position: Vector2(1740, 1000), radius: 23, seed: 7),
      StoneComponent(position: Vector2(2080, 1000), radius: 21, seed: 8),
      StoneComponent(position: Vector2(650, 640), radius: 14, seed: 9),
      StoneComponent(position: Vector2(1600, 640), radius: 15, seed: 10),
    ];
    for (final s in stones) {
      add(s);
    }

    // 3. Natural Foliage Camouflage Bushes
    final bushes = [
      BushComponent(position: Vector2(130, 1000), radius: 24, seed: 11),
      BushComponent(position: Vector2(250, 1000), radius: 20, seed: 12),
      BushComponent(position: Vector2(520, 1000), radius: 26, seed: 13),
      BushComponent(position: Vector2(950, 1000), radius: 25, seed: 14),
      BushComponent(position: Vector2(1250, 1000), radius: 23, seed: 15),
      BushComponent(position: Vector2(1720, 1000), radius: 27, seed: 16),
      BushComponent(position: Vector2(2020, 1000), radius: 25, seed: 17),
      BushComponent(position: Vector2(2200, 1000), radius: 22, seed: 18),
      // On platforms
      BushComponent(position: Vector2(380, 840), radius: 18, seed: 19),
      BushComponent(position: Vector2(1200, 820), radius: 20, seed: 20),
      BushComponent(position: Vector2(1900, 840), radius: 18, seed: 21),
      BushComponent(position: Vector2(720, 640), radius: 17, seed: 22),
    ];
    for (final b in bushes) {
      add(b);
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Beautiful Daylight Sky Gradient Background
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0284C7), // Deep azure sky
          Color(0xFF38BDF8), // Clear vibrant sky blue
          Color(0xFF7DD3FC), // Soft atmospheric daylight tint
          Color(0xFFBAE6FD), // Light horizon haze
        ],
        stops: [0.0, 0.38, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), skyPaint);

    // 2. Soft Stylized Fluffy Sky Clouds
    _drawClouds(canvas);

    // 3. Subtle Tactical Combat Coordinate Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= width; x += 150) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y <= height; y += 150) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // 4. Tactical Sector Markings
    _drawSectorMark(canvas, 'SECTOR ALPHA - SKY ARENA', const Offset(150, 90));
    _drawSectorMark(canvas, 'COMMAND CENTER', const Offset(1100, 90));
    _drawSectorMark(canvas, 'SECTOR BRAVO - HIGHLANDS', const Offset(1800, 90));

    // 5. Render all children (ground, walls, tactical platforms) ON TOP of sky
    super.render(canvas);
  }

  void _drawClouds(Canvas canvas) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;

    final cloudHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    final cloudPositions = [
      const Offset(240, 180),
      const Offset(680, 140),
      const Offset(1180, 190),
      const Offset(1650, 130),
      const Offset(2080, 170),
      const Offset(450, 310),
      const Offset(950, 320),
      const Offset(1450, 300),
      const Offset(1920, 280),
    ];

    for (final pos in cloudPositions) {
      canvas.drawCircle(pos, 36, cloudPaint);
      canvas.drawCircle(pos + const Offset(-22, 5), 24, cloudPaint);
      canvas.drawCircle(pos + const Offset(24, 5), 26, cloudPaint);
      canvas.drawCircle(pos + const Offset(-8, -8), 22, cloudHighlight);
    }
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
