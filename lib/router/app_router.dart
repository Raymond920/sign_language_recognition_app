import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';
import 'package:sign_language_recognition_app/pages/lesson_content_page.dart';
import 'package:sign_language_recognition_app/pages/lessons_list_page.dart';
import 'package:sign_language_recognition_app/pages/practice_sign_page.dart';
import 'package:sign_language_recognition_app/pages/quizzes_list_page.dart';
import 'package:sign_language_recognition_app/pages/recognize_signs_page.dart';
import 'package:sign_language_recognition_app/pages/settings_page.dart';
import 'package:sign_language_recognition_app/pages/sign_detail_page.dart';
import 'package:sign_language_recognition_app/pages/sign_library_page.dart';

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
        name: 'recognize_signs',
        builder: (context, state) => const RecognizePage(),
      ),
      GoRoute(
        path: '/signs-library',
        name: 'signs_library',
        builder: (context, state) => const SignsLibraryPage(),
      ),
      GoRoute(
        path: '/sign-detail',
        name: 'sign_detail',
        builder: (context, state) {
          final sign = state.extra as Sign;
          return SignDetailPage(sign: sign);
        }
      ),
      GoRoute(
        path: '/practice-signs',
        name: 'practice_signs',
        builder: (context, state) => const PracticeSignPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/lessons',
        name: 'lessons',
        builder: (context, state) => const LessonsListPage(),
      ),
      GoRoute(
        path: '/lesson-content',
        name: 'lesson_content',
        builder: (context, state) {
          final lesson = state.extra as Lesson;
          return LessonContentPage(lessonId: lesson.id);
        }
      ),
      GoRoute(
        path: '/quizzes-list',
        name: 'quizzes_list',
        builder: (context, state) => const QuizzesListPage(),
      ),
    ]
  );
}