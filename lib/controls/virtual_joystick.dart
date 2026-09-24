import 'dart:math';
import 'package:flutter/material.dart';

enum VirtualJoystickMode {
  movement,
  aimAndFire,
}

/// Semi-transparent, responsive on-screen virtual joystick.
/// Supports both movement/jetpack mode (left) and 360° aim & fire mode (right).
class VirtualJoystick extends StatefulWidget {
  final double radius;
  final VirtualJoystickMode mode;
  final ValueChanged<Offset>? onVectorChanged;
  final ValueChanged<double>? onDirectionChanged;
  final void Function(double angle, bool isFiring)? onAimChanged;
  final VoidCallback? onReleased;

  const VirtualJoystick({
    super.key,
    this.radius = 64.0,
    this.mode = VirtualJoystickMode.movement,
    this.onVectorChanged,
    this.onDirectionChanged,
    this.onAimChanged,
    this.onReleased,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _dragOffset = Offset.zero;

  void _updateFromLocalPosition(Offset localPosition) {
    final center = Offset(widget.radius, widget.radius);
    final rawOffset = localPosition - center;
    final distance = rawOffset.distance;
    final clampedOffset = distance > widget.radius
        ? Offset.fromDirection(rawOffset.direction, widget.radius)
        : rawOffset;

    setState(() {
      _dragOffset = clampedOffset;
    });

    final normalized = Offset(
      (_dragOffset.dx / widget.radius).clamp(-1.0, 1.0),
      (_dragOffset.dy / widget.radius).clamp(-1.0, 1.0),
    );

    widget.onVectorChanged?.call(normalized);
    widget.onDirectionChanged?.call(normalized.dx);

    if (widget.mode == VirtualJoystickMode.aimAndFire) {
      final dist = _dragOffset.distance;
      if (dist > 8.0) {
        final angle = atan2(_dragOffset.dy, _dragOffset.dx);
        widget.onAimChanged?.call(angle, true);
      } else {
        widget.onAimChanged?.call(0.0, false);
      }
    }
  }

  void _handlePanEnd() {
    setState(() {
      _dragOffset = Offset.zero;
    });
    widget.onVectorChanged?.call(Offset.zero);
    widget.onDirectionChanged?.call(0.0);
    if (widget.mode == VirtualJoystickMode.aimAndFire) {
      widget.onAimChanged?.call(0.0, false);
    }
    widget.onReleased?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    final isAim = widget.mode == VirtualJoystickMode.aimAndFire;

    final primaryColor = isAim ? const Color(0xFFEF4444) : const Color(0xFF38BDF8);
    final secondaryColor = isAim ? const Color(0xFFB91C1C) : const Color(0xFF0284C7);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (d) => _updateFromLocalPosition(d.localPosition),
      onPanUpdate: (d) => _updateFromLocalPosition(d.localPosition),
      onPanEnd: (_) => _handlePanEnd(),
      onPanCancel: _handlePanEnd,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.38),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.5),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.18),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Directional / Aim Guide Markings
            if (!isAim) ...[
              // Left / Right / Fly indicators
              Positioned(
                left: 6,
                child: Icon(Icons.arrow_left, color: Colors.white.withValues(alpha: 0.4), size: 22),
              ),
              Positioned(
                right: 6,
                child: Icon(Icons.arrow_right, color: Colors.white.withValues(alpha: 0.4), size: 22),
              ),
              Positioned(
                top: 6,
                child: Icon(Icons.keyboard_arrow_up, color: const Color(0xFF38BDF8).withValues(alpha: 0.6), size: 22),
              ),
            ] else ...[
              // Aim Crosshair Rings
              Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1.5),
                ),
              ),
              Icon(
                Icons.adjust_rounded,
                color: primaryColor.withValues(alpha: 0.3),
                size: 28,
              ),
            ],

            // Draggable Knob
            Transform.translate(
              offset: _dragOffset,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor,
                      secondaryColor,
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isAim ? Icons.my_location_rounded : Icons.drag_indicator,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
