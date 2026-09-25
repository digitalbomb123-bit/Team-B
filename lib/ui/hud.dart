import 'package:flutter/material.dart';
import '../../characters/character_definition.dart';
import '../../characters/character_registry.dart';
import 'health_bar.dart';

/// Top HUD layer displaying health, score, kills, and pause menu.
class GameHud extends StatelessWidget {
  final double currentHealth;
  final double maxHealth;
  final double currentFuel;
  final double maxFuel;
  final int kills;
  final int deaths;
  final int characterId;
  final String playerName;
  final int totalPlayers;
  final int remainingSeconds;
  final int fartBombCount;
  final bool isSuperFuel;
  final String weaponName;
  final double weaponZoom;
  final int currentAmmo;
  final int maxAmmo;
  final bool isReloading;
  final double reloadProgress;
  final VoidCallback onPausePressed;
  final VoidCallback? onZoomPressed;
  final VoidCallback? onScoreboardPressed;
  final VoidCallback? onReloadPressed;

  const GameHud({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
    this.currentFuel = 100.0,
    this.maxFuel = 100.0,
    required this.kills,
    required this.deaths,
    required this.characterId,
    required this.playerName,
    this.totalPlayers = 10,
    this.remainingSeconds = 180,
    this.fartBombCount = 0,
    this.isSuperFuel = false,
    this.weaponName = 'Uzi',
    this.weaponZoom = 2.0,
    this.currentAmmo = 25,
    this.maxAmmo = 25,
    this.isReloading = false,
    this.reloadProgress = 1.0,
    required this.onPausePressed,
    this.onZoomPressed,
    this.onScoreboardPressed,
    this.onReloadPressed,
  });

  @override
  Widget build(BuildContext context) {
    final character = CharacterRegistry.getById(characterId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. TOP-LEFT: Health, Avatar, Player Info
            _buildPlayerCard(character),

            // 2. TOP-RIGHT: Kill Count, Match Timer, Scope Zoom & Tactical Pause
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScoreBadge(),
                const SizedBox(width: 6),
                _buildZoomButton(),
                const SizedBox(width: 6),
                _buildPauseButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(CharacterDefinition character) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Face Avatar Thumbnail
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                character.faceAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Name & Health Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              HudHealthBar(
                currentHealth: currentHealth,
                maxHealth: maxHealth,
                width: 130,
                height: 12,
              ),
              const SizedBox(height: 3),
              _buildFuelBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuelBar() {
    final ratio = (currentFuel / maxFuel).clamp(0.0, 1.0);
    final iconColor = isSuperFuel ? const Color(0xFF38BDF8) : const Color(0xFFF97316);
    final barColors = isSuperFuel
        ? const [Color(0xFF38BDF8), Color(0xFF00F0FF)]
        : const [Color(0xFFFF7A00), Color(0xFFFFB800)];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSuperFuel ? Icons.bolt_rounded : Icons.rocket_launch_rounded,
          color: iconColor,
          size: 10,
        ),
        const SizedBox(width: 4),
        Container(
          width: 116,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: iconColor.withValues(alpha: 0.5), width: 1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: barColors),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBadge() {
    return InkWell(
      onTap: onScoreboardPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kills
            const Icon(Icons.gps_fixed_rounded, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 4),
            Text(
              '$kills',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(width: 10),
            Container(width: 1, height: 16, color: Colors.white24),
            const SizedBox(width: 10),

            // Match Countdown Timer
            ..._buildMatchTimer(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMatchTimer() {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final Color timerColor;
    if (remainingSeconds <= 10) {
      timerColor = const Color(0xFFEF4444); // Urgent red
    } else if (remainingSeconds <= 30) {
      timerColor = const Color(0xFFF59E0B); // Warning amber
    } else {
      timerColor = const Color(0xFF38BDF8); // Normal cyan
    }

    return [
      Icon(
        remainingSeconds <= 10
            ? Icons.timer_outlined
            : Icons.timer_outlined,
        color: timerColor,
        size: 15,
      ),
      const SizedBox(width: 4),
      Text(
        timeStr,
        style: TextStyle(
          color: timerColor,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ];
  }

  Widget _buildPauseButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPausePressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.pause_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton() {
    final zoomText = weaponZoom % 1 == 0
        ? '${weaponZoom.toInt()}x'
        : '${weaponZoom.toStringAsFixed(1)}x';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onZoomPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.zoom_out_map_rounded,
                color: Color(0xFF38BDF8),
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                zoomText,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
