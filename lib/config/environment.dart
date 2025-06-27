enum Environment {
  development,
  testing,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.development;
  
  // Set the current environment
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  // Get the current environment
  static Environment get environment => _environment;
  
  // Get base URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        return "https://dev.startupworld.in/";
      case Environment.testing:
        return "https://test.startupworld.in/";
      case Environment.production:
        return "https://startupworld.in";
    }
  }
  
  // Get API key based on environment (sent in request body, not headers)
  static String get apiKey {
    switch (_environment) {
      case Environment.development:
        return "efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u"; // Replace with actual dev API key
      case Environment.testing:
        return "efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u"; // Replace with actual test API key
      case Environment.production:
        return "efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u";
    }
  }
  
  // Get timeout duration based on environment
  static Duration get timeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 30); // Shorter timeout for dev
      case Environment.testing:
        return const Duration(seconds: 60); // Medium timeout for testing
      case Environment.production:
        return const Duration(seconds: 120); // Longer timeout for production
    }
  }
  
  // Get whether to enable debug logging
  static bool get enableDebugLogging {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.testing:
        return true;
      case Environment.production:
        return false;
    }
  }
  
  // Get environment name for display
  static String get environmentName {
    switch (_environment) {
      case Environment.development:
        return "Development";
      case Environment.testing:
        return "Testing";
      case Environment.production:
        return "Production";
    }
  }
  
  // Get environment color for UI
  static int get environmentColor {
    switch (_environment) {
      case Environment.development:
        return 0xFFFF9800; // Orange
      case Environment.testing:
        return 0xFF2196F3; // Blue
      case Environment.production:
        return 0xFF4CAF50; // Green
    }
  }
  
  // Get environment-specific configuration
  static Map<String, dynamic> get config {
    switch (_environment) {
      case Environment.development:
        return {
          'baseUrl': 'https://dev.startupworld.in/',
          'apiKey': 'efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u',
          'timeout': 30,
          'enableLogging': true,
          'name': 'Development',
          'color': 0xFFFF9800,
        };
      case Environment.testing:
        return {
          'baseUrl': 'https://test.startupworld.in/',
          'apiKey': 'efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u',
          'timeout': 60,
          'enableLogging': true,
          'name': 'Testing',
          'color': 0xFF2196F3,
        };
      case Environment.production:
        return {
          'baseUrl': 'https://startupworld.in',
          'apiKey': 'efc10cqkr4Ta29EIYolGsAxRiwOBVmDgn3X9e5ZMKzyC8bsv7u',
          'timeout': 120,
          'enableLogging': false,
          'name': 'Production',
          'color': 0xFF4CAF50,
        };
    }
  }
} 