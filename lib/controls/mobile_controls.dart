import 'package:flutter/material.dart';
import 'input_controller.dart';
import 'virtual_joystick.dart';

/// Full mobile dual-joystick overlay providing:
/// - Left Joystick: Horizontal movement + Upward drag for Jetpack flight
/// - Right Joystick: 360° Aiming & continuous Fire on drag
/// - Action Buttons: Dedicated Jetpack / Jump Boost button
class MobileControlsOverlay extends StatefulWidget {
  final InputController inputController;

  const MobileControlsOverlay({
    super.key,
    required this.inputController,
  });

  @override
  State<MobileControlsOverlay> createState() => _MobileControlsOverlayState();
}

class _MobileControlsOverlayState extends State<MobileControlsOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Bottom-Left: Left Joystick for Movement & Jetpack Thrust
        Positioned(
          left: 28,
          bottom: 24,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VirtualJoystick(
                  radius: 64.0,
                  mode: VirtualJoystickMode.movement,
                  onVectorChanged: (vector) {
                    widget.inputController.usingTouchControls = true;
                    widget.inputController.setMoveX(vector.dx);
                    // Dragging joystick upward activates jetpack flight
                    final isUpwardThrust = vector.dy < -0.3;
                    widget.inputController.setFlying(isUpwardThrust);
                    widget.inputController.setJumping(isUpwardThrust);
                  },
                  onReleased: () {
                    widget.inputController.setMoveX(0.0);
                    widget.inputController.setFlying(false);
                    widget.inputController.setJumping(false);
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'MOVE / FLY',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Bottom-Right: Right Joystick for 360° Aim & Fire
        Positioned(
          right: 28,
          bottom: 24,
          child: SafeArea(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Dedicated JETPACK / JUMP Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 18),
                  child: _ActionButton(
                    size: 64,
                    color: const Color(0xFF10B981),
                    icon: Icons.rocket_launch_rounded,
                    label: 'JETPACK',
                    onPressedDown: () {
                      widget.inputController.usingTouchControls = true;
                      widget.inputController.setFlying(true);
                      widget.inputController.setJumping(true);
                    },
                    onPressedUp: () {
                      widget.inputController.setFlying(false);
                      widget.inputController.setJumping(false);
                    },
                  ),
                ),

                // Right Joystick (Aim & Fire)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VirtualJoystick(
                      radius: 64.0,
                      mode: VirtualJoystickMode.aimAndFire,
                      onAimChanged: (angle, isFiring) {
                        widget.inputController.usingTouchControls = true;
                        widget.inputController.setAimAngle(angle);
                        widget.inputController.setShooting(isFiring);
                      },
                      onReleased: () {
                        widget.inputController.setShooting(false);
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'AIM & FIRE',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Action Button widget for touch controls with tactile feedback.
class _ActionButton extends StatefulWidget {
  final double size;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressedDown;
  final VoidCallback onPressedUp;

  const _ActionButton({
    required this.size,
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressedDown,
    required this.onPressedUp,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onPressedDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressedUp();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onPressedUp();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _isPressed ? 0.9 : 0.65),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: _isPressed ? 16 : 8,
                spreadRadius: _isPressed ? 3 : 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.40,
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
