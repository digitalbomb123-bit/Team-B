import 'package:flutter/material.dart';
import 'input_controller.dart';
import 'virtual_joystick.dart';

/// Full mobile dual-joystick overlay providing:
/// - Left Joystick: Horizontal movement + Upward drag for Jetpack flight
/// - Right Joystick: 360° Aiming & continuous Fire on drag
/// - Action Buttons: Dedicated Jetpack / Jump Boost button
class MobileControlsOverlay extends StatefulWidget {
  final InputController inputController;
  final ValueNotifier<int>? fartBombCountListenable;
  final VoidCallback? onFartBombPressed;
  final int selectedCharacterId;
  final ValueNotifier<double>? poopCooldownListenable;
  final VoidCallback? onPoopPressed;

  const MobileControlsOverlay({
    super.key,
    required this.inputController,
    this.fartBombCountListenable,
    this.onFartBombPressed,
    this.selectedCharacterId = 1,
    this.poopCooldownListenable,
    this.onPoopPressed,
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
                Text(
                  'MOVE / FLY',
                  style: TextStyle(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
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
                // Special Power Button: Exclusive POOP power for Jos (#5), or FART BOMB for others
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 18),
                  child: widget.selectedCharacterId == 5
                      ? ValueListenableBuilder<double>(
                          valueListenable: widget.poopCooldownListenable ?? ValueNotifier<double>(0.0),
                          builder: (context, cooldown, _) {
                            return _PoopPowerButton(
                              size: 64,
                              cooldown: cooldown,
                              onPressed: cooldown <= 0
                                  ? () {
                                      widget.inputController.usingTouchControls = true;
                                      if (widget.onPoopPressed != null) {
                                        widget.onPoopPressed!();
                                      } else {
                                        widget.inputController.triggerPoop();
                                      }
                                    }
                                  : null,
                            );
                          },
                        )
                      : ValueListenableBuilder<int>(
                          valueListenable: widget.fartBombCountListenable ?? ValueNotifier<int>(0),
                          builder: (context, bombCount, _) {
                            return _FartBombButton(
                              size: 64,
                              bombCount: bombCount,
                              onPressed: bombCount > 0
                                  ? () {
                                      widget.inputController.usingTouchControls = true;
                                      if (widget.onFartBombPressed != null) {
                                        widget.onFartBombPressed!();
                                      } else {
                                        widget.inputController.triggerFartBomb();
                                      }
                                    }
                                  : null,
                            );
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
                    Text(
                      'AIM & FIRE',
                      style: TextStyle(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.55),
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
            color: widget.color.withValues(alpha: _isPressed ? 0.6 : 0.35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2),
                blurRadius: _isPressed ? 10 : 4,
                spreadRadius: _isPressed ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white.withValues(alpha: 0.85),
                size: widget.size * 0.40,
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
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

/// Action button for the Fart Bomb.
/// Disabled (dimmed slate) when 0 bombs; enabled (vibrant pulsating toxic green) when player collects a bomb.
class _FartBombButton extends StatefulWidget {
  final double size;
  final int bombCount;
  final VoidCallback? onPressed;

  const _FartBombButton({
    required this.size,
    required this.bombCount,
    required this.onPressed,
  });

  @override
  State<_FartBombButton> createState() => _FartBombButtonState();
}

class _FartBombButtonState extends State<_FartBombButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.bombCount > 0 && widget.onPressed != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _FartBombButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasEnabled = oldWidget.bombCount > 0 && oldWidget.onPressed != null;
    final isEnabled = widget.bombCount > 0 && widget.onPressed != null;
    if (isEnabled && !wasEnabled) {
      _pulseController.repeat(reverse: true);
    } else if (!isEnabled && wasEnabled) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.bombCount > 0 && widget.onPressed != null;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = isEnabled ? _pulseController.value : 0.0;

        return GestureDetector(
          onTapDown: isEnabled
              ? (_) {
                  setState(() => _isPressed = true);
                }
              : null,
          onTapUp: isEnabled
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed?.call();
                }
              : null,
          onTapCancel: isEnabled
              ? () {
                  setState(() => _isPressed = false);
                }
              : null,
          child: AnimatedScale(
            scale: _isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 70),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFBEF264).withValues(alpha: 0.65),
                          const Color(0xFF65A30D).withValues(alpha: 0.65),
                        ],
                      )
                    : null,
                color: isEnabled ? null : const Color(0xFF1E293B).withValues(alpha: 0.35),
                border: Border.all(
                  color: isEnabled
                      ? Color.lerp(const Color(0xFFBEF264).withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.8), pulseValue)!
                      : Colors.white24,
                  width: isEnabled ? 2.0 : 1.2,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF84CC16).withValues(alpha: 0.25 + pulseValue * 0.2),
                          blurRadius: 10 + pulseValue * 4,
                          spreadRadius: 1 + pulseValue * 1,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/fart_bomb.png',
                        width: widget.size * 0.46,
                        height: widget.size * 0.46,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          '💨',
                          style: TextStyle(
                            fontSize: widget.size * 0.34,
                            shadows: isEnabled
                                ? [
                                    const Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'FART BOMB',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isEnabled ? Colors.white : Colors.white38,
                          fontSize: 8.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          shadows: isEnabled
                              ? [
                                  const Shadow(
                                    color: Colors.black87,
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),

                  // Pill counter badge
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isEnabled ? const Color(0xFFBEF264) : Colors.white24,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        isEnabled ? 'x${widget.bombCount}' : '0',
                        style: TextStyle(
                          color: isEnabled ? const Color(0xFFBEF264) : Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tactical Poop Power Button exclusive to Jos (#5)
class _PoopPowerButton extends StatefulWidget {
  final double size;
  final double cooldown;
  final VoidCallback? onPressed;

  const _PoopPowerButton({
    required this.size,
    required this.cooldown,
    required this.onPressed,
  });

  @override
  State<_PoopPowerButton> createState() => _PoopPowerButtonState();
}

class _PoopPowerButtonState extends State<_PoopPowerButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.cooldown <= 0 && widget.onPressed != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PoopPowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasReady = oldWidget.cooldown <= 0 && oldWidget.onPressed != null;
    final isReady = widget.cooldown <= 0 && widget.onPressed != null;
    if (isReady && !wasReady) {
      _pulseController.repeat(reverse: true);
    } else if (!isReady && wasReady) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = widget.cooldown <= 0 && widget.onPressed != null;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = isReady ? _pulseController.value : 0.0;

        return GestureDetector(
          onTapDown: isReady ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isReady
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed?.call();
                }
              : null,
          onTapCancel: isReady ? () => setState(() => _isPressed = false) : null,
          child: AnimatedScale(
            scale: _isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 70),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isReady
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFB45309).withValues(alpha: 0.75),
                          const Color(0xFF78350F).withValues(alpha: 0.75),
                        ],
                      )
                    : null,
                color: isReady ? null : const Color(0xFF1E293B).withValues(alpha: 0.45),
                border: Border.all(
                  color: isReady
                      ? Color.lerp(
                          const Color(0xFFF59E0B).withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.9),
                          pulseValue,
                        )!
                      : Colors.white24,
                  width: isReady ? 2.2 : 1.2,
                ),
                boxShadow: isReady
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35 + pulseValue * 0.25),
                          blurRadius: 10 + pulseValue * 5,
                          spreadRadius: 1 + pulseValue * 1.5,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '💩',
                        style: TextStyle(
                          fontSize: widget.size * 0.40,
                          shadows: isReady
                              ? const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'POOP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isReady ? const Color(0xFFFDE68A) : Colors.white38,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          shadows: isReady
                              ? const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),

                  // Cooldown or READY Badge
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isReady ? const Color(0xFF451A03) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isReady ? const Color(0xFFF59E0B) : Colors.white24,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        isReady ? 'READY' : '${widget.cooldown.toStringAsFixed(1)}s',
                        style: TextStyle(
                          color: isReady ? const Color(0xFFFDE68A) : Colors.white60,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
