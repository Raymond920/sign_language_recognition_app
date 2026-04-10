import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/shared/widgets/status_badge.dart';


class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.lesson});

  final LessonMock lesson;

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    Color? backgroundColor;
    Color? textColor;

    String status;

    if (lesson.progress == 0){
      status = "Not Started";
      statusIcon = Icons.radio_button_unchecked;
      statusColor = Colors.grey;
      backgroundColor = Colors.grey[100];
      textColor = Colors.black;
    } else if (lesson.progress < 1) {
      status = "In Progress";
      statusIcon = Icons.radio_button_checked;
      statusColor = Colors.indigo;
      backgroundColor = Colors.indigo[100];
      textColor = Colors.indigo[800];
    } else {
      status = "Completed";
      statusIcon = Icons.check_circle_rounded;
      statusColor = Colors.green;
      backgroundColor = Colors.green[100];
      textColor = Colors.green[800];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Assuming route defined as /lessons/:id
            context.pushNamed(
              'lesson_content', 
              extra: lesson
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFFE0E0E0), width: 1),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  softWrap: true,
                                ),
                                Text(
                                  lesson.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.play_arrow_outlined,
                            color: Colors.grey,
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
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "${(lesson.progress * 100).toInt()}%",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
            
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: lesson.progress,
                          backgroundColor: Colors.grey[200],
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
