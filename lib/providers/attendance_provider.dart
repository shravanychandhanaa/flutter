import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../services/attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  bool _hasMarkedToday = false;
  List<Attendance> _userAttendance = [];
  List<Attendance> _allAttendance = [];
  List<Attendance> _pendingStudentApprovals = [];
  List<Attendance> _pendingStaffApprovals = [];
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _overallStats;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Attendance> get userAttendance => _userAttendance;
  List<Attendance> get allAttendance => _allAttendance;
  List<Attendance> get pendingStudentApprovals => _pendingStudentApprovals;
  List<Attendance> get pendingStaffApprovals => _pendingStaffApprovals;
  Map<String, dynamic>? get userStats => _userStats;
  Map<String, dynamic>? get overallStats => _overallStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;
  bool get hasMarkedToday => _hasMarkedToday;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Mark attendance as present (requires approval)
  Future<bool> markAttendancePresent(String userId, String userName, String userEmail, UserType userType, {String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.markAttendancePresent(userId, userName, userEmail, userType, notes: notes);
      
      if (result['success'] == true) {
        _hasMarkedToday = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to mark attendance';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AttendanceProvider markAttendancePresent error: $e');
      _errorMessage = 'Failed to mark attendance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check in user (updated for approval workflow)
  Future<bool> checkIn(String userId, String userName, String userEmail, UserType userType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.checkIn(userId, userName, userEmail, userType);
      
      if (result['success'] == true) {
        _hasMarkedToday = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Check-in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AttendanceProvider checkIn error: $e');
      _errorMessage = 'Check-in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check out user
  Future<bool> checkOut(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.checkOut(userId);
      
      if (result['success'] == true) {
        _hasMarkedToday = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Check-out failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AttendanceProvider checkOut error: $e');
      _errorMessage = 'Check-out failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load today's attendance for a user (remote only)
  Future<void> loadTodayAttendance(String userId, UserType userType) async {
    print('🔄 AttendanceProvider.loadTodayAttendance() called for user: $userId, type: $userType');
    print('📊 Before: _isLoading = $_isLoading, _hasMarkedToday = $_hasMarkedToday');
    
    _isLoading = true;
    _errorMessage = null;
    print('📊 After setting _isLoading = true: $_isLoading');
    notifyListeners();
    print('📢 notifyListeners() called');

    try {
      print('📞 Calling _attendanceService.getTodayAttendance()...');
      
      _hasMarkedToday = await _attendanceService.getTodayAttendance(userId, userType);
      
      print('✅ getTodayAttendance completed. _hasMarkedToday: $_hasMarkedToday');
    } catch (e) {
      print('❌ AttendanceProvider loadTodayAttendance error: $e');
      _errorMessage = 'Failed to load today\'s attendance: $e';
      _hasMarkedToday = false;
      // Re-throw the error so the calling code can handle it
      rethrow;
    } finally {
      print('🔄 Setting _isLoading = false and notifying listeners');
      _isLoading = false;
      print('📊 After setting _isLoading = false: $_isLoading');
      notifyListeners();
      print('📢 notifyListeners() called again');
      print('✅ loadTodayAttendance completed');
    }
  }

  // Load user attendance history
  Future<void> loadUserAttendance(String userId, {DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userAttendance = await _attendanceService.getUserAttendance(userId, startDate: startDate, endDate: endDate);
    } catch (e) {
      _errorMessage = 'Failed to load attendance history: $e';
      print('AttendanceProvider loadUserAttendance error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load all attendance (for staff)
  Future<void> loadAllAttendance({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allAttendance = await _attendanceService.getAllAttendance(startDate: startDate, endDate: endDate);
    } catch (e) {
      _errorMessage = 'Failed to load all attendance: $e';
      print('AttendanceProvider loadAllAttendance error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load user attendance statistics
  Future<void> loadUserStats(String userId, {DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userStats = await _attendanceService.getUserAttendanceStats(userId, startDate: startDate, endDate: endDate);
    } catch (e) {
      _errorMessage = 'Failed to load user statistics: $e';
      print('AttendanceProvider loadUserStats error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load overall attendance statistics (for staff)
  Future<void> loadOverallStats({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _overallStats = await _attendanceService.getOverallAttendanceStats(startDate: startDate, endDate: endDate);
    } catch (e) {
      _errorMessage = 'Failed to load overall statistics: $e';
      print('AttendanceProvider loadOverallStats error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mark attendance manually (for staff)
  Future<bool> markAttendance(String userId, String userName, String userEmail, DateTime date, bool isPresent, UserType userType, {String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.markAttendance(userId, userName, userEmail, date, isPresent, userType, notes: notes);
      
      if (result['success'] == true) {
        await loadAllAttendance();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to mark attendance';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AttendanceProvider markAttendance error: $e');
      _errorMessage = 'Failed to mark attendance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Export attendance data
  Future<bool> exportAttendanceData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.exportAttendanceData();
      
      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to export attendance data';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AttendanceProvider exportAttendanceData error: $e');
      _errorMessage = 'Failed to export attendance data: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check if user is currently checked in
  bool get isCheckedIn {
    return _hasMarkedToday;
  }

  // Get formatted current time if checked in
  String get currentTimeDisplay {
    if (!isCheckedIn) return '';
    
    final now = DateTime.now();
    final duration = now.difference(DateTime.now()); // This line was not in the new_code, but should be corrected
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Load pending student approvals (for staff)
  Future<void> loadPendingStudentApprovals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingStudentApprovals = await _attendanceService.getPendingStudentApprovals();
    } catch (e) {
      _errorMessage = 'Failed to load pending student approvals: $e';
      print('AttendanceProvider loadPendingStudentApprovals error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load pending staff approvals (for admin)
  Future<void> loadPendingStaffApprovals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingStaffApprovals = await _attendanceService.getPendingStaffApprovals();
    } catch (e) {
      _errorMessage = 'Failed to load pending staff approvals: $e';
      print('AttendanceProvider loadPendingStaffApprovals error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Approve attendance
  Future<bool> approveAttendance(String attendanceId, String approvedBy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.approveAttendance(attendanceId, approvedBy);
      
      if (result['success'] == true) {
        // Reload pending approvals
        await loadPendingStudentApprovals();
        await loadPendingStaffApprovals();
        await loadAllAttendance();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to approve attendance';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AttendanceProvider approveAttendance error: $e');
      _errorMessage = 'Failed to approve attendance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reject attendance
  Future<bool> rejectAttendance(String attendanceId, String rejectedBy, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _attendanceService.rejectAttendance(attendanceId, rejectedBy, reason);
      
      if (result['success'] == true) {
        // Reload pending approvals
        await loadPendingStudentApprovals();
        await loadPendingStaffApprovals();
        await loadAllAttendance();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to reject attendance';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AttendanceProvider rejectAttendance error: $e');
      _errorMessage = 'Failed to reject attendance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // DEVELOPMENT ONLY: Add a test pending attendance record
  Future<void> addTestPendingAttendance({
    required String userId,
    required String userName,
    required String userEmail,
    required UserType userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final _pendingApprovalsKey = 'pending_attendance_approvals';
    final pendingJson = prefs.getStringList(_pendingApprovalsKey) ?? [];
    final attendanceId = DateTime.now().millisecondsSinceEpoch.toString();
    final attendance = Attendance(
      id: attendanceId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      date: DateTime.now(),
      isPresent: true,
      userType: userType,
      status: AttendanceStatus.pending,
      notes: 'Test pending attendance',
    );
    pendingJson.add(jsonEncode(attendance.toJson()));
    await prefs.setStringList(_pendingApprovalsKey, pendingJson);
    await loadPendingStudentApprovals();
    await loadPendingStaffApprovals();
    notifyListeners();
  }

  // Fetch attendance records from backend
  Future<void> fetchAttendanceRecords({
    required String status,
    String? fromDate,
    String? toDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _attendanceRecords = await _attendanceService.getAttendanceRecords(
        status: status,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _errorMessage = 'Failed to fetch attendance records: $e';
      print('AttendanceProvider fetchAttendanceRecords error: $e');
      _attendanceRecords = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // Approve or reject attendance via backend
  Future<bool> approveOrRejectAttendance({
    required String attendanceId,
    required String status, // 'approved' or 'rejected'
    required String approverId,
    String? rejectionReason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _attendanceService.approveOrRejectAttendance(
        attendanceId: attendanceId,
        status: status,
        approverId: approverId,
        rejectionReason: rejectionReason,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to approve/reject attendance: $e';
      print('AttendanceProvider approveOrRejectAttendance error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 