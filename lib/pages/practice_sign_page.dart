import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/shared/widgets/learning_module_card.dart';
import 'package:sign_language_recognition_app/shared/widgets/status_badge.dart';
import 'package:sign_language_recognition_app/shared/widgets/user_stats_card.dart';

class PracticeSignPage extends StatefulWidget {
  const PracticeSignPage({
    super.key,
  });

  @override
  State<PracticeSignPage> createState() => _PracticeSignPageState();
}

class _PracticeSignPageState extends State<PracticeSignPage> with WidgetsBindingObserver {
  late AppLifecycleListener _lifecycleListener;
  int _totalPoints = 0;
  int _lessonsAvailable = 0;
  int _lessonsCompleted = 0;
  int _quizzesAvailable = 0;
  int _quizzesCompleted = 0;
  double _bestScore = 0;
  final DBHelper _dbHelper = DBHelper();
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    // Load initial points value
    _totalPoints = ProfileService.cachedTotalPoints;
    
    // Load practice data from database
    _loadPracticeData();
    
    WidgetsBinding.instance.addObserver(this);
    ProfileService.totalPointsNotifier.addListener(_onPointsChanged);
    ProfileService.quizCompletionNotifier.addListener(_onQuizCompleted);
    _lifecycleListener = AppLifecycleListener(
      onResume: _onPageResume,
    );
  }

  Future<void> _loadPracticeData() async {
    try {
      final allLessons = await _dbHelper.getAllLessons();
      final lessonsCompleted = allLessons.where((l) => l.isCompleted).length;
      
      final allQuizzes = await _dbHelper.getAllQuizzes();
      // Use same filtering as quizzes_list_page for consistency (score >= 60)
      final completedQuizzes = allQuizzes.where((q) => q.bestScore >= 60).toList();
      final int quizzesCompleted = completedQuizzes.length;
      
      // Calculate best quiz score from completed quizzes
      final bestScore = completedQuizzes.isEmpty ? 0.0 : completedQuizzes.map((q) => q.bestScore).reduce((a, b) => a > b ? a : b).toDouble();
      
      setState(() {
        _lessonsAvailable = allLessons.length;
        _lessonsCompleted = lessonsCompleted;
        _quizzesAvailable = allQuizzes.length;
        _quizzesCompleted = quizzesCompleted;
        _bestScore = bestScore;
      });
    } catch (e) {
      print('❌ Error loading practice data: $e');
    }
  }

  void _onPointsChanged() {
    setState(() {
      _totalPoints = ProfileService.cachedTotalPoints;
    });
    _loadPracticeData();
  }

  void _onQuizCompleted() {
    _loadPracticeData();
  }

  Future<void> _onPageResume() async {
    setState(() {
      _totalPoints = ProfileService.cachedTotalPoints;
    });
    await _loadPracticeData();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lastLifecycleState == AppLifecycleState.paused && state == AppLifecycleState.resumed) {
      _loadPracticeData();
    }
    _lastLifecycleState = state;
  }

  @override
  void dispose() {
    ProfileService.totalPointsNotifier.removeListener(_onPointsChanged);
    ProfileService.quizCompletionNotifier.removeListener(_onQuizCompleted);
    _lifecycleListener.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Practice MSL"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget> [
                SizedBox(height: 20,),
                // heading message
                Column(
                  children: [
                    Text(
                      "Ready to Learn?",
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 10,),
                    Text(
                      "Choose your learning path to improve your MSL skills",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Color.fromRGBO(0, 0, 0, 0.4)
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20,),
                LearningModuleCard(
                  title: "Attend Lessons", 
                  description: "Structured learning with step-by-step guidance", 
                  icon: Icons.menu_book, 
                  iconBgColor: Color.fromRGBO(99, 102, 241, 1), 
                  badges: [
                    StatusBadge(
                      text: "$_lessonsAvailable Lessons Available", 
                      backgroundColor: Color.fromRGBO(239, 239, 253, 1), 
                      textColor: Colors.blue[900]!
                    ),
                    StatusBadge(
                      text: "$_lessonsCompleted Completed", 
                      backgroundColor: Color.fromRGBO(219, 252, 231, 1), 
                      textColor: Colors.green[900]!
                    ),
                  ],
                  onTap: () => {
                    context.push('/lessons')
                  }
                ),
                LearningModuleCard(
                  title: "Take Quizzes", 
                  description: "Test your knowledge and track your progress", 
                  icon: Icons.psychology, 
                  iconBgColor: Color.fromRGBO(139, 92, 246, 1), 
                  badges: [
                    StatusBadge(
                      text: "$_quizzesAvailable Quizzes Available", 
                      backgroundColor: Color.fromRGBO(243, 238, 254, 1), 
                      textColor: Colors.deepPurple[900]!
                    ),
                    StatusBadge(
                      text: "Best Score: ${_bestScore.toStringAsFixed(1)}%", 
                      backgroundColor: Color.fromRGBO(230, 247, 250, 1), 
                      textColor: Colors.cyan[900]!
                    ),
                  ],
                  onTap: () => {
                    context.push('/quizzes-list')
                  }
                ),
                UserStatsCard(
                  header: "Your Progress",
                  stats: [
                    StatItemData(
                      title: "Lessons",
                      value: _lessonsCompleted.toString(),
                      valueColor: Color.fromRGBO(99, 102, 241, 1.0),
                      titleColor: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                    StatItemData(
                      title: "Quizzes",
                      value: _quizzesCompleted.toString(),
                      valueColor: Color.fromRGBO(99, 102, 241, 1.0),
                      titleColor: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                    StatItemData(
                      title: "Points",
                      value: _totalPoints.toString(),
                      valueColor: Color.fromRGBO(6, 182, 212, 1.0),
                      titleColor: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}