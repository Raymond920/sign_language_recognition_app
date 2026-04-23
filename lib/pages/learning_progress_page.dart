import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/achievement_model.dart';
import 'package:sign_language_recognition_app/services/achivement_service.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/services/study_tracker_service.dart';
import 'package:sign_language_recognition_app/shared/widgets/achievement_card.dart';
import 'package:sign_language_recognition_app/shared/widgets/stat_detail_card.dart';
import '../shared/widgets/dashboard_block.dart';

class LearningProgressPage extends StatefulWidget {
  const LearningProgressPage({
    super.key,
    this.lessonsCompleted = 0,
    this.quizzesCompleted = 0,
    this.totalLessons = 0,
    this.totalQuizzes = 0,
  });

  final int lessonsCompleted;
  final int quizzesCompleted;
  final int totalLessons;
  final int totalQuizzes;

  @override
  State<LearningProgressPage> createState() => _LearningProgressPageState();
}

class _LearningProgressPageState extends State<LearningProgressPage> with WidgetsBindingObserver {
  late AppLifecycleListener _lifecycleListener;
  int _totalPoints = 0;
  int _lessonsCompleted = 0;
  int _quizzesCompleted = 0;
  int _totalLessons = 0;
  int _totalQuizzes = 0;
  double _avgQuizScore = 0;
  int _signsLearned = 0;
  int _dayStreak = 0;
  double _totalStudyTime = 0.0;
  Map<String, bool> _achievementStatus = {};
  final DBHelper _dbHelper = DBHelper();
  final AchievementService _achievementService = AchievementService();

  @override
  void initState() {
    super.initState();
    // Load initial points value
    _totalPoints = ProfileService.cachedTotalPoints;
    
    // Listen for points changes
    ProfileService.totalPointsNotifier.addListener(_onPointsChanged);
    
    // Load real values from database
    _loadProgressData();
    
    // Add lifecycle listener to refresh when page resumes
    _lifecycleListener = AppLifecycleListener(
      onResume: _onPageResume,
    );
  }

  Future<void> _loadProgressData() async {
    try {
      final allLessons = await _dbHelper.getAllLessons();
      final lessonsCompleted = allLessons.where((l) => l.isCompleted).length;
      
      final allQuizzes = await _dbHelper.getAllQuizzes();
      // Only count quizzes with score >= 60 as completed
      final quizzesCompleted = allQuizzes.where((q) => q.bestScore >= 60).length;
      
      final double avgQuizScore = quizzesCompleted == 0
      ? 0
      : allQuizzes
          .where((q) => q.bestScore >= 60)
          .map((q) => q.bestScore)
          .reduce((a, b) => a + b) / quizzesCompleted;
      
      final allSigns = await _dbHelper.getAllSigns();
      final signsLearned = allSigns.where((s) => s.isCompleted).length;
      
      // Load study tracking data
      final dayStreak = await StudyTrackerService.calculateDayStreak();
      final totalStudyHours = await StudyTrackerService.getTotalStudyTimeInHours();
      final achievementStatus = await _achievementService.getAchievementStatusMap();

      setState(() {
        _totalLessons = allLessons.length;
        _lessonsCompleted = lessonsCompleted;
        _totalQuizzes = allQuizzes.length;
        _quizzesCompleted = quizzesCompleted;
        _avgQuizScore = avgQuizScore;
        _signsLearned = signsLearned;
        _dayStreak = dayStreak;
        _totalStudyTime = totalStudyHours;
        _achievementStatus = achievementStatus;
      });
    } catch (e) {
      print('❌ Error loading progress data: $e');
    }
  }

  void _onPointsChanged() {
    setState(() {
      _totalPoints = ProfileService.cachedTotalPoints;
    });
  }

  Future<void> _onPageResume() async {
    setState(() {
      _totalPoints = ProfileService.cachedTotalPoints;
    });
    // Refresh progress data on page resume
    await _loadProgressData();
  }

