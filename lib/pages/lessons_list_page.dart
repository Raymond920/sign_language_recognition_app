import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/shared/widgets/lesson_card.dart';

class LessonsListPage extends StatefulWidget {
  const LessonsListPage({super.key});

  @override
  State<LessonsListPage> createState() => _LessonsListPageState();
}

class _LessonsListPageState extends State<LessonsListPage> {
  List<LessonMock> dummyLessons = [
    LessonMock(
      title: "Alphabet Group 1: A, B, C",
      description: "Learn the first 3 letters of MSL alphabet",
      signCount: 3,
      progress: 1.0,
    ),
    LessonMock(
      title: "Alphabet Group 2: D, E, F",
      description: "Continue with letters D through F",
      signCount: 3,
      progress: 1.0,
    ),
    LessonMock(
      title: "Numbers 0-5",
      description: "Basic number signs from 0 to 5",
      signCount: 6,
      progress: 0.6,
    ),
    LessonMock(
      title: "Numbers 6-10",
      description: "Basic number signs from 1 to 5",
      signCount: 5,
      progress: 0.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Lessons"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: dummyLessons.length + 1,
            separatorBuilder: (context, index) {
              if (index == dummyLessons.length - 1) return const SizedBox(height: 0);
              return const SizedBox(height: 15);
            },
            itemBuilder: (context, index) {
              if (index == dummyLessons.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Showing ${dummyLessons.length} lessons",
                    style: const TextStyle(
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return LessonCard(lesson: dummyLessons[index]);
            },
          ),
        ),
      ),
    );
  }
}
