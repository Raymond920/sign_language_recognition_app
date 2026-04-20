import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/shared/widgets/achievemnt_banner.dart';
import 'package:sign_language_recognition_app/shared/widgets/navigation_button.dart';
import 'package:sign_language_recognition_app/shared/widgets/profile_avatar.dart';
import '../shared/widgets/dashboard_block.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    print('🏠 [HOME] initState called');
    print('🏠 [HOME] Current cached image before refresh: ${ProfileService.cachedProfileImage?.path}');
    
    // Refresh after first frame to ensure state updates properly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🏠 [HOME] postFrameCallback triggered');
      _refreshProfileImage();
    });
  }

  Future<void> _refreshProfileImage() async {
    print('🏠 [HOME] _refreshProfileImage() called');
    print('🏠 [HOME] Cache BEFORE refresh: ${ProfileService.cachedProfileImage?.path}');
    
    // Refresh profile image cache when home screen is displayed
    await ProfileService.refreshProfileImage();
    
    print('🏠 [HOME] Cache AFTER refresh: ${ProfileService.cachedProfileImage?.path}');
    
    // Force UI rebuild to show updated image
    if (mounted) {
      print('🏠 [HOME] Widget mounted, calling setState()');
      setState(() {
        print('🏠 [HOME] setState() callback executed');
      });
    } else {
      print('🏠 [HOME] Widget not mounted, skipping setState()');
    }
  }

  Widget _drawer() {
    print('🏠 [HOME] _drawer() building...');
    print('🏠 [HOME] _drawer() cached image: ${ProfileService.cachedProfileImage?.path}');
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context); // close the drawer
                context.push("/profile");
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Wrap ProfileAvatar in ValueListenableBuilder to react to profile image changes
                  ValueListenableBuilder<String?>(
                    valueListenable: ProfileService.profileImageNotifier,
                    builder: (context, imagePath, _) {
                      print('🏠 [HOME] ValueListenableBuilder updated with path: $imagePath');
                      return ProfileAvatar(
                        profileImage: imagePath != null ? File(imagePath) : null,
                        radius: 45,
                        backgroundColor: Colors.deepPurple[100]!,
                        iconData: Icons.person,
                        iconColor: Colors.deepPurple,
                        iconSize: 80,
                      );
                    },
                  ),
                  SizedBox(width: 20,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Profile',
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage your account',
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined),
            title: Text('Recognize Signs'),
            onTap: () {
              Navigator.pop(context);
              context.push("/recognize-signs");
            },
          ),
          ListTile(
            leading: Icon(Icons.book_outlined),
            title: Text('MSL Library'),
            onTap: () {
              Navigator.pop(context);
              context.push("/signs-library");
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.school_outlined),
            title: Text('Practise MSL'),
            shape: const Border(),
            collapsedShape: const Border(),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                  leading: Icon(Icons.menu_book_outlined),
                  title: Text('Attend Lessons'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push("/lessons");
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListTile(
                  leading: Icon(Icons.psychology_outlined),
                  title: Text('Take Quizzes'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push("/quizzes-list");
                  },
                ),
              )
            ],
          ),          
          ListTile(
            leading: Icon(Icons.bar_chart_outlined),
            title: Text('Progress Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.push("/learning-progress");
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push("/settings");
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("MSL Translator"),

        actions: [
          IconButton(
            onPressed: () {
              if (SettingsService.cachedHaptic) {
                HapticFeedback.selectionClick();
              }
              context.push("/profile");
            }, 
            icon: const Icon(Icons.account_circle_rounded))
        ],
      ),
      drawer: _drawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 40),
              ValueListenableBuilder<String>(
                valueListenable: ProfileService.usernameNotifier,
                builder: (context, username, _) {
                  return WelcomeDialog(username: username);
                },
              ),
              const SizedBox(height: 40),
              // TODO: debug achivement banner notification.
              // TextButton.icon(
              //   onPressed: () {
              //     showAchievementNotification('🎯 First Steps unlocked (debug)');
              //   },
              //   icon: const Icon(Icons.emoji_events_outlined),
              //   label: const Text('Show Achievement Banner'),
              //   style: TextButton.styleFrom(
              //     foregroundColor: Colors.white,
              //     backgroundColor: Colors.orange,
              //     padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     textStyle: const TextStyle(
              //       fontSize: 14,
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
              const LearningProgressButton(),
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