  @override
  void dispose() {
    ProfileService.totalPointsNotifier.removeListener(_onPointsChanged);
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("My Progress"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
              const SizedBox(height: 20),
              DashboardBlock(
                title: 'Overall Progress', 
                icon: Icons.trending_up,
                iconColor: const Color.fromRGBO(6, 182, 212, 1.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          "Course Completion",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? colorScheme.onSurface : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${(_totalLessons + _totalQuizzes > 0 ? ((_lessonsCompleted + _quizzesCompleted) / (_totalLessons + _totalQuizzes) * 100) : 0).toStringAsFixed(2)}%",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? colorScheme.onSurface : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _totalLessons + _totalQuizzes > 0 ? (_lessonsCompleted + _quizzesCompleted) / (_totalLessons + _totalQuizzes) : 0,
                        minHeight: 14.0,
                        backgroundColor: isDark ? colorScheme.surfaceContainerHighest : const Color.fromRGBO(99, 102, 241, 0.2),
                        color: const Color.fromRGBO(99, 102, 241, 1.0),
                      ),
                    ),
                    SizedBox(height: 25.0),
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _lessonsCompleted.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color.fromRGBO(99, 102, 241, 1.0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 26,
                                ),
                              ),
                              Text(
                                "Lessons Done",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? colorScheme.onSurfaceVariant : const Color.fromRGBO(0, 0, 0, 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _quizzesCompleted.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color.fromRGBO(99, 102, 241, 1.0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 26,
                                ),
                              ),
                              Text(
                                "Quizzes Passed",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? colorScheme.onSurfaceVariant : const Color.fromRGBO(0, 0, 0, 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _totalPoints.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color.fromRGBO(6, 182, 212, 1.0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 26,
                                ),
                              ),
                              Text(
                                "Points Earned",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? colorScheme.onSurfaceVariant : const Color.fromRGBO(0, 0, 0, 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                )
              ),
              const SizedBox(height: 20),

              // Achievement block
              DashboardBlock(
                title: "Achievements",
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.orange,
                child: Column(
                  children: [
                    SizedBox(height: 16,),
                    GridView.count(
                      shrinkWrap: true, // Required because it's inside a Column (in DashboardBlock)
                      physics: const NeverScrollableScrollPhysics(), // Let the main page handle scrolling
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8, // Adjust based on your text length
                      children: AchievementService.allAchievements.map((achievement) {
                        return AchievementCard(
                          emoji: achievement.emoji,
                          title: achievement.title,
                          description: achievement.description,
                          isEarned: _achievementStatus[achievement.id] ?? false,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Statistic block
              DashboardBlock(
                title: "Statistics",
                child: Column(
                  children: [
                    SizedBox(height: 16,),
                    GridView.count(
                      shrinkWrap: true, // Required for use inside a Column/Scrollview
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,       // 2 items per row
                      crossAxisSpacing: 10,    // Space between columns
                      mainAxisSpacing: 10,     // Space between rows
                      childAspectRatio: 1,   // Makes the cards slightly wider/squarer

                      // TODO: Change to real value
                      children: [
                        StatDetailCard(
                          icon: Icons.track_changes_rounded,
                          iconColor: Colors.indigoAccent,
                          value: _signsLearned.toString(),
                          label: "Signs Learned",
                        ),
                        StatDetailCard(
                          icon: Icons.star_outline_rounded,
                          iconColor: Colors.cyan,
                          value: "${_avgQuizScore.toStringAsFixed(1)}%",
                          label: "Avg Quiz Score",
                        ),
                        StatDetailCard(
                          icon: Icons.access_time_rounded,
                          iconColor: Colors.deepPurpleAccent,
                          value: "${_totalStudyTime.toStringAsFixed(1)}h",
                          label: "Study Time",
                        ),
                        StatDetailCard(
                          icon: Icons.emoji_events_outlined,
                          iconColor: Colors.orange,
                          value: _dayStreak.toString(),
                          label: "Day Streak",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Recent Activities block
              // DashboardBlock(
              //   title: "Recent Activities",
              //   child: Column(
              //     children: const [
              //       ActivityItem(
              //         title: "Completed 'Numbers 1-5' lesson",
              //         subtitle: "2 hours ago",
              //       ),
              //       ActivityItem(
              //         title: "Took 'Alphabet A-Z Test' quiz",
              //         subtitle: "1 day ago",
              //         score: "92%",
              //         scoreColor: Colors.green,
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}