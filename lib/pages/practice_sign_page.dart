import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class _PracticeSignPageState extends State<PracticeSignPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: Change these to use sqlite data
    var lessonsAvailable = 20;
    var lessonsCompleted = 13;
    var quizzesAvailable = 15;
    var quizzesCompleted = 5;
    var totalPointsGained = 450;
    var bestScore = "85%";

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
                      text: "$lessonsAvailable Lessons Available", 
                      backgroundColor: Color.fromRGBO(239, 239, 253, 1), 
                      textColor: Colors.blue[900]!
                    ),
                    StatusBadge(
                      text: "$lessonsCompleted Completed", 
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
                      text: "$quizzesAvailable Quizzes Available", 
                      backgroundColor: Color.fromRGBO(243, 238, 254, 1), 
                      textColor: Colors.deepPurple[900]!
                    ),
                    StatusBadge(
                      text: "Best Score: $bestScore", 
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
                      value: lessonsCompleted.toString(),
                      valueColor: Color.fromRGBO(99, 102, 241, 1.0),
                      titleColor: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                    StatItemData(
                      title: "Quizzes",
                      value: quizzesCompleted.toString(),
                      valueColor: Color.fromRGBO(99, 102, 241, 1.0),
                      titleColor: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                    StatItemData(
                      title: "Points",
                      value: totalPointsGained.toString(),
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