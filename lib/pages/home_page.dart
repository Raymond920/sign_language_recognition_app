import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/dashboard_block.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("MSL Translator"),

        actions: [
          IconButton(
            onPressed: () {
              context.push("/profile");
            }, 
            icon: const Icon(Icons.account_circle))
        ],
      ),
      drawer: Drawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 40),
            const WelcomeDialog(username: "Raymond"),
            const SizedBox(height: 40),
            LearningProgressButton(
              lessonsCompleted: 13, 
              quizzesCompleted: 5, 
              totalLessons: 30, 
              totalQuizzes: 10,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                NavigationButton(
                  title: "Recognize Signs", 
                  icon: Icons.camera_alt_outlined, 
                  color: Colors.deepPurple[400]!,
                  route: "/recognize-signs", 
                  description: "Real-time sign detection"),
                const NavigationButton(
                  title: "Practice MSL", 
                  icon: Icons.school, 
                  color: Colors.deepPurple,
                  route: "/practice-signs", 
                  description: "Lessons and quizzes"),
                const NavigationButton(
                  title: "MSL Library", 
                  icon: Icons.menu_book, 
                  color: Colors.cyan,
                  route: "/signs-library", 
                  description: "Browse sign database"),
                const NavigationButton(
                  title: "Settings", 
                  icon: Icons.settings, 
                  color: Colors.black54,
                  route: "/settings", 
                  description: "App preferences"),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Welcome back, $username!",
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold
          ),
        ),
        Text(
          "Continue your MSL learning journey.",
          style: const TextStyle(
            fontSize: 16, 
            color: Color.fromRGBO(0, 0, 0, 0.4)
          ),
        ),
      ],
    );
  }
}

class LearningProgressButton extends StatelessWidget {
  const LearningProgressButton({
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
  final String nextLesson = "Numbers 1 - 5";

  @override
  Widget build(BuildContext context) {
    return DashboardBlock(
      title: 'Learning Progress',
      icon: Icons.trending_up,
      iconColor: Color.fromRGBO(6, 182, 212, 1.0),
      onTap: () { 
        context.push('/learning-progress', 
        extra: {
          'lessonsCompleted': 13,
          'totalLessons': 30,
          'quizzesCompleted': 5,
          'totalQuizzes': 10,
        },
      ); 
      },
      child: Column(
        children: [
          SizedBox(height: 14.0),
          Row(
            children: [
              Text(
                "Overall Progress",
                style: TextStyle(
                  fontSize: 16
                ),
              ),
              const Spacer(),
              Text(
                "${((lessonsCompleted + quizzesCompleted) / (totalLessons + totalQuizzes) * 100).toStringAsFixed(2)}%",
                style: TextStyle(
                  fontSize: 16
                ),
              ),
            ],
          ),
          SizedBox(height: 20.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (lessonsCompleted + quizzesCompleted) / (totalLessons + totalQuizzes),
              minHeight: 12.0,
              backgroundColor: Color.fromRGBO(99, 102, 241, 0.2),
              color: Color.fromRGBO(99, 102, 241, 1.0),
            ),
          ),
          SizedBox(height: 15.0),
          Row(
            children: [
              Text(
                "$lessonsCompleted lessons completed",
                style: const TextStyle(
                  fontSize: 12, 
                  color: Color.fromRGBO(0, 0, 0, 0.4)
                ),
              ),
              Spacer(),
              Text(
                "Next: $nextLesson",
                style: const TextStyle(
                  fontSize: 12, 
                  color: Color.fromRGBO(0, 0, 0, 0.4)
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class NavigationButton extends StatelessWidget {
  const NavigationButton({
    super.key,
    required this.title,
    required this.icon,
    this.color = Colors.black,
    required this.route,
    required this.description,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push(route);
        },
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromRGBO(0, 0, 0, 0.4),
                  ),
                )
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
