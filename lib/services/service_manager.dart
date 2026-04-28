import 'package:sign_language_recognition_app/services/hand_recognition_service.dart';

/// Singleton manager for app services
/// Ensures services are initialized once and reused across pages
class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  static late HandRecognitionService _handRecognitionService;
  static bool _isInitialized = false;

  ServiceManager._internal();

  factory ServiceManager() {
    return _instance;
  }

  /// Initialize all services at app startup
  /// This happens ONCE before any pages are loaded
  static Future<void> initializeServices() async {
    if (_isInitialized) {
      print('🔧 [SERVICE_MANAGER] Services already initialized, skipping...');
      return;
    }

    try {
      print('🔧 [SERVICE_MANAGER] Initializing services at app startup...');
      final startTime = DateTime.now();

      // Initialize hand recognition service (the expensive one)
      print('🔧 [SERVICE_MANAGER] Preloading hand recognition service...');
      final handStart = DateTime.now();
      _handRecognitionService = HandRecognitionService();
      await _handRecognitionService.initialize();
      final handDuration = DateTime.now().difference(handStart);
      print('🔧 [SERVICE_MANAGER] Hand recognition service preloaded in ${handDuration.inMilliseconds}ms');

      _isInitialized = true;
      final totalDuration = DateTime.now().difference(startTime);
      print('🔧 [SERVICE_MANAGER] ✅ All services initialized in ${totalDuration.inMilliseconds}ms');
    } catch (e) {
      print('❌ [SERVICE_MANAGER] Error initializing services: $e');
      rethrow;
    }
  }

  /// Get the singleton hand recognition service instance
  /// Returns the preloaded instance - no waiting required
  static HandRecognitionService getHandRecognitionService() {
    if (!_isInitialized) {
      throw Exception(
          '❌ ServiceManager not initialized! Call initializeServices() at app startup.');
    }
    return _handRecognitionService;
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;
}
