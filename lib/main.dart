import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'tflite_model/model_connection.dart';

import 'services/settings_service.dart';
import 'services/tts_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // Start model preload at app startup to reduce waiting time before recognition.
  initializeModelResources();

  final savedSettings = await SettingsService.getAllSettings();

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
    return MaterialApp.router(
      title: 'Sign Language Recognition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}