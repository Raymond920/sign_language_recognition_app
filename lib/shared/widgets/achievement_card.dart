import 'package:flutter/material.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key, 
    required this.emoji, 
    required this.title, 
    required this.description,
    this.isEarned = false
  });

  final String emoji;
  final String title;
  final String description;
  final bool isEarned;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Define colors based on the state
    final Color backgroundColor = isEarned
      ? (isDark ? const Color(0x33A16207) : const Color(0xFFFFFBEB))
      : (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9FAFB));
    final Color borderColor = isEarned
      ? (isDark ? const Color(0xFFA16207) : const Color(0xFFFEF3C7))
      : (isDark ? colorScheme.outlineVariant : const Color(0xFFF3F4F6));
    final Color textColor = isEarned
      ? (isDark ? const Color(0xFFFACC15) : const Color(0xFF92400E))
      : (isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600);
    final Color titleColor = isEarned
      ? (isDark ? const Color(0xFFFACC15) : const Color(0xFF92400E))
      : (isDark ? colorScheme.onSurface : Colors.grey.shade700);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                emoji, 
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Description
          Expanded(
            child: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),

          // Earned badge (Shown when isEarned is true)
          if (isEarned) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x335A3D00) : const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFFA16207) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 14,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xDDB45309),
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Earned",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309),
                    ),
                  )
                ],
              ),
            )
          ] else ...[
            const SizedBox(height: 8)
          ]
        ],
      ),
    );
  }
}