class LearningProgressButton extends StatefulWidget {
  const LearningProgressButton({super.key});

  @override
  State<LearningProgressButton> createState() => _LearningProgressButtonState();
}

class _LearningProgressButtonState extends State<LearningProgressButton> with WidgetsBindingObserver {
  int _lessonsCompleted = 0;
  int _quizzesCompleted = 0;
  int _totalLessons = 0;
  int _totalQuizzes = 0;
  final DBHelper _dbHelper = DBHelper();
  late AppLifecycleListener _lifecycleListener;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
    // Listen to total points changes and refresh data
    ProfileService.totalPointsNotifier.addListener(_onPointsChanged);
    
    // CRITICAL FIX: Add WidgetsBindingObserver to catch quiz updates from ANY completion (not just 100% scores)
    WidgetsBinding.instance.addObserver(this);
    print('🏠 [HOME] Registered WidgetsBindingObserver to catch quiz updates from ANY completion');
    
    // Add lifecycle listener to refresh when page resumes
    _lifecycleListener = AppLifecycleListener(
      onResume: _onPageResume,
    );
  }

  @override
  void dispose() {
    ProfileService.totalPointsNotifier.removeListener(_onPointsChanged);
    _lifecycleListener.dispose();
    WidgetsBinding.instance.removeObserver(this);
    print('🏠 [HOME] Removed WidgetsBindingObserver');
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // CRITICAL FIX: Detect return from route navigation (even if no points awarded)
    // When app state changes from paused→resumed, refresh progress
    // This catches non-perfect scores (80%, 90%, etc.) that don't award points
    if (_lastLifecycleState == AppLifecycleState.paused && state == AppLifecycleState.resumed) {
      print('🏠 [HOME] App resumed from paused state - checking for quiz updates (catches ANY quiz score)...');
      _loadProgressData();
    }
    _lastLifecycleState = state;
  }

  Future<void> _onPageResume() async {
    print('🏠 [HOME] App resumed, updating progress...');
    // Refresh progress data when app comes back from background
    await _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      final allLessons = await _dbHelper.getAllLessons();
      final allQuizzes = await _dbHelper.getAllQuizzes();
      // Use same filtering as quizzes_list_page for consistency (score >= 60)
      final completedQuizzes = allQuizzes.where((quiz) => quiz.bestScore >= 60).toList();

      setState(() {
        _totalLessons = allLessons.length;
        _totalQuizzes = allQuizzes.length;
        _lessonsCompleted =
            allLessons.where((lesson) => lesson.isCompleted).length;
        _quizzesCompleted = completedQuizzes.length;
      });
      
      print('🏠 [HOME] Progress loaded: $_lessonsCompleted/$_totalLessons lessons, $_quizzesCompleted/$_totalQuizzes quizzes = ${((_lessonsCompleted + _quizzesCompleted) / (_totalLessons + _totalQuizzes) * 100).toStringAsFixed(2)}%');
    } catch (e) {
      print('🏠 [HOME] Error loading progress data: $e');
    }
  }

  void _onPointsChanged() {
    print('🏠 [HOME] Points changed, scheduling data refresh...');
    // Add delay to ensure database is updated before querying
    // Use Future.delayed instead of waiting for page resume since home page widget is always visible
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _loadProgressData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardBlock(
      title: 'Learning Progress',
      icon: Icons.trending_up,
      iconColor: Color.fromRGBO(6, 182, 212, 1.0),
      onTap: () { 
        context.push('/learning-progress', 
        extra: {
          'lessonsCompleted': _lessonsCompleted,
          'totalLessons': _totalLessons,
          'quizzesCompleted': _quizzesCompleted,
          'totalQuizzes': _totalQuizzes,
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
                _totalLessons + _totalQuizzes > 0 
                  ? "${((_lessonsCompleted + _quizzesCompleted) / (_totalLessons + _totalQuizzes) * 100).toStringAsFixed(2)}%"
                  : "0%",
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
              value: _totalLessons + _totalQuizzes > 0
                  ? (_lessonsCompleted + _quizzesCompleted) / (_totalLessons + _totalQuizzes)
                  : 0.0,
              minHeight: 12.0,
              backgroundColor: Color.fromRGBO(99, 102, 241, 0.2),
              color: Color.fromRGBO(99, 102, 241, 1.0),
            ),
          ),
          SizedBox(height: 15.0),
        ],
      ),
    );
  }
}