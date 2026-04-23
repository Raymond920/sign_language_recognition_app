import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/shared/widgets/status_badge.dart';


class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key, 
    required this.lesson,
    this.onNavigateBack,
  });

  final Lesson lesson;
  final VoidCallback? onNavigateBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    IconData statusIcon;
    Color statusColor;
    Color? backgroundColor;
    Color? textColor;

    String status;

    if (lesson.progress == 0){
      status = "Not Started";
      statusIcon = Icons.radio_button_unchecked;
      statusColor = isDark ? colorScheme.onSurfaceVariant : Colors.grey;
      backgroundColor = isDark ? colorScheme.surfaceContainerHighest : Colors.grey[100];
      textColor = isDark ? colorScheme.onSurface : Colors.black;
    } else if (lesson.progress < 1) {
      status = "In Progress";
      statusIcon = Icons.radio_button_checked;
      statusColor = Colors.indigo;
      backgroundColor = isDark ? const Color(0x332563EB) : Colors.indigo[100];
      textColor = isDark ? const Color(0xFF93C5FD) : Colors.indigo[800];
    } else {
      status = "Completed";
      statusIcon = Icons.check_circle_rounded;
      statusColor = Colors.green;
      backgroundColor = isDark ? const Color(0x3315803D) : Colors.green[100];
      textColor = isDark ? const Color(0xFF86EFAC) : Colors.green[800];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            // Assuming route defined as /lessons/:id
            // print('\n🎓 LESSON CARD TAPPED:');
            // print('   Lesson ID: ${lesson.id}');
            // print('   Title: ${lesson.title}');
            // print('   Signs Count: ${lesson.signCount}');
            // print('   Current Progress: ${(lesson.progress * 100).toStringAsFixed(1)}%');
            // print('   Navigation: lesson_content route...\n');
            
            // Navigate to lesson content page
            await context.pushNamed(
              'lesson_content', 
              extra: lesson,
            );
            
            // After returning, refresh the lessons list
            if (onNavigateBack != null) {
              // print('\n🔄 Returning from lesson - Refreshing lessons list...\n');
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Progress Icon
                Icon(statusIcon, color: statusColor, size: 24),
          
                const SizedBox(width: 15),
          
                // 2. Middle content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? colorScheme.onSurface : Colors.black,
                                  ),
                                  softWrap: true,
                                ),
                                Text(
                                  lesson.description,
                                  style: TextStyle(
                                    color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.play_arrow_outlined,
                            color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                            size: 24,
                          ),
                        ],
                      ),
          
                      const SizedBox(height: 12),

                      // Progress bar
                      if (status != "Not Started") ...[
                        // Sign count and Percentage row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${lesson.signCount} signs",
                              style: TextStyle(
                                color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                              ),
                            ),
                            Text(
                              "${(lesson.progress * 100).toInt()}%",
                              style: TextStyle(
                                color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                              ),
                            ),
                          ],
                        ),
            
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: lesson.progress,
                          backgroundColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[200],
                          color: Colors.indigoAccent,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
          
                      SizedBox(height: 12),
                      StatusBadge(
                        text: status,
                        backgroundColor: backgroundColor!,
                        textColor: textColor!,
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
}
