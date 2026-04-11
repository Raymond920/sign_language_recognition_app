import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/shared/widgets/lesson_card.dart';

class LessonsListPage extends StatefulWidget {
  const LessonsListPage({super.key});

  @override
  State<LessonsListPage> createState() => _LessonsListPageState();
}

class _LessonsListPageState extends State<LessonsListPage> {
  late Future<List<Lesson>> _lessonsFuture;
  final DBHelper dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    // Fetch lessons from database
    _refreshLessons();
  }

  void _refreshLessons() {
    print('\n' + '='*70);
    print('📚 LESSONS LIST PAGE: Fetching lessons from database...');
    print('='*70);
    setState(() {
      _lessonsFuture = dbHelper.getAllLessons().then((lessons) {
        print('\n✅ Database Query Complete:');
        print('   Total lessons found: ${lessons.length}');
        if (lessons.isNotEmpty) {
          print('\n📋 Lesson Details:');
          for (int i = 0; i < lessons.length; i++) {
            final lesson = lessons[i];
            print('   [$i+1] ID: ${lesson.id}');
            print('       Title: ${lesson.title}');
            print('       Description: ${lesson.description}');
            print('       Signs Count: ${lesson.signCount}');
            print('       Progress: ${(lesson.progress * 100).toStringAsFixed(1)}%');
            print('       Status: ${lesson.status}');
            print('');
          }
        }
        print('='*70 + '\n');
        return lessons;
      }).catchError((error) {
        print('\n❌ Error fetching lessons: $error');
        print('='*70 + '\n');
        throw error;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Lessons"),
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ Loading state: Waiting for database query...');
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            print('❌ Error state: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading lessons: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('🔄 Retrying database query...');
                      setState(() {
                        _lessonsFuture = dbHelper.getAllLessons();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // No data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('⚠️  No data state: No lessons found in database');
            return const Center(
              child: Text('No lessons available'),
            );
          }

          final lessons = snapshot.data!;
          print('✅ Success state: Rendering ${lessons.length} lessons');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: lessons.length + 1,
              separatorBuilder: (context, index) {
                if (index == lessons.length - 1) return const SizedBox(height: 0);
                return const SizedBox(height: 15);
              },
              itemBuilder: (context, index) {
                if (index == lessons.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Showing ${lessons.length} lessons',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final lesson = lessons[index];

                return LessonCard(
                  lesson: lesson,
                  onNavigateBack: _refreshLessons,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
