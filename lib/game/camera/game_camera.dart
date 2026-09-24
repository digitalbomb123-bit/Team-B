import 'package:flame/components.dart';

/// Configurable camera controller for smooth tracking and zoom.
class GameCameraConfig {
  /// Base camera zoom level.
  /// Higher values zoom in closer, lower values reveal more of the arena.
  static double cameraZoom = 1.1;

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
