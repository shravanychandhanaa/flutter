import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../config/environment.dart';
import 'api_client.dart';
import 'dart:convert';

class ApiService {
  // Error Logging
  static Future<Response> logError(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('error_log_ws.php', data: requestData);
  }

  // Team Details
  static Future<Response> getTeamStatus(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=Team_Details', data: requestData);
  }

  // Role List
  static Future<Response> getRoleList(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=Role_List', data: requestData);
  }

  // Team List
  static Future<Response> getTeamList(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=Team_List', data: requestData);
  }

  // Employee Registration
  static Future<Response> registerEmployee(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('api2/api2.php?x=addEmployeeProfile', data: requestData);
  }

  // Sponsorer Registration
  static Future<Response> registerSponsorer(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('api2/api2.php?x=interns_profile_api', data: requestData);
  }

  // Student Profile
  static Future<Response> showStudentProfile(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=student_profile_show', data: requestData);
  }

  // Forgot Password
  static Future<Response> forgotPassword(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('api2/api2.php?action=forgot_password', data: requestData);
  }

  // Student Login with fallback
  static Future<Response> studentLogin(Map<String, dynamic> data) async {
    // Get the current API client configuration
    final currentApiClient = apiClient;
    
    try {
      return await currentApiClient.post('Webservices/api3.php?action=student_login', data: data);
    } catch (e) {
      // Fallback to platform-specific HTTP client (only on mobile)
      if (!kIsWeb) {
        try {
          final result = await PlatformHttpClient.post('${currentApiClient.options.baseUrl}Webservices/api3.php?action=student_login', data);
          return Response(
            requestOptions: RequestOptions(path: 'Webservices/api3.php?action=student_login'),
            statusCode: result['statusCode'],
            data: result['data'],
          );
        } catch (e2) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  // Get Project List
  static Future<Response> getProjectList(Map<String, dynamic> data) async {
    // Add API key to the request data
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    
    return await apiClient.post('Webservices/api3.php?action=Master_List', data: requestData);
  }

  // Student Registration
  static Future<Response> registerStudent(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    
    return await apiClient.post('Webservices/api3.php?action=student_registration', data: requestData);
  }

  // Add Task
  static Future<Response> addTask(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=Add_Update_Task', data: requestData);
  }

  // Work Type List
  static Future<Response> getWorkTypeList(Map<String, dynamic> data) async {
    // Add API key to the request data
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    
    return await apiClient.post('/Webservices/api3.php?action=Work_Type_List', data: requestData);
  }

  // Validate College ID
  static Future<Response> validateCollegeID(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=Validate_CollegeID', data: requestData);
  }

  // Get All Colleges
  static Future<Response> getAllColleges() async {
    Map<String, dynamic> requestData = {
      'api_key': AppConfig.apiKey,
    };
    
    return await apiClient.post('Webservices/api3.php?action=college_list', data: requestData);
  }

  // Teacher Registration
  static Future<Response> registerTeacher(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('/Webservices/api3.php?action=teacher_registration', data: requestData);
  }

  // Staff Login with fallback
  static Future<Response> staffLogin(Map<String, dynamic> data) async {
    // Get the current API client configuration
    final currentApiClient = apiClient;
    
    try {
      final response = await currentApiClient.post('Webservices/api3.php?action=staff_login', data: data);
      return response;
    } catch (e) {
      // Fallback to platform-specific HTTP client (only on mobile)
      if (!kIsWeb) {
        try {
          final result = await PlatformHttpClient.post('${currentApiClient.options.baseUrl}Webservices/api3.php?action=staff_login', data);
          return Response(
            requestOptions: RequestOptions(path: 'Webservices/api3.php?action=staff_login'),
            statusCode: result['statusCode'],
            data: result['data'],
          );
        } catch (e2) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  // Get Student List with filtering
  static Future<Response> getStudentList(Map<String, dynamic> filters) async {
    // Prepare the request payload with default values
    Map<String, dynamic> requestData = {
      "SL_search": filters['SL_search'] ?? 1,
      "date_type": filters['date_type'] ?? "",
      "teams": filters['teams'] ?? "",
      "fromdate": filters['fromdate'] ?? "",
      "todate": filters['todate'] ?? "",
      "list": filters['list'] ?? "",
      "list2": filters['list2'] ?? "",
      "status": filters['status'] ?? "",
      "cname": filters['cname'] ?? "",
      "stud": filters['stud'] ?? "",
      "project": filters['project'] ?? "",
      "assigner": filters['assigner'] ?? "",
      "work_cat": filters['work_cat'] ?? "",
      "work_type": filters['work_type'] ?? "",
      "activity_status": filters['activity_status'] ?? "",
      "teamleader": filters['teamleader'] ?? "",
      "keyword": filters['keyword'] ?? "",
      "api_key": AppConfig.apiKey
    };

    return await apiClient.post('Webservices/api3.php?action=show_student_list', data: requestData);
  }

  // Student CRM
  static Future<Response> getStudentCRM(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=create_crm', data: requestData);
  }

  // Teacher CRM
  static Future<Response> getTeacherCRM(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=create_crm', data: requestData);
  }

  // Search Student CRM
  static Future<Response> searchStudent(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=search_in_crm', data: requestData);
  }

  // Search Teacher CRM
  static Future<Response> searchTeacher(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=search_in_crm', data: requestData);
  }

  // Get Student Task List
  static Future<Response> getTaskList(Map<String, dynamic> data) async {
    // Add API key to the request data
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    
    return await apiClient.post('Webservices/api3.php?action=student_task_list', data: requestData);
  }

  // Assign Task
  static Future<Response> assignTask(Map<String, dynamic> data) async {
    // Add API key to the request data
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    
    return await apiClient.post('Webservices/api3.php?action=Assign_Task', data: requestData);
  }

  // View Previous Task List
  static Future<Response> viewPreviousTasks(Map<String, dynamic> data) async {
    // Add API key to the request data
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    
    return await apiClient.post('Webservices/api3.php?action=assigned_task_list', data: requestData);
  }

  // Get All Tasks for Staff View (all student tasks)
  static Future<Response> getAllTasksForStaff(Map<String, dynamic> data) async {
    // Use the data passed from the task service instead of overriding it
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    
    // Use the new API endpoint for all student tasks
    return await apiClient.post('Webservices/api3.php?action=assigned_task_list_all_students', data: requestData);
  }

  // Get All Tasks for Staff View with custom date range
  static Future<Response> getAllTasksForStaffWithDateRange(DateTime fromDate, DateTime toDate) async {
    // Format dates for API
    final fromDateStr = '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';
    final toDateStr = '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}';
    
    // Prepare request data with custom date filtering
    Map<String, dynamic> requestData = {
      'from_date': fromDateStr,
      'to_date': toDateStr,
      'api_key': AppConfig.apiKey,
    };
    
    // Use the new API endpoint for all student tasks
    return await apiClient.post('Webservices/api3.php?action=assigned_task_list_all_students', data: requestData);
  }

  // Edit Profile
  static Future<Response> updateProfile(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=student_profile_update', data: requestData);
  }

  // Student Team Project Details
  static Future<Response> setStudentTeam(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=student_team_proj_details', data: requestData);
  }

  // Send OTP
  static Future<Response> sendOTP(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('api2/api2.php?action=send_otp', data: requestData);
  }

  // Verify OTP
  static Future<Response> verifyOTP(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('api2/api2.php?x=varify_otp', data: requestData);
  }

  // Forgot Password OTP
  static Future<Response> sendForgotPasswordOTP(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Version1/Forgot_password.php?x=send_otp', data: requestData);
  }

  // Verify Forgot Password OTP
  static Future<Response> verifyForgotPasswordOTP(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Version1/Forgot_password.php?x=varify_otp', data: requestData);
  }

  // Delete User Data
  static Future<Response> deleteUserData(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=delete_user_data', data: requestData);
  }

  // Quick Registration
  static Future<Response> quickRegistration(Map<String, dynamic> data) async {
    Map<String, dynamic> requestData = Map<String, dynamic>.from(data);
    requestData['api_key'] = AppConfig.apiKey;
    return await apiClient.post('Webservices/api3.php?action=quick_registration', data: requestData);
  }
} 