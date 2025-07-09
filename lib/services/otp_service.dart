import 'package:dio/dio.dart';
import 'api_client.dart';

class OtpService {
  static const String _apiKey = "cda11aoip2Ry07CGWmjEqYvPguMZTkBel1V8c3XKIxwA6zQt5s";

  // Send OTP to phone number or email
  Future<Map<String, dynamic>> sendOtp({
    required String countryCode,
    required String phoneNumber,
    String? emailId,
  }) async {
    try {
      final requestData = {
        "operation": "send_otp",
        "country_code": countryCode,
        "phone_number": phoneNumber,
        "email_id": emailId ?? "",
        "api_key": _apiKey,
        "msg": "STAR_OTP"
      };

      final response = await apiClient.post('api2/api2.php?x=send_otp', data: requestData);

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200) {
          return {
            'success': true,
            'message': responseData['responseMessage'] ?? 'OTP sent successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['responseMessage'] ?? 'Failed to send OTP',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String countryCode,
    required String phoneNumber,
    required String otp,
    String? emailId,
  }) async {
    try {
      final requestData = {
        "operation": "varify_otp",
        "country_code": countryCode,
        "phone_number": phoneNumber,
        "email_id": emailId ?? "",
        "otp": otp,
        "api_key": _apiKey
      };

      final response = await apiClient.post('api2/api2.php?x=varify_otp', data: requestData);

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200) {
          return {
            'success': true,
            'message': responseData['responseMessage'] ?? 'OTP verified successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['responseMessage'] ?? 'OTP verification failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify OTP: $e',
      };
    }
  }
} 