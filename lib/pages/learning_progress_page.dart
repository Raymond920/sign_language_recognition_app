import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/shared/widgets/achievement_card.dart';
import 'package:sign_language_recognition_app/shared/widgets/activity_item.dart';
import 'package:sign_language_recognition_app/shared/widgets/stat_detail_card.dart';
import '../shared/widgets/dashboard_block.dart';

class LearningProgressPage extends StatelessWidget {
  const LearningProgressPage({
    super.key,
    required this.lessonsCompleted,
    required this.quizzesCompleted,
    required this.totalLessons,
    required this.totalQuizzes,
  });

  final int lessonsCompleted;
  final int quizzesCompleted;
  final int totalLessons;
  final int totalQuizzes;

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          "Course Completion",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${((lessonsCompleted + quizzesCompleted) / (totalLessons + totalQuizzes) * 100).toStringAsFixed(2)}%",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (lessonsCompleted + quizzesCompleted) / (totalLessons + totalQuizzes),
                        minHeight: 14.0,
                        backgroundColor: Color.fromRGBO(99, 102, 241, 0.2),
                        color: Color.fromRGBO(99, 102, 241, 1.0),
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
                                lessonsCompleted.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.fromRGBO(99, 102, 241, 1.0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 26,
                                ),
                              ),
                              Text(
                                "Lessons Done",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.fromRGBO(0, 0, 0, 0.5),
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
                                quizzesCompleted.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.fromRGBO(99, 102, 241, 1.0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 26,
                                ),
                              ),
                              Text(
                                "Quizzes Passed",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.fromRGBO(0, 0, 0, 0.5),
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
                              /// TODO: Remember to change the point earned 
                              /// after created point calculation method for 
                              /// total quizzes
                              Text(
                                '450',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.fromRGBO(6, 182, 212, 1.0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 26,
                                ),
                              ),
                              Text(
                                "Points Earned",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.fromRGBO(0, 0, 0, 0.5),
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
                      childAspectRatio: 0.84, // Adjust based on your text length
                      children: const [

                        // TODO: Change the achievements details to follow sqlite
                        AchievementCard(
                          emoji: "🎯",
                          title: "First Steps",
                          description: "Completed first lesson",
                          isEarned: true,
                        ),
                        AchievementCard(
                          emoji: "🔡",
                          title: "Alphabet Master",
                          description: "Mastered all alphabet signs",
                          isEarned: true,
                        ),
                        AchievementCard(
                          emoji: "🔢",
                          title: "Number Ninja",
                          description: "Perfect score in numbers quiz",
                          isEarned: true,
                        ),
                        AchievementCard(
                          emoji: "⚡",
                          title: "Quick Learner",
                          description: "Complete 5 lessons in one day",
                          isEarned: false,
                        ),
                        AchievementCard(
                          emoji: "💯",
                          title: "Perfect Score",
                          description: "Get 100% in any quiz",
                          isEarned: false,
                        ),
                        AchievementCard(
                          emoji: "🔥",
                          title: "Streak Master",
                          description: "7 day learning streak",
                          isEarned: false,
                        ),
                        // ... more cards
                      ],
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

                      // TODO: Change the value to follow sqlite
                      children: [
                        const StatDetailCard(
                          icon: Icons.track_changes_rounded,
                          iconColor: Colors.indigoAccent,
                          value: "42",
                          label: "Signs Learned",
                        ),
                        const StatDetailCard(
                          icon: Icons.star_outline_rounded,
                          iconColor: Colors.cyan,
                          value: "88%",
                          label: "Avg Quiz Score",
                        ),
                        const StatDetailCard(
                          icon: Icons.access_time_rounded,
                          iconColor: Colors.deepPurpleAccent,
                          value: "12h",
                          label: "Study Time",
                        ),
                        const StatDetailCard(
                          icon: Icons.emoji_events_outlined,
                          iconColor: Colors.orange,
                          value: "5",
                          label: "Day Streak",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Recent Activities block
              DashboardBlock(
                title: "Recent Activities",
                child: Column(
                  children: const [
                    // TODO: Need add time checking for the time passed for recent activities
                    ActivityItem(
                      title: "Completed 'Numbers 1-5' lesson",
                      subtitle: "2 hours ago",
                    ),
                    ActivityItem(
                      title: "Took 'Alphabet A-Z Test' quiz",
                      subtitle: "1 day ago",
                      score: "92%",
                      scoreColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}