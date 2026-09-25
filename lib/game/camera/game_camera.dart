import 'package:flame/components.dart';

/// Configurable camera controller for smooth tracking and zoom.
class GameCameraConfig {
  /// Base camera zoom level.
  /// Higher values zoom in closer, lower values reveal more of the arena.
  static double cameraZoom = 1.1;

  /// Convert weapon zoom level (e.g. 2.0x, 2.5x, 3.0x, 6.0x) into Flame camera viewfinder zoom.
  /// Higher weapon zoom = wider tactical FOV (zoomed out).
  static double getCameraZoomForWeaponZoom(double weaponZoom) {
    if (weaponZoom <= 1.0) return 1.0;
    // Maps 1.0x -> 1.0, 2.0x -> ~0.82, 3.0x -> ~0.69, 6.0x -> ~0.48
    final zoomOut = 1.0 / (1.0 + (weaponZoom - 1.0) * 0.22);
    return zoomOut.clamp(0.48, 1.1);
  }

  /// Logical game viewport dimensions.
  /// The game renders at this logical coordinate resolution and scales responsively.
  static const double logicalWidth = 960.0;
  static const double logicalHeight = 540.0;

  /// Clamps camera center so it doesn't pan outside the arena bounds.
  static Vector2 clampToArena({
    required Vector2 target,
    required double arenaWidth,
    required double arenaHeight,
    required Vector2 viewportSize,
    required double zoom,
  }) {
    final halfViewW = (viewportSize.x / zoom) / 2;
    final halfViewH = (viewportSize.y / zoom) / 2;

    final clampedX = target.x.clamp(halfViewW, arenaWidth - halfViewW);
    final clampedY = target.y.clamp(halfViewH, arenaHeight - halfViewH);

    return Vector2(clampedX, clampedY);
  }
}
