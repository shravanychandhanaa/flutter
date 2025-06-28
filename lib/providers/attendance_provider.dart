import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  Attendance? _todayAttendance;
  List<Attendance> _userAttendance = [];
  List<Attendance> _allAttendance = [];
  List<Attendance> _pendingStudentApprovals = [];
  List<Attendance> _pendingStaffApprovals = [];
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _overallStats;
  bool _isLoading = false;
  String? _errorMessage;

  Attendance? get todayAttendance => _todayAttendance;
  List<Attendance> get userAttendance => _userAttendance;
  List<Attendance> get allAttendance => _allAttendance;
  List<Attendance> get pendingStudentApprovals => _pendingStudentApprovals;
  List<Attendance> get pendingStaffApprovals => _pendingStaffApprovals;
  Map<String, dynamic>? get userStats => _userStats;
  Map<String, dynamic>? get overallStats => _overallStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
        _todayAttendance = result['attendance'];
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
        _todayAttendance = result['attendance'];
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
        _todayAttendance = result['attendance'];
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

  // Load today's attendance for a user
  Future<void> loadTodayAttendance(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todayAttendance = await _attendanceService.getTodayAttendance(userId);
    } catch (e) {
      _errorMessage = 'Failed to load today\'s attendance: $e';
      print('AttendanceProvider loadTodayAttendance error: $e');
    }

    _isLoading = false;
    notifyListeners();
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
    return _todayAttendance?.isCheckedIn ?? false;
  }

  // Get formatted current time if checked in
  String get currentTimeDisplay {
    if (!isCheckedIn) return '';
    
    final checkInTime = _todayAttendance?.checkInTime;
    if (checkInTime == null) return '';
    
    final now = DateTime.now();
    final duration = now.difference(checkInTime);
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
} 