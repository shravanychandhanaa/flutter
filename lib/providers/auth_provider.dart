import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

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
        
        print('✅ Auto-login successful: ${user.name}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Auto-login error: $e');
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Registering user: $name ($email) as ${userType.name}');
      
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        userType: userType,
        team: team,
        project: project,
        collegeId: collegeId,
        phone: phone,
      );

      print('Registration result: $result');

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
      print('AuthProvider registration error: $e');
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
        
        print('✅ Login successful: ${_currentUser?.name}');
      } else {
        _errorMessage = result['message'];
        print('❌ Login failed: $_errorMessage');
      }

      _isLoading = false;
      notifyListeners();
      return result['success'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed: $e';
      print('❌ Login error: $e');
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
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
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
      print('❌ Get session data error: $e');
      return null;
    }
  }

  // Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      return await _authService.isRememberMeEnabled();
    } catch (e) {
      print('❌ Check remember me error: $e');
      return false;
    }
  }

  // Get all users (for staff)
  Future<List<User>> getAllUsers() async {
    try {
      return await _authService.getAllUsers();
    } catch (e) {
      print('AuthProvider getAllUsers error: $e');
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
      print('AuthProvider validateCollegeId error: $e');
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
      print('AuthProvider sendOTP error: $e');
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
      print('AuthProvider verifyOTP error: $e');
      _errorMessage = 'Failed to verify OTP: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 