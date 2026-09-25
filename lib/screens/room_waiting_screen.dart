import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../characters/character_definition.dart';
import '../characters/character_registry.dart';
import '../multiplayer/mock_multiplayer_client.dart';
import '../multiplayer/multiplayer_client.dart';
import '../multiplayer/player_state.dart';
import '../multiplayer/websocket_multiplayer_client.dart';
import '../ui/orientation_overlay.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';

/// Pre-match 15-second room waiting lobby where players gather before the match starts.
class RoomWaitingScreen extends StatefulWidget {
  final int characterId;
  final String playerName;
  final int botCount;
  final bool isOnlineMultiplayer;
  final String roomId;
  final String serverUrl;
  final int gameDurationSeconds;
  final MultiplayerClient? customMultiplayerClient;

  const RoomWaitingScreen({
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
  State<RoomWaitingScreen> createState() => _RoomWaitingScreenState();
}

class _RoomWaitingScreenState extends State<RoomWaitingScreen>
    with SingleTickerProviderStateMixin {
  late final MultiplayerClient _multiplayerClient;
  StreamSubscription<List<PlayerState>>? _playersSub;

  static const int _totalWaitingSeconds = 15;
  int _countdownSeconds = _totalWaitingSeconds;
  Timer? _countdownTimer;

  List<PlayerState> _roster = [];
  bool _isTransitioning = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Initialize multiplayer client
    if (widget.customMultiplayerClient != null) {
      _multiplayerClient = widget.customMultiplayerClient!;
    } else if (widget.isOnlineMultiplayer) {
      _multiplayerClient = WebSocketMultiplayerClient(
        serverUrl: widget.serverUrl,
      );
    } else {
      _multiplayerClient = MockMultiplayerClient();
    }

    _connectAndListen();
    _startCountdown();
  }

  void _connectAndListen() {
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

    _playersSub = _multiplayerClient.playersStream.listen((players) {
      if (mounted) {
        setState(() {
          _roster = players;
        });
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _startMatch();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  void _startMatch() {
    if (_isTransitioning) return;
    _isTransitioning = true;
    _countdownTimer?.cancel();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          characterId: widget.characterId,
          playerName: widget.playerName,
          botCount: widget.botCount,
          isOnlineMultiplayer: widget.isOnlineMultiplayer,
          roomId: widget.roomId,
          serverUrl: widget.serverUrl,
          gameDurationSeconds: widget.gameDurationSeconds,
          customMultiplayerClient: _multiplayerClient,
        ),
      ),
    );
  }

  void _leaveRoom() {
    _countdownTimer?.cancel();
    _multiplayerClient.disconnect();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LobbyScreen()),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _playersSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final localDef = CharacterRegistry.getById(widget.characterId);
    final size = MediaQuery.of(context).size;
    final isCompactHeight = size.height < 520;
    final progress = _countdownSeconds / _totalWaitingSeconds;

    return OrientationOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompactHeight ? 12 : 20,
              vertical: isCompactHeight ? 8 : 12,
            ),
            child: Column(
              children: [
                // 1. TOP HEADER: Room Code, Mode, Game Duration, and Leave button
                _buildHeader(isCompactHeight),

                SizedBox(height: isCompactHeight ? 6 : 12),

                // 2. MAIN BODY: Countdown Indicator & Player Roster Grid
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT: 15-Second Animated Countdown Dial & Start Now Button
                      SizedBox(
                        width: isCompactHeight ? 200 : 250,
                        child: _buildCountdownPanel(
                          progress: progress,
                          isCompactHeight: isCompactHeight,
                        ),
                      ),

                      SizedBox(width: isCompactHeight ? 10 : 16),

                      // RIGHT: Live Roster of Joined Players (Up to 10 slots)
                      Expanded(
                        child: _buildRosterPanel(
                          localDef: localDef,
                          isCompactHeight: isCompactHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Back button + Room Code Badge
          Expanded(
            flex: 5,
            child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back button
                InkWell(
                  onTap: _leaveRoom,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded,
                            color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'LEAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Room Code Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF38BDF8), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.meeting_room_rounded,
                          color: Color(0xFF38BDF8), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'ROOM: ${widget.roomId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.roomId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Room code "${widget.roomId}" copied!'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF0284C7),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy_rounded,
                            color: Color(0xFF38BDF8), size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ),

          const SizedBox(width: 8),

          // Right Side: Match Duration + Mode Badge
          Expanded(
            flex: 5,
            child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Match Duration Badge (From Setter)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'MATCH TIME: ${_formatDuration(widget.gameDurationSeconds)}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Mode Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isOnlineMultiplayer
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : const Color(0xFF64748B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.isOnlineMultiplayer
                          ? const Color(0xFF10B981)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isOnlineMultiplayer
                            ? Icons.wifi_rounded
                            : Icons.smart_toy_rounded,
                        color: widget.isOnlineMultiplayer
                            ? const Color(0xFF10B981)
                            : const Color(0xFFCBD5E1),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isOnlineMultiplayer ? 'ONLINE' : 'SOLO BOTS',
                        style: TextStyle(
                          color: widget.isOnlineMultiplayer
                              ? const Color(0xFF10B981)
                              : const Color(0xFFCBD5E1),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownPanel({
    required double progress,
    required bool isCompactHeight,
  }) {
    final dialSize = isCompactHeight ? 110.0 : 140.0;

    return Container(
      padding: EdgeInsets.all(isCompactHeight ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'MATCH STARTS IN',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          SizedBox(height: isCompactHeight ? 8 : 12),

          // Glowing Circular Countdown Ring
          SizedBox(
            width: dialSize,
            height: dialSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                SizedBox(
                  width: dialSize,
                  height: dialSize,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: isCompactHeight ? 6 : 8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Active Glowing Progress Track
                SizedBox(
                  width: dialSize,
                  height: dialSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: isCompactHeight ? 6 : 8,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _countdownSeconds <= 5
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF38BDF8),
                    ),
                  ),
                ),

                // Central Countdown Digits
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = _countdownSeconds <= 5
                            ? 1.0 + (_pulseController.value * 0.12)
                            : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: Text(
                            '$_countdownSeconds',
                            style: TextStyle(
                              color: _countdownSeconds <= 5
                                  ? const Color(0xFFEF4444)
                                  : Colors.white,
                              fontSize: isCompactHeight ? 36 : 46,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: (_countdownSeconds <= 5
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF38BDF8))
                                      .withValues(alpha: 0.6),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      'SECONDS',
                      style: TextStyle(
                        color: _countdownSeconds <= 5
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF38BDF8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: isCompactHeight ? 6 : 10),

          // Subtitle
          const Text(
            'Waiting for players to join...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9.5,
            ),
          ),

          SizedBox(height: isCompactHeight ? 8 : 12),

          // START NOW Button (Allows bypassing wait)
          SizedBox(
            width: double.infinity,
            height: isCompactHeight ? 34 : 38,
            child: ElevatedButton(
              onPressed: _startMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
                padding: EdgeInsets.zero,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'START NOW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterPanel({
    required CharacterDefinition localDef,
    required bool isCompactHeight,
  }) {
    // Total players in room (Local + others in roster)
    final otherPlayers = _roster
        .where((p) => p.playerId != _multiplayerClient.localPlayerId)
        .toList();
    final totalCount = otherPlayers.length + 1;

    return Container(
      padding: EdgeInsets.all(isCompactHeight ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Roster Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded,
                      color: Color(0xFF38BDF8), size: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'ROOM ROSTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalCount / 10 Joined',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isCompactHeight ? 6 : 8),

          // 10 Slot Grid
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isCompactHeight ? 5 : 5,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: isCompactHeight ? 1.4 : 1.25,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Slot 1: You (Local Player)
                  return _buildPlayerSlotCard(
                    name: widget.playerName,
                    faceAsset: localDef.faceAsset,
                    isLocalPlayer: true,
                    isOccupied: true,
                    slotNumber: 1,
                    isCompact: isCompactHeight,
                  );
                }

                final otherIndex = index - 1;
                if (otherIndex < otherPlayers.length) {
                  final p = otherPlayers[otherIndex];
                  final charDef = CharacterRegistry.getById(p.characterId);
                  return _buildPlayerSlotCard(
                    name: p.name,
                    faceAsset: charDef.faceAsset,
                    isLocalPlayer: false,
                    isOccupied: true,
                    slotNumber: index + 1,
                    isCompact: isCompactHeight,
                  );
                }

                // Empty Slot
                return _buildEmptySlotCard(index + 1, isCompact: isCompactHeight);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlotCard({
    required String name,
    required String faceAsset,
    required bool isLocalPlayer,
    required bool isOccupied,
    required int slotNumber,
    bool isCompact = false,
  }) {
    if (isCompact) {
      return Container(
        decoration: BoxDecoration(
          color: isLocalPlayer
              ? const Color(0xFF0284C7).withValues(alpha: 0.2)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLocalPlayer
                ? const Color(0xFF38BDF8)
                : const Color(0xFF10B981).withValues(alpha: 0.6),
            width: isLocalPlayer ? 1.8 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A),
                  border: Border.all(
                    color: isLocalPlayer
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF10B981),
                    width: 1.0,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    faceAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isLocalPlayer ? 'YOU • READY' : 'READY',
                style: TextStyle(
                  color: isLocalPlayer
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF10B981),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isLocalPlayer
            ? const Color(0xFF0284C7).withValues(alpha: 0.2)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocalPlayer
              ? const Color(0xFF38BDF8)
              : const Color(0xFF10B981).withValues(alpha: 0.6),
          width: isLocalPlayer ? 1.8 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Avatar Face
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A),
              border: Border.all(
                color: isLocalPlayer
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFF10B981),
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                faceAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLocalPlayer
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLocalPlayer ? 'YOU • READY' : 'READY',
                        style: TextStyle(
                          color: isLocalPlayer
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF10B981),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotCard(int slotNumber, {bool isCompact = false}) {
    if (isCompact) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: Center(
                child: Text(
                  '#$slotNumber',
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Waiting...',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: Center(
              child: Text(
                '#$slotNumber',
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Waiting...',
              style: TextStyle(
                color: Colors.white30,
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
