import 'package:flutter/material.dart';

/// Represents a single death/kill event in the match.
class KillFeedEntry {
  final String id;
  final String killerName;
  final String victimName;
  final String weapon; // 'bullet', 'fart_bomb'
  final bool isLocalKiller;
  final bool isLocalVictim;
  final DateTime timestamp;

  KillFeedEntry({
    required this.id,
    required this.killerName,
    required this.victimName,
    this.weapon = 'bullet',
    this.isLocalKiller = false,
    this.isLocalVictim = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get actionText {
    if (weapon == 'fart_bomb') {
      return 'fart-bombed';
    }
    return 'eliminated';
  }

  String get weaponIcon {
    if (weapon == 'fart_bomb') {
      return '💨';
    }
    return '🎯';
  }
}

/// Overlay widget showing recent kill announcements ("who killed who").
/// Automatically fades out notifications after a brief display duration.
class KillFeedOverlay extends StatelessWidget {
  final ValueNotifier<List<KillFeedEntry>> killFeedListenable;

  const KillFeedOverlay({
    super.key,
    required this.killFeedListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<KillFeedEntry>>(
      valueListenable: killFeedListenable,
      builder: (context, entries, _) {
        if (entries.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: entries.map((entry) => _buildKillItem(entry)).toList(),
        );
      },
    );
  }

  Widget _buildKillItem(KillFeedEntry entry) {
    final killerColor = entry.isLocalKiller
        ? const Color(0xFF38BDF8) // Bright Cyan for YOU
        : const Color(0xFFFBBF24); // Amber Gold for others

    final victimColor = entry.isLocalVictim
        ? const Color(0xFFEF4444) // Urgent Red for YOU
        : const Color(0xFFCBD5E1); // Light Slate for others

    final borderColor = entry.isLocalKiller
        ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
        : (entry.isLocalVictim
            ? const Color(0xFFEF4444).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.15));

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Killer
            Text(
              entry.isLocalKiller ? 'YOU' : entry.killerName,
              style: TextStyle(
                color: killerColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 5),

            // Weapon Icon & Action
            Text(
              entry.weaponIcon,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              entry.actionText,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),

            // Victim
            Text(
              entry.isLocalVictim ? 'YOU' : entry.victimName,
              style: TextStyle(
                color: victimColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
