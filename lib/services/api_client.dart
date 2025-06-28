import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// Conditional import for web
import '../config/environment.dart';

// Web-compatible HTTP client using a simpler approach
class WebHttpClient {
  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> data) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebHttpClient only works on web platforms');
    }
    
    try {
      // For web, we'll use a simpler approach that doesn't require dart:html
      // This will throw an error but can be caught and handled gracefully
      throw UnsupportedError('Web HTTP client not implemented - using Dio fallback');
    } catch (e) {
      if (EnvironmentConfig.enableDebugLogging) {
        print('❌ Web HTTP Error: $e');
      }
      rethrow;
    }
  }
}

// Platform-specific HTTP client
class PlatformHttpClient {
  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> data) async {
    if (kIsWeb) {
      // On web, just throw an error so we can use Dio fallback
      throw UnsupportedError('Web platform - using Dio fallback');
    } else {
      return await CustomHttpClient.post(url, data);
    }
  }
}

// Alternative HTTP client using dart:io for mobile platforms
class CustomHttpClient {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 30);

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> data) async {
    if (kIsWeb) {
      throw UnsupportedError('CustomHttpClient does not work on web platforms');
    }
    
    try {
      final uri = Uri.parse(url);
      final request = await _client.postUrl(uri);
      
      // Set headers
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json, text/plain, */*');
      request.headers.set('Accept-Encoding', 'gzip, deflate, br');
      request.headers.set('Connection', 'keep-alive');
      request.headers.set('Cache-Control', 'no-cache');
      request.headers.set('Pragma', 'no-cache');
      
      // Write request body
      request.write(jsonEncode(data));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (EnvironmentConfig.enableDebugLogging) {
        print('🌐 Custom HTTP Request: POST $url');
        print('📤 Request Data: $data');
        print('✅ Custom HTTP Response: ${response.statusCode}');
        print('📥 Response Data: $responseBody');
      }
      
      // Try to parse response
      try {
        final jsonData = jsonDecode(responseBody);
        return {
          'statusCode': response.statusCode,
          'data': jsonData,
        };
      } catch (e) {
        // If it's HTML, try to extract JSON
        if (responseBody.contains('{')) {
          final jsonStart = responseBody.indexOf('{');
          final jsonEnd = responseBody.lastIndexOf('}') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = responseBody.substring(jsonStart, jsonEnd);
            final jsonData = jsonDecode(jsonString);
            return {
              'statusCode': response.statusCode,
              'data': jsonData,
            };
          }
        }
        
        return {
          'statusCode': response.statusCode,
          'data': responseBody,
        };
      }
    } catch (e) {
      if (EnvironmentConfig.enableDebugLogging) {
        print('❌ Custom HTTP Error: $e');
      }
      rethrow;
    }
  }
}

// Custom interceptor to handle server compatibility and response parsing
class ServerCompatibilityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add headers that match the working Postman request exactly
    options.headers["Content-Type"] = "application/json";
    options.headers["Accept"] = "application/json, text/plain, */*";
    options.headers["Accept-Encoding"] = "gzip, deflate, br";
    options.headers["Connection"] = "keep-alive";
    options.headers["Cache-Control"] = "no-cache";
    options.headers["Pragma"] = "no-cache";
    
    // Remove any CORS headers that might trigger preflight
    options.headers.remove("Access-Control-Allow-Origin");
    options.headers.remove("Access-Control-Allow-Methods");
    options.headers.remove("Access-Control-Allow-Headers");
    options.headers.remove("Access-Control-Max-Age");
    
    if (EnvironmentConfig.enableDebugLogging) {
      print('🌐 API Request: ${options.method} ${options.path}');
      print('📤 Request Data: ${options.data}');
      print('📋 Request Headers: ${options.headers}');
    }
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle HTML responses by trying to parse them as JSON if possible
    if (response.headers.value("content-type")?.contains("text/html") == true) {
      if (EnvironmentConfig.enableDebugLogging) {
        print('⚠️ Server returned HTML instead of JSON. Attempting to parse...');
      }
      
      // Try to extract JSON from HTML response if it contains JSON
      final responseData = response.data;
      if (responseData is String && responseData.contains('{')) {
        try {
          // Look for JSON content in the HTML
          final jsonStart = responseData.indexOf('{');
          final jsonEnd = responseData.lastIndexOf('}') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = responseData.substring(jsonStart, jsonEnd);
            final jsonData = jsonDecode(jsonString);
            response.data = jsonData;
            if (EnvironmentConfig.enableDebugLogging) {
              print('✅ Successfully extracted JSON from HTML response');
            }
          }
        } catch (e) {
          if (EnvironmentConfig.enableDebugLogging) {
            print('❌ Failed to extract JSON from HTML response: $e');
          }
        }
      }
    }
    
    if (EnvironmentConfig.enableDebugLogging) {
      print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
      print('📥 Response Data: ${response.data}');
      print('📋 Response Headers: ${response.headers}');
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (EnvironmentConfig.enableDebugLogging) {
      print('❌ API Error: ${err.response?.statusCode} ${err.requestOptions.path}');
      print('🚨 Error Message: ${err.message}');
      print('📋 Error Data: ${err.response?.data}');
      print('📋 Error Headers: ${err.response?.headers}');
    }
    
    handler.next(err);
  }
}

// Create Dio instances with environment-specific configuration
Dio get apiClient => Dio(BaseOptions(
  baseUrl: EnvironmentConfig.baseUrl,
  connectTimeout: EnvironmentConfig.timeout,
  receiveTimeout: EnvironmentConfig.timeout,
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json, text/plain, */*",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Cache-Control": "no-cache",
    "Pragma": "no-cache",
  },
  // Configure to accept all responses
  validateStatus: (status) {
    return status != null && status < 500; // Accept all responses except server errors
  },
  // Disable automatic redirects and preflight
  followRedirects: false,
  maxRedirects: 0,
))..interceptors.add(ServerCompatibilityInterceptor());

// Legacy clients for backward compatibility (if needed)
final Dio apiClient1 = Dio(BaseOptions(
  baseUrl: "https://smartcookie.in/",
  connectTimeout: const Duration(seconds: 120),
  receiveTimeout: const Duration(seconds: 120),
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json, text/plain, */*",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Cache-Control": "no-cache",
    "Pragma": "no-cache",
  },
  validateStatus: (status) {
    return status != null && status < 500;
  },
  followRedirects: false,
  maxRedirects: 0,
))..interceptors.add(ServerCompatibilityInterceptor());

final Dio apiClient2 = Dio(BaseOptions(
  baseUrl: "https://dev.startupworld.in/",
  connectTimeout: const Duration(seconds: 120),
  receiveTimeout: const Duration(seconds: 120),
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json, text/plain, */*",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Cache-Control": "no-cache",
    "Pragma": "no-cache",
  },
  validateStatus: (status) {
    return status != null && status < 500;
  },
  followRedirects: false,
  maxRedirects: 0,
))..interceptors.add(ServerCompatibilityInterceptor()); 