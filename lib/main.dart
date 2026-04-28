import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'router/app_router.dart';
import 'tflite_model/model_connection.dart';
import 'shared/widgets/achievemnt_banner.dart';
import 'shared/theme/app_theme.dart';

import 'services/settings_service.dart';
import 'services/profile_service.dart';
import 'services/tts_service.dart';
import 'services/service_manager.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Preload heavy services early to avoid lag during navigation
  print('⏳ [MAIN] Starting app initialization...');
  final appStartTime = DateTime.now();
  
  // 1. Initialize TFLite model
  print('⏳ [MAIN] Preloading TensorFlow Lite model...');
  final modelStart = DateTime.now();
  initializeModelResources();
  final modelDuration = DateTime.now().difference(modelStart);
  print('⏳ [MAIN] TensorFlow Lite model preloaded in ${modelDuration.inMilliseconds}ms');
  
  // 2. Initialize hand recognition service (singleton)
  print('⏳ [MAIN] Preloading hand recognition service...');
  final handStart = DateTime.now();
  await ServiceManager.initializeServices();
  final handDuration = DateTime.now().difference(handStart);
  print('⏳ [MAIN] Hand recognition service preloaded in ${handDuration.inMilliseconds}ms');

  // 3. Initialize other services
  final savedSettings = await SettingsService.getAllSettings();
  await ProfileService.initialize();

  await TtsService.initTts(
    speed: savedSettings['speechSpeed'],
    genderPreference: savedSettings['selectedVoice'],
  );
  
  final totalDuration = DateTime.now().difference(appStartTime);
  print('⏳ [MAIN] ✅ App initialization completed in ${totalDuration.inMilliseconds}ms');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService.darkModeNotifier,
      builder: (context, isDarkMode, _) {
        return MaterialApp.router(
          title: 'Sign Language Recognition',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return AchievementBannerHost(
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}