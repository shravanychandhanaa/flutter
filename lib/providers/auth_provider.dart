import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/college.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _sessionData;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get sessionData => _sessionData;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize auth state
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        
        // Get session data if available
        await getSessionData();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
    String? team,
    String? project,
    String? collegeId,
    String? phone,
    // Additional student registration fields
    String? dob,
    String? gender,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? pincode,
    String? college,
    String? countryCode,
    String? mobile,
    String? likeToBe,
    String? hearAboutUs,
    String? other,
    String? workCategory,
    String? workType,
    String? batch,
    String? degree,
    String? department,
    String? year,
    String? whoAreYou,
    String? durationOfProjects,
    String? hobby,
    String? dbKnowledge,
    String? technologies,
    String? otherSoftware,
    String? otherSkills,
    String? companyName,
    String? fromDate,
    String? toDate,
    String? roleDescription,
    String? regSource,
    String? userImage,
    String? studentType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        userType: userType,
        team: team,
        project: project,
        collegeId: collegeId,
        phone: phone,
        // Student registration fields
        dob: dob,
        gender: gender,
        address1: address1,
        address2: address2,
        city: city,
        state: state,
        pincode: pincode,
        college: college,
        countryCode: countryCode,
        mobile: mobile,
        likeToBe: likeToBe,
        hearAboutUs: hearAboutUs,
        other: other,
        workCategory: workCategory,
        workType: workType,
        batch: batch,
        degree: degree,
        department: department,
        year: year,
        whoAreYou: whoAreYou,
        durationOfProjects: durationOfProjects,
        hobby: hobby,
        dbKnowledge: dbKnowledge,
        technologies: technologies,
        otherSoftware: otherSoftware,
        otherSkills: otherSkills,
        companyName: companyName,
        fromDate: fromDate,
        toDate: toDate,
        roleDescription: roleDescription,
        regSource: regSource,
        userImage: userImage,
        studentType: studentType,
      );

      if (result['success'] == true) {
        _currentUser = result['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
    required UserType userType,
    bool rememberMe = false,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.login(
        email: email,
        password: password,
        userType: userType,
        rememberMe: rememberMe,
      );

      if (result['success']) {
        _currentUser = result['user'];
        _isLoggedIn = true;
        _errorMessage = null;
        
        // Store session data if available
        if (result['sessionData'] != null) {
          _sessionData = result['sessionData'];
        }
      } else {
        _errorMessage = result['message'];
      }

      _isLoading = false;
      notifyListeners();
      return result['success'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      _errorMessage = null;
      _sessionData = null;
      notifyListeners();
    } catch (e) {
      // Handle logout error silently
    }
  }

  // Get session data
  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final sessionData = await _authService.getSessionData();
      _sessionData = sessionData;
      notifyListeners();
      return sessionData;
    } catch (e) {
      return null;
    }
  }

  // Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      return await _authService.isRememberMeEnabled();
    } catch (e) {
      return false;
    }
  }

  // Get all users (for staff)
  Future<List<User>> getAllUsers() async {
    try {
      return await _authService.getAllUsers();
    } catch (e) {
      _errorMessage = 'Failed to get users: $e';
      notifyListeners();
      return [];
    }
  }

  // Validate college ID
  Future<bool> validateCollegeId(String collegeId) async {
    try {
      return await _authService.validateCollegeId(collegeId);
    } catch (e) {
      return false;
    }
  }

  // Send OTP
  Future<bool> sendOTP(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.sendOTP(email);
      
      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to send OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to send OTP: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOTP(email, otp);
      
      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Invalid OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to verify OTP: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get all colleges
  Future<List<College>> getAllColleges() async {
    try {
      return await _authService.getAllColleges();
    } catch (e) {
      _errorMessage = 'Failed to get colleges: $e';
      notifyListeners();
      return [];
    }
  }

  // Quick Registration
  Future<Map<String, dynamic>> quickRegistration({
    required String fullName,
    required String collegeId,
    required String gender,
    required String countryCode,
    required String mobile,
    required String email,
    required String projectName,
    required String workCategory,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.quickRegistration(
        fullName: fullName,
        collegeId: collegeId,
        gender: gender,
        countryCode: countryCode,
        mobile: mobile,
        email: email,
        projectName: projectName,
        workCategory: workCategory,
      );

      if (result['success'] == true) {
        _currentUser = result['user'];
        _isLoading = false;
        notifyListeners();
        return result;
      } else {
        _errorMessage = result['message'] ?? 'Quick registration failed';
        _isLoading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _errorMessage = 'Quick registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Quick registration failed: $e',
      };
    }
  }
} 