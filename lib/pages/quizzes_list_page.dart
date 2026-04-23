import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/quiz_model.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/shared/widgets/quiz_card.dart';
import 'package:sign_language_recognition_app/shared/widgets/user_stats_card.dart';

class QuizzesListPage extends StatefulWidget {
  const QuizzesListPage({
    super.key,
  });

  @override
  State<QuizzesListPage> createState() => _QuizzesListPageState();
}

class _QuizzesListPageState extends State<QuizzesListPage> with WidgetsBindingObserver {
  late Future<List<Quiz>> _quizzesFuture;
  final DBHelper dbHelper = DBHelper();
  late AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _refreshQuizzes();
    
    // Listen for when the page comes back into focus
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        // Refresh quizzes when app is resumed
        if (mounted) {
          print('📲 App resumed - refreshing quiz list...');
          _refreshQuizzes();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _refreshQuizzes() {
    print('🔄 Refreshing quiz list...');
    setState(() {
      _quizzesFuture = dbHelper.getAllQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Quizzes"),
      ),
      body: FutureBuilder<List<Quiz>>(
        future: _quizzesFuture,
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
                  Text('Error loading quizzes: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('🔄 Retrying database query...');
                      _refreshQuizzes();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // No data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('⚠️  No data state: No quiz found in database');
            return const Center(
              child: Text('No quiz available'),
            );
          }

          final quizzes = snapshot.data!;
          // Here checking for 
          final passedQuizzes = quizzes.where((q) => q.bestScore >= 60).toList();
          final int quizzesPassed = passedQuizzes.length;
          final attemptedQuizzes = quizzes.where((q) => q.bestScore > 0).toList();
          final int quizzesAttempted = attemptedQuizzes.length;
          final double avgScore = quizzesAttempted == 0
            ? 0
            : attemptedQuizzes.map((q) => q.bestScore).reduce((a, b) => a + b) /
              quizzesAttempted;
          final Color statTitleColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color.fromRGBO(0, 0, 0, 0.5);
          print('✅ Success state: Rendering ${quizzes.length} quizzes');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: quizzes.length + 1,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 15);
              },
              itemBuilder: (context, index) {
                if (index == quizzes.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: UserStatsCard(
                      header: "Your Quiz Stats",
                      stats: [
                        StatItemData(
                          title: "Passed",
                          value: quizzesPassed.toString(),
                          valueColor: Color.fromRGBO(99, 102, 241, 1.0),
                          titleColor: statTitleColor,
                        ),
                        StatItemData(
                          title: "Avg Score",
                          value: "${avgScore.toStringAsFixed(1)}%",
                          valueColor: Color.fromRGBO(6, 182, 212, 1.0),
                          titleColor: statTitleColor,
                        ),
                        StatItemData(
                          title: "Remaining",
                          value: (quizzes.length - quizzesPassed).toString(),
                          valueColor: Color.fromRGBO(99, 102, 241, 1.0),
                          titleColor: statTitleColor,
                        ),
                      ],
                    ),
                  );
                }

                final quiz = quizzes[index];

                return QuizCard(
                  quiz: quiz,
                  onTap: () {},
                  onNavigateBack: _refreshQuizzes,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

