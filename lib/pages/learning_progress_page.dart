import 'package:flutter/material.dart';
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
      body: Center(
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
            )
          ],
        ),
      ),
    );
  }
}