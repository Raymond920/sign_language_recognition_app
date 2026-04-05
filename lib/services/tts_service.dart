import "package:flutter_tts/flutter_tts.dart";

class TtsService {
    static final FlutterTts _flutterTts = FlutterTts();

    static double _normalizedSpeechRate(double speed) {
      final clamped = speed.clamp(0.0, 1.0).toDouble();
      // Keep a safe lower bound because some engines treat 0.0 as default speed.
      return 0.2 + (clamped * 0.8);
    }

    static Future<void> initTts({
      required double speed, 
      required String genderPreference
    }) async {
      await _flutterTts.setLanguage("en-US");
      await updateSettings(speed: speed, genderPreference: genderPreference);
    }

    static Future<void> updateSettings({
      required double speed, 
      required String genderPreference
    }) async {
      // 1. Set Speech Rate (Speed)
      // Map UI value (0.0-1.0) to a reliable engine range.
      await _flutterTts.setSpeechRate(_normalizedSpeechRate(speed));

      // 2. Set Voice based on gender preference
      await _setVoiceByGender(genderPreference);
    }

    static Future<void> _setVoiceByGender(String gender) async {
      try {
        List<dynamic> voices = await _flutterTts.getVoices;
        
        // Filter voices for English (US)
        // Note: Android and iOS return different Map structures
        var targetVoice = voices.firstWhere((voice) {
          final String name = voice["name"].toString().toLowerCase();
          
          if (gender == "Female Voice") {
            // Common keywords for female voices in system names
            return name == "en-us-x-tpc-local";
          } else {
            // Use a fixed male voice
            return name == "en-us-x-tpd-local";
          }
        }, orElse: () => null);

        if (targetVoice != null) {
          await _flutterTts.setVoice({"name": targetVoice["name"], "locale": targetVoice["locale"]});
        }
      } catch (e) {
        print("Error setting voice: $e");
      }
    }

    // speak text
    static Future<void> speakText(String text) async {
        await _flutterTts.speak(text);
    }

    // Stop speaking
    static Future<void> stopSpeaking() async {
        await _flutterTts.stop();
    }
}