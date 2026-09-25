import 'dart:async';
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
import '../ui/kill_feed_overlay.dart';
import '../ui/orientation_overlay.dart';
import '../ui/scoreboard_dialog.dart';
import 'lobby_screen.dart';
import 'room_waiting_screen.dart';

/// Active gameplay screen embedding Flame GameWidget, HUD, and responsive controls.
class GameScreen extends StatefulWidget {
  final int characterId;
  final String playerName;
  final int botCount;
  final bool isOnlineMultiplayer;
  final String roomId;
  final String serverUrl;
  final int gameDurationSeconds;
  final MultiplayerClient? customMultiplayerClient;

  const GameScreen({
    super.key,
    required this.characterId,
    required this.playerName,
    this.botCount = 4,
    this.isOnlineMultiplayer = false,
    this.roomId = 'ARENA-1',
    this.serverUrl = 'wss://team-b-6hro.onrender.com',
    this.gameDurationSeconds = 180,
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
  final ValueNotifier<({double fuel, bool isSuperFuel})> _fuelNotifier =
      ValueNotifier((fuel: 100.0, isSuperFuel: false));
  final ValueNotifier<({int kills, int deaths})> _scoreNotifier =
      ValueNotifier((kills: 0, deaths: 0));
  final ValueNotifier<int> _fartBombNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<KillFeedEntry>> _killFeedNotifier =
      ValueNotifier<List<KillFeedEntry>>([]);
  final ValueNotifier<String?> _lastKillerNameNotifier =
      ValueNotifier<String?>(null);
  late final ValueNotifier<int> _matchTimerNotifier;
  late int _remainingMatchSeconds;
  Timer? _matchTimer;
  bool _matchFinished = false;
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
    _remainingMatchSeconds = widget.gameDurationSeconds;
    _matchTimerNotifier = ValueNotifier<int>(_remainingMatchSeconds);
    _startMatchTimer();

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

    _game.onFuelChanged = (fuel, maxFuel, isSuperFuel) {
      if (_fuelNotifier.value.fuel != fuel ||
          _fuelNotifier.value.isSuperFuel != isSuperFuel) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fuelNotifier.value = (fuel: fuel, isSuperFuel: isSuperFuel);
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

    _game.onFartBombCountChanged = (count) {
      if (_fartBombNotifier.value != count) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fartBombNotifier.value = count;
          }
        });
      }
    };

    _game.onKillFeedEvent = ({
      required String killerName,
      required String victimName,
      required String weapon,
      required bool isLocalKiller,
      required bool isLocalVictim,
    }) {
      if (isLocalVictim) {
        _lastKillerNameNotifier.value = killerName;
      }
      final entry = KillFeedEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        killerName: killerName,
        victimName: victimName,
        weapon: weapon,
        isLocalKiller: isLocalKiller,
        isLocalVictim: isLocalVictim,
      );

      final current = List<KillFeedEntry>.from(_killFeedNotifier.value);
      current.add(entry);
      if (current.length > 5) {
        current.removeAt(0);
      }
      _killFeedNotifier.value = current;

      Timer(const Duration(milliseconds: 4000), () {
        if (!mounted) return;
        final updated = List<KillFeedEntry>.from(_killFeedNotifier.value);
        updated.removeWhere((e) => e.id == entry.id);
        _killFeedNotifier.value = updated;
      });
    };

    _inputController.onFartBombPressed = _triggerFartBomb;

    final client = _multiplayerClient;
    if (widget.customMultiplayerClient == null) {
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
  }

  void _triggerFartBomb() {
    _game.triggerLocalFartBomb();
  }

  void _startMatchTimer() {
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_game.paused) return;

      if (_remainingMatchSeconds <= 1) {
        timer.cancel();
        _remainingMatchSeconds = 0;
        _matchTimerNotifier.value = 0;
        _handleMatchFinished();
      } else {
        _remainingMatchSeconds--;
        _matchTimerNotifier.value = _remainingMatchSeconds;
      }
    });
  }

  List<MatchPlayerScore> _buildMatchScoreboard() {
    final localId = _multiplayerClient.localPlayerId;
    final localKills = _scoreNotifier.value.kills;
    final localDeaths = _scoreNotifier.value.deaths;

    final Map<String, MatchPlayerScore> scoreMap = {};

    // 1. Populate all players tracked by multiplayer client
    for (final p in _multiplayerClient.currentPlayers) {
      final isLocal = (p.playerId == localId);
      scoreMap[p.playerId] = MatchPlayerScore(
        playerId: p.playerId,
        name: isLocal ? widget.playerName : p.name,
        characterId: isLocal ? widget.characterId : p.characterId,
        kills: isLocal ? localKills : p.kills,
        deaths: isLocal ? localDeaths : p.deaths,
        isLocal: isLocal,
      );
    }

    // 2. Ensure local player is recorded even if not yet in currentPlayers
    if (!scoreMap.containsKey(localId)) {
      scoreMap[localId] = MatchPlayerScore(
        playerId: localId,
        name: widget.playerName,
        characterId: widget.characterId,
        kills: localKills,
        deaths: localDeaths,
        isLocal: true,
      );
    }

    return scoreMap.values.toList();
  }

  void _showLiveScoreboard() {
    final wasPaused = _game.paused;
    _game.paused = true;

    final scores = _buildMatchScoreboard();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ScoreboardDialog(
          scores: scores,
          isMatchOver: false,
          matchDurationSeconds: widget.gameDurationSeconds,
          onResume: () {
            Navigator.of(context).pop();
            if (!wasPaused) {
              _game.paused = false;
              _focusNode.requestFocus();
            }
          },
        );
      },
    ).then((_) {
      if (!wasPaused && !_matchFinished) {
        _game.paused = false;
        _focusNode.requestFocus();
      }
    });
  }

  void _handleMatchFinished() {
    if (_matchFinished) return;
    _matchFinished = true;
    _game.paused = true;
    _inputController.reset();

    final scores = _buildMatchScoreboard();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ScoreboardDialog(
          scores: scores,
          isMatchOver: true,
          matchDurationSeconds: widget.gameDurationSeconds,
          onMainMenu: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LobbyScreen()),
            );
          },
          onPlayAgain: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RoomWaitingScreen(
                  characterId: widget.characterId,
                  playerName: widget.playerName,
                  botCount: widget.botCount,
                  isOnlineMultiplayer: widget.isOnlineMultiplayer,
                  roomId: widget.roomId,
                  serverUrl: widget.serverUrl,
                  gameDurationSeconds: widget.gameDurationSeconds,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    _matchTimerNotifier.dispose();
    _multiplayerClient.disconnect();
    _inputController.dispose();
    _focusNode.dispose();
    _healthNotifier.dispose();
    _fuelNotifier.dispose();
    _scoreNotifier.dispose();
    _fartBombNotifier.dispose();
    _killFeedNotifier.dispose();
    _lastKillerNameNotifier.dispose();
    super.dispose();
  }

  // ==========================================
  // DESKTOP KEYBOARD CONTROLS (A, D, W, Space)
  // ==========================================
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.keyF ||
          event.logicalKey == LogicalKeyboardKey.keyB) {
        _triggerFartBomb();
      }
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
                    '• Mobile: Left Joystick (Move/Fly), Right Drag (Aim), JUMP, FIRE & FART BOMB\n• Desktop: A/D (Move), W/Space (Jump), F/B (Fart Bomb), Mouse (Aim), Left Click (Fire)',
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
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showLiveScoreboard();
                  },
                  icon: const Icon(Icons.leaderboard_rounded, size: 16),
                  label: const Text('SCOREBOARD'),
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

                      // 2. Mobile Touch Controls (Joystick, Aim, Jump, Fire, Fart Bomb)
                      Positioned.fill(
                        child: MobileControlsOverlay(
                          inputController: _inputController,
                          fartBombCountListenable: _fartBombNotifier,
                          onFartBombPressed: _triggerFartBomb,
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
                            return ValueListenableBuilder<({double fuel, bool isSuperFuel})>(
                              valueListenable: _fuelNotifier,
                              builder: (context, fuelState, _) {
                                return ValueListenableBuilder<({int kills, int deaths})>(
                                  valueListenable: _scoreNotifier,
                                  builder: (context, score, _) {
                                    return ValueListenableBuilder<int>(
                                      valueListenable: _matchTimerNotifier,
                                      builder: (context, remainingSec, _) {
                                        return ValueListenableBuilder<int>(
                                          valueListenable: _fartBombNotifier,
                                          builder: (context, fartBombCount, _) {
                                            return GameHud(
                                              currentHealth: health,
                                              maxHealth: 100.0,
                                              currentFuel: fuelState.fuel,
                                              maxFuel: 100.0,
                                              isSuperFuel: fuelState.isSuperFuel,
                                              kills: score.kills,
                                              deaths: score.deaths,
                                              characterId: widget.characterId,
                                              playerName: widget.playerName,
                                              totalPlayers: widget.botCount + 1,
                                              remainingSeconds: remainingSec,
                                              fartBombCount: fartBombCount,
                                              onPausePressed: _showPauseDialog,
                                              onScoreboardPressed: _showLiveScoreboard,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // 4. Kill Feed Announcements ("Who killed who")
                      Positioned(
                        top: 66,
                        right: 16,
                        child: KillFeedOverlay(
                          killFeedListenable: _killFeedNotifier,
                        ),
                      ),

                      // 5. Dead / Respawning Banner
                      Positioned.fill(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _healthNotifier,
                          builder: (context, health, _) {
                            if (health > 0.0) return const SizedBox.shrink();
                            return ValueListenableBuilder<String?>(
                              valueListenable: _lastKillerNameNotifier,
                              builder: (context, killerName, _) {
                                return Container(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 54,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'KIA - RESPAWNING...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        if (killerName != null && killerName.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Text(
                                              'ELIMINATED BY $killerName',
                                              style: const TextStyle(
                                                color: Color(0xFFFCA5A5),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        const Text(
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
