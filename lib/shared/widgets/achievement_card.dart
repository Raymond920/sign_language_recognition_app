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
    // 1. Define colors based on the state
    final Color backgroundColor = isEarned ? const Color(0xFFFFFBEB) : const Color(0xFFF9FAFB);
    final Color borderColor = isEarned ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6);
    final Color textColor = isEarned ? const Color(0xFF92400E) : Colors.grey.shade600;
    final Color titleColor = isEarned ? const Color(0xFF92400E) : Colors.grey.shade700;

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
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, size: 14, color: Color(0xDDB45309)),
                  SizedBox(width: 4),
                  Text(
                    "Earned",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309)
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