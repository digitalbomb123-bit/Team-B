import 'dart:math';
import 'package:flutter/material.dart';
import '../characters/character_registry.dart';

/// Represents a single combatant's score entry for the match scoreboard.
class MatchPlayerScore {
  final String playerId;
  final String name;
  final int characterId;
  final int kills;
  final int deaths;
  final bool isLocal;

  const MatchPlayerScore({
    required this.playerId,
    required this.name,
    required this.characterId,
    required this.kills,
    required this.deaths,
    this.isLocal = false,
  });

  double get kdRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
}

/// Esports-style Leaderboard & Scoreboard dialog showing each player's kills and deaths.
class ScoreboardDialog extends StatelessWidget {
  final List<MatchPlayerScore> scores;
  final bool isMatchOver;
  final int? matchDurationSeconds;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onMainMenu;
  final VoidCallback? onResume;

  const ScoreboardDialog({
    super.key,
    required this.scores,
    this.isMatchOver = true,
    this.matchDurationSeconds,
    this.onPlayAgain,
    this.onMainMenu,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompactHeight = screenSize.height < 450;

    // Sort players: highest kills first; tie-break: lowest deaths
    final sortedScores = List<MatchPlayerScore>.from(scores)
      ..sort((a, b) {
        final killDiff = b.kills.compareTo(a.kills);
        if (killDiff != 0) return killDiff;
        return a.deaths.compareTo(b.deaths);
      });

    final mvp = sortedScores.isNotEmpty && sortedScores.first.kills > 0
        ? sortedScores.first
        : null;

    final localEntry = sortedScores.cast<MatchPlayerScore?>().firstWhere(
          (p) => p?.isLocal == true,
          orElse: () => null,
        );

    final localRank = localEntry != null ? sortedScores.indexOf(localEntry) + 1 : null;

    final dialogWidth = min(screenSize.width * 0.92, 580.0);
    final dialogMaxHeight = min(screenSize.height * 0.90, 480.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: dialogMaxHeight),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMatchOver ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isMatchOver ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8))
                  .withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // HEADER BANNER
            // ==========================================
            _buildHeader(isCompactHeight, mvp),

            // ==========================================
            // SCOREBOARD TABLE HEADER
            // ==========================================
            _buildTableHeader(isCompactHeight),

            // ==========================================
            // SCOREBOARD ROSTER LIST (UP TO 10 PLAYERS)
            // ==========================================
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactHeight ? 8 : 12,
                  vertical: 4,
                ),
                itemCount: sortedScores.length,
                itemBuilder: (context, index) {
                  final entry = sortedScores[index];
                  final rank = index + 1;
                  return _buildPlayerRow(entry, rank, isCompactHeight);
                },
              ),
            ),

            // ==========================================
            // FOOTER: LOCAL PLAYER QUICK SUMMARY & ACTIONS
            // ==========================================
            _buildFooter(context, localEntry, localRank, isCompactHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompactHeight, MatchPlayerScore? mvp) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactHeight ? 12 : 16,
        vertical: isCompactHeight ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMatchOver ? Icons.emoji_events_rounded : Icons.leaderboard_rounded,
                  color: isMatchOver ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                  size: isCompactHeight ? 18 : 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isMatchOver ? 'MATCH SCOREBOARD' : 'LIVE ARENA SCOREBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompactHeight ? 14 : 16,
                    letterSpacing: 1.2,
                  ),
                ),
                if (matchDurationSeconds != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${matchDurationSeconds! ~/ 60}m',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (mvp != null) ...[
            SizedBox(height: isCompactHeight ? 2 : 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👑 ', style: TextStyle(fontSize: 12)),
                  Text(
                    'MATCH MVP: ${mvp.name} (${mvp.kills} KILLS)',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isCompactHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactHeight ? 10 : 14,
        vertical: isCompactHeight ? 4 : 6,
      ),
      color: const Color(0xFF0F172A),
      child: const Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              'RANK',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'COMBATANT',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              'KILLS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              'DEATHS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              'K/D',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(MatchPlayerScore entry, int rank, bool isCompactHeight) {
    final charDef = CharacterRegistry.getById(entry.characterId);
    final isLocal = entry.isLocal;

    // Rank styling
    Color rankColor;
    Widget rankWidget;
    if (rank == 1) {
      rankColor = const Color(0xFFF59E0B);
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 14));
    } else if (rank == 2) {
      rankColor = const Color(0xFFCBD5E1);
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 14));
    } else if (rank == 3) {
      rankColor = const Color(0xFFB45309);
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 14));
    } else {
      rankColor = const Color(0xFF64748B);
      rankWidget = Text(
        '#$rank',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final avatarSize = isCompactHeight ? 24.0 : 28.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(
        horizontal: isCompactHeight ? 8 : 10,
        vertical: isCompactHeight ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isLocal
            ? const Color(0xFF0284C7).withValues(alpha: 0.22)
            : (rank % 2 == 0
                ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                : const Color(0xFF1E293B).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocal
              ? const Color(0xFF38BDF8)
              : (rank == 1 ? rankColor.withValues(alpha: 0.5) : Colors.white10),
          width: isLocal ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank column
          SizedBox(
            width: 32,
            child: Center(child: rankWidget),
          ),
          const SizedBox(width: 8),

          // Face Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A),
              border: Border.all(
                color: isLocal ? const Color(0xFF38BDF8) : Colors.white24,
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                charDef.faceAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Name & YOU badge
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLocal ? Colors.white : const Color(0xFFE2E8F0),
                      fontSize: isCompactHeight ? 11 : 12,
                      fontWeight: isLocal ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
                if (isLocal) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Kills Column
          SizedBox(
            width: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Color(0xFFEF4444), size: 12),
                const SizedBox(width: 3),
                Text(
                  '${entry.kills}',
                  style: TextStyle(
                    color: entry.kills > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
                    fontSize: isCompactHeight ? 12 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // Deaths Column
          SizedBox(
            width: 48,
            child: Text(
              '${entry.deaths}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: isCompactHeight ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // K/D Column
          SizedBox(
            width: 44,
            child: Text(
              entry.deaths == 0
                  ? '${entry.kills}.0'
                  : entry.kdRatio.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: entry.kdRatio >= 1.0 ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                fontSize: isCompactHeight ? 11 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    MatchPlayerScore? localEntry,
    int? localRank,
    bool isCompactHeight,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactHeight ? 10 : 14,
        vertical: isCompactHeight ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (localEntry != null && localRank != null) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'YOUR RESULT: Rank #$localRank • ${localEntry.kills} Kills • ${localEntry.deaths} Deaths • ${localEntry.deaths == 0 ? "${localEntry.kills}.0" : localEntry.kdRatio.toStringAsFixed(1)} K/D',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isCompactHeight ? 6 : 8),
          ],

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onMainMenu != null)
                TextButton(
                  onPressed: onMainMenu,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactHeight ? 10 : 14,
                      vertical: isCompactHeight ? 6 : 8,
                    ),
                  ),
                  child: const Text(
                    'MAIN MENU',
                    style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 8),
              if (isMatchOver && onPlayAgain != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactHeight ? 12 : 16,
                      vertical: isCompactHeight ? 6 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (!isMatchOver && onResume != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactHeight ? 12 : 16,
                      vertical: isCompactHeight ? 6 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onResume,
                  child: const Text('RESUME'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
