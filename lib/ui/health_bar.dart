import 'package:flutter/material.dart';

/// Polished military HUD health bar with animated transitions and low HP alert.
class HudHealthBar extends StatelessWidget {
  final double currentHealth;
  final double maxHealth;
  final double width;
  final double height;

  const HudHealthBar({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
    this.width = 160.0,
    this.height = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (currentHealth / maxHealth).clamp(0.0, 1.0);

    Color barColor;
    if (ratio > 0.5) {
      barColor = const Color(0xFF10B981); // Green
    } else if (ratio > 0.25) {
      barColor = const Color(0xFFF59E0B); // Amber
    } else {
      barColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated Bar
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    barColor.withValues(alpha: 0.8),
                    barColor,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
