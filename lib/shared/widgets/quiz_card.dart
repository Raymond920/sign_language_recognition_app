import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/models/quiz_model.dart';
import 'package:sign_language_recognition_app/shared/widgets/status_badge.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({
    required this.quiz,
    required this.onTap,
    this.onNavigateBack,
  });

  final Quiz quiz;
  final VoidCallback onTap;
  final VoidCallback? onNavigateBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Determine badge colors based on score
    late Color badgeBackgroundColor;
    late Color badgeTextColor;
    
    if (quiz.bestScore == 0) {
      // Not started - grey
      badgeBackgroundColor = isDark ? colorScheme.surfaceContainerHighest : Colors.grey[100]!;
      badgeTextColor = isDark ? colorScheme.onSurfaceVariant : Colors.grey[800]!;
    } else if (quiz.bestScore == 100) {
      // Perfect score - green
      badgeBackgroundColor = isDark ? const Color(0x3315803D) : Colors.green[100]!;
      badgeTextColor = isDark ? const Color(0xFF86EFAC) : Colors.green[800]!;
    } else if (quiz.bestScore >= 60) {
      // Passed but not perfect - blue
      badgeBackgroundColor = isDark ? const Color(0x332563EB) : Colors.blue[100]!;
      badgeTextColor = isDark ? const Color(0xFF93C5FD) : Colors.blue[800]!;
    } else {
      // Failed - red
      badgeBackgroundColor = isDark ? const Color(0x33B91C1C) : Colors.red[100]!;
      badgeTextColor = isDark ? const Color(0xFFFCA5A5) : Colors.red[800]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            // Navigate to quiz content page and wait for return
            await context.pushNamed(
              'quiz_content', 
              extra: quiz,
            );
            
            // After returning, refresh the quizzes list
            if (onNavigateBack != null) {
              onNavigateBack!();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              border: Border.all(
                color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Description part
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          softWrap: true,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? colorScheme.onSurface : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          quiz.description,
                          softWrap: true,
                          style: TextStyle(
                            color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    ),

                    // Best score part
                    // TODO: conditional show after user complete that question
                    if (quiz.bestScore != 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star_border, color: Colors.amber, size: 20),
                              Text(
                                "${quiz.bestScore.toString()}%",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? colorScheme.onSurface : Colors.black,
                                ),
                              )
                            ],
                          ),
                          Text(
                            "Best Score",
                            // textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[500]
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // No.of questions, complete status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${quiz.questionCount} questions",
                      style: TextStyle(
                        color: isDark ? colorScheme.onSurfaceVariant : Colors.black,
                      ),
                    ),
                    StatusBadge(
                      // TODO: add function to update quiz status value on db side
                      text: quiz.status,
                      backgroundColor: badgeBackgroundColor,
                      textColor: badgeTextColor,
                    ),
                  ],
                ),
              ],
            )
          ),
        ),
      ),
    );
  }
}