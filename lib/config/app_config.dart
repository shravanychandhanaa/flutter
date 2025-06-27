import 'environment.dart';

class AppConfig {
  // Build configuration - change this for different builds
  static const Environment defaultEnvironment = Environment.development;
  
  // API Configuration for each environment
  static const Map<Environment, Map<String, dynamic>> apiConfigs = {
    Environment.development: {
      'baseUrl': 'https://dev.startupworld.in/',
      'apiKey': 'efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u',
      'timeout': 30, // seconds
      'enableLogging': true,
    },
    Environment.testing: {
      'baseUrl': 'https://test.startupworld.in/',
      'apiKey': 'efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u',
      'timeout': 60, // seconds
      'enableLogging': true,
    },
    Environment.production: {
      'baseUrl': 'https://startupworld.in',
      'apiKey': 'efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u',
      'timeout': 120, // seconds
      'enableLogging': false,
    },
  };
  
  // Initialize the app with the default environment
  static void initialize() {
    EnvironmentConfig.setEnvironment(defaultEnvironment);
  }
  
  // Get configuration for current environment
  static Map<String, dynamic> get currentConfig {
    return apiConfigs[EnvironmentConfig.environment] ?? apiConfigs[Environment.development]!;
  }
  
  // Helper methods to get specific config values
  static String get baseUrl => currentConfig['baseUrl'];
  static String get apiKey {
    final key = currentConfig['apiKey'];
    print('🔑 AppConfig.apiKey called:');
    print('   Environment: ${EnvironmentConfig.environment}');
    print('   Current config: $currentConfig');
    print('   API Key from config: ${key.substring(0, 10)}...');
    print('   Full API Key: $key');
    return key;
  }
  static int get timeoutSeconds => currentConfig['timeout'];
  static bool get enableLogging => currentConfig['enableLogging'];
  
  // Debug method to show current configuration
  static void debugConfig() {
    print('🔧 AppConfig Debug:');
    print('   Environment: ${EnvironmentConfig.environment}');
    print('   Base URL: $baseUrl');
    print('   API Key: ${apiKey.substring(0, 10)}...');
    print('   Timeout: ${timeoutSeconds}s');
    print('   Logging: $enableLogging');
  }
  
  // App-specific configurations
  static const String appName = 'StartupWorld';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Feature flags
  static const bool enableDebugMode = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Network Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Storage Configuration
  static const String userPreferencesKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
} 