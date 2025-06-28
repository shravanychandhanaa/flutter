import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'api_client.dart';

class AuthService {
  static const String _currentUserKey = 'current_user';
  static const String _rememberMeKey = 'remember_me';
  static const String _sessionDataKey = 'session_data';
  final Uuid _uuid = const Uuid();

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
    String? team,
    String? project,
    String? collegeId,
    String? phone,
  }) async {
    try {
      Map<String, dynamic> requestData = {
        'name': name,
        'email': email,
        'password': password,
        'user_type': userType.toString().split('.').last,
        'team': team ?? '',
        'project': project ?? '',
        'college_id': collegeId ?? '',
        'phone': phone ?? '',
      };

      Response response;
      
      if (userType == UserType.student) {
        response = await ApiService.registerStudent(requestData);
      } else {
        response = await ApiService.registerTeacher(requestData);
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          // Create user object for local storage
          final newUser = User(
            id: responseData['user_id']?.toString() ?? _uuid.v4(),
            name: name,
            email: email,
            userType: userType,
            team: team,
            project: project,
          );

          // Store current user locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));

          return {
            'success': true,
            'message': responseData['message'] ?? 'Registration successful',
            'user': newUser,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Registration failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required UserType userType,
    bool rememberMe = false,
  }) async {
    try {
      Map<String, dynamic> requestData = {
        'api_key': AppConfig.apiKey,
      };

      // Debug logging for API key
      print('🔑 Login - API Key being sent: ${AppConfig.apiKey.substring(0, 10)}...');
      print('🔑 Login - Full API Key: ${AppConfig.apiKey}');

      // For students, use pwd field and usertype "1"
      // For staff, use password field and usertype "3"
      if (userType == UserType.student) {
        requestData['email'] = email;
        requestData['pwd'] = password; // Use 'pwd' for students
        requestData['usertype'] = '1'; // Student usertype
      } else {
        requestData['username'] = email; // email parameter contains username for staff
        requestData['password'] = password; // Use 'password' for staff
        requestData['usertype'] = '3'; // Staff usertype as specified
      }

      print('🔐 Login request data: $requestData');
      print('👤 User type: $userType');

      Response response;
      
      if (userType == UserType.student) {
        response = await ApiService.studentLogin(requestData);
      } else {
        // Test print to verify this section is reached
        print('🔍 ENTERING STAFF LOGIN SECTION');
        
        // Enhanced debug logging for staff login in production
        print('🚀 STAFF LOGIN DEBUG - PRODUCTION');
        print('📡 Full API URL: ${ApiService.getStaffLoginUrl()}');
        print('📤 Request Body (JSON): ${jsonEncode(requestData)}');
        print('📤 Request Body (Formatted):');
        requestData.forEach((key, value) {
          print('   $key: $value');
        });
        print('📤 Request Headers: ${ApiService.getStaffLoginHeaders()}');
        
        response = await ApiService.staffLogin(requestData);
        
        print('📥 Response Status Code: ${response.statusCode}');
        print('📥 Response Headers: ${response.headers}');
        print('📥 Response Data Type: ${response.data.runtimeType}');
        print('📥 Response Body (Raw): ${response.data}');
        print('📥 Response Body (JSON): ${jsonEncode(response.data)}');
        
        // Log response details for debugging
        if (response.data is Map) {
          print('📥 Response Keys: ${response.data.keys.toList()}');
          print('📥 Response Status Field: ${response.data['responseStatus']}');
          print('📥 Response Message: ${response.data['responseMessage']}');
          if (response.data['Staff_Details'] != null) {
            print('📥 Staff Details Count: ${response.data['Staff_Details'].length}');
            if (response.data['Staff_Details'].isNotEmpty) {
              print('📥 First Staff Member: ${jsonEncode(response.data['Staff_Details'][0])}');
            }
          }
        }
      }

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      // Handle different response types
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Check if response is a Map (JSON) or String (HTML with JSON)
        Map<String, dynamic> parsedData;
        if (responseData is Map<String, dynamic>) {
          parsedData = responseData;
        } else if (responseData is String) {
          try {
            // Try to parse as JSON
            parsedData = jsonDecode(responseData);
          } catch (e) {
            // If it's HTML, try to extract JSON from it
            if (responseData.contains('{')) {
              final jsonStart = responseData.indexOf('{');
              final jsonEnd = responseData.lastIndexOf('}') + 1;
              if (jsonStart >= 0 && jsonEnd > jsonStart) {
                final jsonString = responseData.substring(jsonStart, jsonEnd);
                parsedData = jsonDecode(jsonString);
              } else {
                return {
                  'success': false,
                  'message': 'Invalid response format from server',
                };
              }
            } else {
              return {
                'success': false,
                'message': 'Invalid response format from server',
              };
            }
          }
        } else {
          return {
            'success': false,
            'message': 'Unexpected response type from server',
          };
        }
        
        print('🔍 Parsed data: $parsedData');
        
        // Handle different response formats for student vs staff
        bool isSuccess = false;
        Map<String, dynamic> userData = {};
        Map<String, dynamic> sessionData = {};
        
        if (userType == UserType.student) {
          // Student response format
          isSuccess = parsedData['responseStatus'] == 200;
          if (isSuccess && parsedData['User_Details'] != null && parsedData['User_Details'] is List) {
            final userList = parsedData['User_Details'] as List;
            if (userList.isNotEmpty) {
              userData = userList.first; // Get the first user
            }
          }
          // Store session data for students
          sessionData = {
            'team_leader_status': parsedData['Team_Leader_Status'] ?? 'false',
            'user_details': parsedData['User_Details'] ?? [],
          };
          print('🎓 Student login - Success: $isSuccess, User data: $userData');
        } else {
          // Staff response format
          isSuccess = parsedData['responseStatus'] == 200;
          if (isSuccess && parsedData['Staff_Details'] != null && parsedData['Staff_Details'] is List) {
            final staffList = parsedData['Staff_Details'] as List;
            if (staffList.isNotEmpty) {
              userData = staffList.first; // Get the first staff member
            }
          }
          // Store session data for staff
          sessionData = {
            'staff_details': parsedData['Staff_Details'] ?? [],
          };
          print('👨‍💼 Staff login - Success: $isSuccess, User data: $userData');
        }
        
        if (isSuccess && userData.isNotEmpty) {
          // Create user object from API response
          final user = User(
            id: userData['id']?.toString() ?? _uuid.v4(),
            name: userData['uname'] ?? userData['name'] ?? '', // Handle both uname and name
            email: userData['email_id'] ?? userData['email'] ?? email, // Handle both email_id and email fields
            userType: userType,
            team: userData['team'] ?? '',
            project: userData['project_name'] ?? userData['project'] ?? '', // Handle project_name for students
          );

          print('✅ Created user object: ${user.toJson()}');

          // Store current user and session data locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
          await prefs.setString(_sessionDataKey, jsonEncode(sessionData));
          
          // Store remember me preference
          await prefs.setBool(_rememberMeKey, rememberMe);

          return {
            'success': true,
            'message': parsedData['responseMessage'] ?? parsedData['message'] ?? 'Login successful',
            'user': user,
            'sessionData': sessionData,
          };
        } else {
          print('❌ Login failed - Success: $isSuccess, User data empty: ${userData.isEmpty}');
          return {
            'success': false,
            'message': parsedData['responseMessage'] ?? parsedData['message'] ?? 'Invalid credentials',
          };
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Get session data
  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionDataKey);
      
      if (sessionJson != null) {
        return jsonDecode(sessionJson);
      }
      
      return null;
    } catch (e) {
      print('Get session data error: $e');
      return null;
    }
  }

  // Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print('Get remember me error: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_sessionDataKey);
      
      // Only clear remember me if it's not enabled
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (!rememberMe) {
        await prefs.remove(_rememberMeKey);
      }
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Get all users (for staff to see)
  Future<List<User>> getAllUsers() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser?.userType != UserType.staff) {
        return [];
      }

      final response = await ApiService.getStudentList({
        'staff_id': currentUser!.id,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success') {
          final usersList = responseData['users'] ?? [];
          return usersList.map<User>((userData) => User.fromJson(userData)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  // Validate College ID
  Future<bool> validateCollegeId(String collegeId) async {
    try {
      final response = await ApiService.validateCollegeID({
        'college_id': collegeId,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['status'] == 'success' && 
               (responseData['valid'] == true || responseData['is_valid'] == true);
      }
      
      return false;
    } catch (e) {
      print('Validate college ID error: $e');
      return false;
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await ApiService.sendOTP({
        'email': email,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        return {
          'success': responseData['status'] == 'success',
          'message': responseData['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('Send OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await ApiService.verifyOTP({
        'email': email,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        return {
          'success': responseData['status'] == 'success',
          'message': responseData['message'] ?? 'OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid OTP',
        };
      }
    } catch (e) {
      print('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'Failed to verify OTP: $e',
      };
    }
  }

  // Delete user data
  Future<Map<String, dynamic>> deleteUserData({
    required String userId,
    required String reason,
    String? feedback,
    String? customReason,
  }) async {
    try {
      final response = await ApiService.deleteUserData({
        'user_id': userId,
        'reason': reason,
        'feedback': feedback ?? '',
        'custom_reason': customReason ?? '',
        'deletion_date': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        return {
          'success': responseData['status'] == 'success',
          'message': responseData['message'] ?? 'Data deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete data: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Delete user data error: $e');
      return {
        'success': false,
        'message': 'Failed to delete data: $e',
      };
    }
  }
} 