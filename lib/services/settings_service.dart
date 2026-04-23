import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // Define Keys to avoid typos
  static const String _keyTts = 'isTtsEnabled';
  static const String _keyVoice = 'selectedVoice';
  static const String _keySpeed = 'speechSpeed';
  static const String _keydarkMode = 'isDarkMode';
  static const String _keyShowLandmarks = 'isShowLandmarks';
  static const String _keyHaptic = 'isHaptic';
  static const String _keyAutoplay = 'isAutoplay';

  // In-memory cache for instant reads in UI.
  static bool _cachedTtsEnabled = false;
  static String _cachedVoice = "Female Voice";
  static double _cachedSpeed = 0.4;
  static bool _cachedDarkMode = false;
  static bool _cachedShowLandmarks = true;
  static bool _cachedHaptic = true;
  static bool _cachedAutoplay = true;
  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(_cachedDarkMode);

  static bool get cachedTtsEnabled => _cachedTtsEnabled;
  static String get cachedVoice => _cachedVoice;
  static double get cachedSpeed => _cachedSpeed;
  static bool get cachedDarkMode => _cachedDarkMode;
  static bool get cachedShowLandmarks => _cachedShowLandmarks;
  static bool get cachedHaptic => _cachedHaptic;
  static bool get cachedAutoplay => _cachedAutoplay;

  // Save methods
  static Future<void> setTts(bool value) async {
    _cachedTtsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTts, value);
  }

  static Future<void> setVoice(String value) async {
    _cachedVoice = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVoice, value);
  }

  static Future<void> setSpeed(double value) async {
    _cachedSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySpeed, value);
  }

  static Future<void> setDarkMode(bool value) async {
    _cachedDarkMode = value;
    darkModeNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keydarkMode, value);
  }

  static Future<void> setShowLandmarks(bool value) async {
    _cachedShowLandmarks = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowLandmarks, value);
  }

  static Future<void> setHaptic(bool value) async {
    _cachedHaptic = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptic, value);
  }

  static Future<void> setAutoplay(bool value) async {
    _cachedAutoplay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoplay, value);
  }

  // Load method (returns a Map with all settings)
  static Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _cachedTtsEnabled = prefs.getBool(_keyTts) ?? false;
    _cachedVoice = prefs.getString(_keyVoice) ?? "Female Voice";
    _cachedSpeed = prefs.getDouble(_keySpeed) ?? 0.4;
    _cachedDarkMode = prefs.getBool(_keydarkMode) ?? false;
    darkModeNotifier.value = _cachedDarkMode;
    _cachedShowLandmarks = prefs.getBool(_keyShowLandmarks) ?? true;
    _cachedHaptic = prefs.getBool(_keyHaptic) ?? true;
    _cachedAutoplay = prefs.getBool(_keyAutoplay) ?? true;

    return {
      'isTtsEnabled': _cachedTtsEnabled,
      'selectedVoice': _cachedVoice,
      'speechSpeed': _cachedSpeed,
      'isDarkMode': _cachedDarkMode,
      'isShowLandmarks': _cachedShowLandmarks,
      'isHaptic': _cachedHaptic,
      'isAutoplay': _cachedAutoplay,
    };
  }
}