import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/pages/recognize_signs_page.dart';

import '/pages/home_page.dart';
import '/pages/profile_page.dart';
import '/pages/learning_progress_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/learning-progress',
        name: 'learning_progress',
        builder: (context, state) {
          final extra = state.extra as Map<String, int>? ?? {};
          return LearningProgressPage(
            lessonsCompleted: extra['lessonsCompleted'] ?? 0, 
            quizzesCompleted: extra['quizzesCompleted'] ?? 0, 
            totalLessons: extra['totalLessons'] ?? 0, 
            totalQuizzes: extra['totalQuizzes']?? 0,
          );
        },
      ),
      GoRoute(
        path: '/recognize-signs',
        name: '/recognize_signs',
        builder: (context, state) => const RecognizePage(),
      )
    ]
  );
}