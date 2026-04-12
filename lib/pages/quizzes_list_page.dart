import 'package:flutter/material.dart';

class QuizzesListPage extends StatefulWidget {
  const QuizzesListPage({
    super.key,
  });

  @override
  State<QuizzesListPage> createState() => _QuizzesListPageState();
}

class _QuizzesListPageState extends State<QuizzesListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Quizzes"),
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
            // print('❌ Error state: ${snapshot.error}');
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
                      // print('🔄 Retrying database query...');
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
            // print('⚠️  No data state: No lessons found in database');
            return const Center(
              child: Text('No lessons available'),
            );
          }

          final lessons = snapshot.data!;
          // print('✅ Success state: Rendering ${lessons.length} lessons');

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