import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/camera/game_camera.dart';
import '../controls/input_controller.dart';
import '../controls/mobile_controls.dart';
import '../game/mini_militia_game.dart';
import '../multiplayer/mock_multiplayer_client.dart';
import '../multiplayer/multiplayer_client.dart';
import '../multiplayer/websocket_multiplayer_client.dart';
import '../ui/hud.dart';
import '../ui/orientation_overlay.dart';
import 'lobby_screen.dart';

/// Active gameplay screen embedding Flame GameWidget, HUD, and responsive controls.
class GameScreen extends StatefulWidget {
  final int characterId;
  final String playerName;
  final int botCount;
  final bool isOnlineMultiplayer;
  final String roomId;
  final String serverUrl;
  final MultiplayerClient? customMultiplayerClient;

  const GameScreen({
    super.key,
    required this.characterId,
    required this.playerName,
    this.botCount = 4,
    this.isOnlineMultiplayer = false,
    this.roomId = 'ARENA-1',
    this.serverUrl = 'wss://team-b-6hro.onrender.com',
    this.customMultiplayerClient,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final InputController _inputController;
  late final MultiplayerClient _multiplayerClient;
  late final MiniMilitiaGame _game;

  // Local HUD Reactive State
  final ValueNotifier<double> _healthNotifier = ValueNotifier<double>(100.0);
  final ValueNotifier<double> _fuelNotifier = ValueNotifier<double>(100.0);
  final ValueNotifier<({int kills, int deaths})> _scoreNotifier =
      ValueNotifier((kills: 0, deaths: 0));
  double _currentZoom = GameCameraConfig.cameraZoom;

  // Desktop keyboard key state tracking
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final FocusNode _focusNode = FocusNode();

  @visibleForTesting
  InputController get inputController => _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = InputController();

    if (widget.customMultiplayerClient != null) {
      _multiplayerClient = widget.customMultiplayerClient!;
    } else if (widget.isOnlineMultiplayer) {
      _multiplayerClient = WebSocketMultiplayerClient(
        serverUrl: widget.serverUrl,
      );
    } else {
      _multiplayerClient = MockMultiplayerClient();
    }

    _game = MiniMilitiaGame(
      multiplayerClient: _multiplayerClient,
      inputController: _inputController,
      selectedCharacterId: widget.characterId,
      playerName: widget.playerName,
    );

    _game.onHealthChanged = (hp, maxHp) {
      if (_healthNotifier.value != hp) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _healthNotifier.value = hp;
          }
        });
      }
    };

    _game.onFuelChanged = (fuel, maxFuel) {
      if (_fuelNotifier.value != fuel) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fuelNotifier.value = fuel;
          }
        });
      }
    };

    _game.onScoreChanged = (k, d) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scoreNotifier.value = (kills: k, deaths: d);
        }
      });
    };

    final client = _multiplayerClient;
    if (client is MockMultiplayerClient) {
      client.connect(
        roomId: widget.roomId,
        playerName: widget.playerName,
        characterId: widget.characterId,
        botCount: widget.botCount,
      );
    } else {
      client.connect(
        roomId: widget.roomId,
        playerName: widget.playerName,
        characterId: widget.characterId,
      );
    }
  }

  @override
  void dispose() {
    _multiplayerClient.disconnect();
    _inputController.dispose();
    _focusNode.dispose();
    _healthNotifier.dispose();
    _fuelNotifier.dispose();
    _scoreNotifier.dispose();
    super.dispose();
  }

  // ==========================================
  // DESKTOP KEYBOARD CONTROLS (A, D, W, Space)
  // ==========================================
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }

    // Evaluate horizontal movement
    double moveX = 0.0;
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      moveX -= 1.0;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      moveX += 1.0;
    }
    _inputController.setMoveX(moveX);

    // Evaluate jumping and jetpack flight
    final jumpingOrFlying = _pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.space) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp);
    _inputController.setJumping(jumpingOrFlying);
    _inputController.setFlying(jumpingOrFlying);

    return KeyEventResult.handled;
  }

  // ==========================================
  // DESKTOP MOUSE AIM HOVER & FOCUS
  // ==========================================
  void _handlePointerHover(PointerHoverEvent event, Size screenSize) {
    if (_inputController.usingTouchControls) return;
    // Calculate aim relative to screen center for desktop mouse hover
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    final dx = event.position.dx - center.dx;
    final dy = event.position.dy - center.dy;
    final angle = atan2(dy, dx);
    _inputController.setAimAngle(angle);
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Focus keyboard input on tap/click without triggering fire
    _focusNode.requestFocus();
  }

  void _showPauseDialog() {
    _game.paused = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.pause_circle_filled, color: Color(0xFF38BDF8), size: 26),
                  SizedBox(width: 8),
                  Text(
                    'TACTICAL PAUSE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Camera Zoom Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Camera Zoom:', style: TextStyle(color: Colors.white70)),
                      Text(
                        '${_currentZoom.toStringAsFixed(2)}x',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _currentZoom,
                    min: 0.8,
                    max: 1.6,
                    divisions: 8,
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (val) {
                      setModalState(() => _currentZoom = val);
                      setState(() {
                        _currentZoom = val;
                        _game.setZoom(val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CONTROLS:',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Mobile: Left Joystick (Move), Right Drag (Aim), JUMP & FIRE buttons\n• Desktop: A/D (Move), W/Space (Jump), Mouse (Aim), Left Click (Fire)',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LobbyScreen()),
                    );
                  },
                  child: const Text('EXIT TO LOBBY', style: TextStyle(color: Color(0xFFEF4444))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _game.paused = false;
                    _focusNode.requestFocus();
                  },
                  child: const Text('RESUME'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              return MouseRegion(
                onHover: (e) => _handlePointerHover(e, size),
                child: Listener(
                  onPointerDown: _handlePointerDown,
                  child: Stack(
                    children: [
                      // 1. Core Flame Game
                      Positioned.fill(
                        child: GameWidget(game: _game),
                      ),

                      // 2. Mobile Touch Controls (Joystick, Aim, Jump, Fire)
                      Positioned.fill(
                        child: MobileControlsOverlay(
                          inputController: _inputController,
                        ),
                      ),

                      // 3. Top Tactical HUD
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ValueListenableBuilder<double>(
                          valueListenable: _healthNotifier,
                          builder: (context, health, _) {
                            return ValueListenableBuilder<double>(
                              valueListenable: _fuelNotifier,
                              builder: (context, fuel, _) {
                                return ValueListenableBuilder<({int kills, int deaths})>(
                                  valueListenable: _scoreNotifier,
                                  builder: (context, score, _) {
                                    return GameHud(
                                      currentHealth: health,
                                      maxHealth: 100.0,
                                      currentFuel: fuel,
                                      maxFuel: 100.0,
                                      kills: score.kills,
                                      deaths: score.deaths,
                                      characterId: widget.characterId,
                                      playerName: widget.playerName,
                                      totalPlayers: widget.botCount + 1,
                                      onPausePressed: _showPauseDialog,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // 4. Dead / Respawning Banner
                      Positioned.fill(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _healthNotifier,
                          builder: (context, health, _) {
                            if (health > 0.0) return const SizedBox.shrink();
                            return Container(
                              color: Colors.black.withValues(alpha: 0.65),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 54,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'KIA - RESPAWNING...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Returning to combat in 3 seconds',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
