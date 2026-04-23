import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'router/app_router.dart';
import 'tflite_model/model_connection.dart';
import 'shared/widgets/achievemnt_banner.dart';
import 'shared/theme/app_theme.dart';

import 'services/settings_service.dart';
import 'services/profile_service.dart';
import 'services/tts_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Start model preload at app startup to reduce waiting time before recognition.
  initializeModelResources();

  final savedSettings = await SettingsService.getAllSettings();
  await ProfileService.initialize();

  await TtsService.initTts(
    speed: savedSettings['speechSpeed'],
    genderPreference: savedSettings['selectedVoice'],
  );

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