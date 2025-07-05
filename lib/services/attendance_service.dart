import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendanceService {
  static const String _attendanceKey = 'attendance';
  static const String _pendingApprovalsKey = 'pending_approvals';
  final Uuid _uuid = const Uuid();

  // Check in a user
  Future<Map<String, dynamic>> checkIn(String userId, String userName, String userEmail, UserType userType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      // Check if already checked in today
      for (String attendanceJsonStr in attendanceJson) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJsonStr));
        if (attendance.userId == userId && 
            attendance.date.isAtSameMomentAs(todayDate) &&
            attendance.isCheckedIn) {
          return {
            'success': false,
            'message': 'Already checked in today',
          };
        }
      }

      // Create new attendance record
      final newAttendance = Attendance(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        date: todayDate,
        checkInTime: today,
        isPresent: true,
        status: AttendanceStatus.pending,
        userType: userType,
      );

      attendanceJson.add(jsonEncode(newAttendance.toJson()));
      await prefs.setStringList(_attendanceKey, attendanceJson);
      
      // Add to pending approvals
      await _addToPendingApprovals(newAttendance);
      
      // Log attendance to API for tracking
      try {
        await ApiService.logError({
          'type': 'attendance_checkin',
          'user_id': userId,
          'user_name': userName,
          'timestamp': today.toIso8601String(),
          'message': 'User checked in',
        });
      } catch (e) {
        print('Failed to log attendance to API: $e');
      }
      
      return {
        'success': true,
        'message': 'Check-in successful. Awaiting approval.',
        'attendance': newAttendance,
      };
    } catch (e) {
      print('Check-in error: $e');
      return {
        'success': false,
        'message': 'Check-in failed: $e',
      };
    }
  }

  // Check out a user
  Future<Map<String, dynamic>> checkOut(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      for (int i = 0; i < attendanceJson.length; i++) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJson[i]));
        if (attendance.userId == userId && 
            attendance.date.isAtSameMomentAs(todayDate) &&
            attendance.isCheckedIn) {
          
          // Update with check out time
          final updatedAttendance = attendance.copyWith(
            checkOutTime: today,
          );
          
          attendanceJson[i] = jsonEncode(updatedAttendance.toJson());
          await prefs.setStringList(_attendanceKey, attendanceJson);
          
          // Log attendance to API for tracking
          try {
            await ApiService.logError({
              'type': 'attendance_checkout',
              'user_id': userId,
              'timestamp': today.toIso8601String(),
              'message': 'User checked out',
              'total_hours': updatedAttendance.totalHours?.inMinutes ?? 0,
            });
          } catch (e) {
            print('Failed to log attendance to API: $e');
          }
          
          return {
            'success': true,
            'message': 'Check-out successful',
            'attendance': updatedAttendance,
          };
        }
      }
      
      return {
        'success': false,
        'message': 'No active check-in found',
      };
    } catch (e) {
      print('Check-out error: $e');
      return {
        'success': false,
        'message': 'Check-out failed: $e',
      };
    }
  }

  // Get today's attendance for a user
  Future<Attendance?> getTodayAttendance(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      for (String attendanceJsonStr in attendanceJson) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJsonStr));
        if (attendance.userId == userId && 
            attendance.date.isAtSameMomentAs(todayDate)) {
          return attendance;
        }
      }
      
      return null;
    } catch (e) {
      print('Get today attendance error: $e');
      return null;
    }
  }

  // Get all attendance records for a user
  Future<List<Attendance>> getUserAttendance(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      List<Attendance> userAttendance = [];
      
      for (String attendanceJsonStr in attendanceJson) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJsonStr));
        if (attendance.userId == userId) {
          if (startDate != null && attendance.date.isBefore(startDate)) continue;
          if (endDate != null && attendance.date.isAfter(endDate)) continue;
          userAttendance.add(attendance);
        }
      }
      
      // Sort by date (newest first)
      userAttendance.sort((a, b) => b.date.compareTo(a.date));
      return userAttendance;
    } catch (e) {
      print('Get user attendance error: $e');
      return [];
    }
  }

  // Get all attendance records (for staff)
  Future<List<Attendance>> getAllAttendance({DateTime? startDate, DateTime? endDate}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      List<Attendance> allAttendance = [];
      
      for (String attendanceJsonStr in attendanceJson) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJsonStr));
        if (startDate != null && attendance.date.isBefore(startDate)) continue;
        if (endDate != null && attendance.date.isAfter(endDate)) continue;
        allAttendance.add(attendance);
      }
      
      // Sort by date (newest first)
      allAttendance.sort((a, b) => b.date.compareTo(a.date));
      return allAttendance;
    } catch (e) {
      print('Get all attendance error: $e');
      return [];
    }
  }

  // Get attendance statistics for a user
  Future<Map<String, dynamic>> getUserAttendanceStats(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final attendance = await getUserAttendance(userId, startDate: startDate, endDate: endDate);
      
      int totalDays = attendance.length;
      int presentDays = attendance.where((a) => a.isPresent).length;
      int absentDays = totalDays - presentDays;
      
      Duration totalHours = Duration.zero;
      for (final record in attendance) {
        if (record.totalHours != null) {
          totalHours += record.totalHours!;
        }
      }
      
      return {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'attendanceRate': totalDays > 0 ? (presentDays / totalDays * 100).roundToDouble() : 0.0,
        'totalHours': totalHours,
        'averageHoursPerDay': totalDays > 0 ? totalHours.inMinutes / totalDays : 0,
      };
    } catch (e) {
      print('Get user attendance stats error: $e');
      return {
        'totalDays': 0,
        'presentDays': 0,
        'absentDays': 0,
        'attendanceRate': 0.0,
        'totalHours': Duration.zero,
        'averageHoursPerDay': 0,
      };
    }
  }

  // Get overall attendance statistics (for staff)
  Future<Map<String, dynamic>> getOverallAttendanceStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final attendance = await getAllAttendance(startDate: startDate, endDate: endDate);
      
      int totalRecords = attendance.length;
      int presentRecords = attendance.where((a) => a.isPresent).length;
      int absentRecords = totalRecords - presentRecords;
      
      Duration totalHours = Duration.zero;
      for (final record in attendance) {
        if (record.totalHours != null) {
          totalHours += record.totalHours!;
        }
      }
      
      // Get unique users
      final uniqueUsers = attendance.map((a) => a.userId).toSet().length;
      // Active students by attendance marked
      final activeStudentIds = attendance
        .where((a) => a.isPresent && a.userType == UserType.student)
        .map((a) => a.userId)
        .toSet();
      final activeStudentsByAttendanceMarked = activeStudentIds.length;
      
      return {
        'totalRecords': totalRecords,
        'presentRecords': presentRecords,
        'absentRecords': absentRecords,
        'overallAttendanceRate': totalRecords > 0 ? (presentRecords / totalRecords * 100).roundToDouble() : 0.0,
        'totalHours': totalHours,
        'uniqueUsers': uniqueUsers,
        'averageHoursPerRecord': totalRecords > 0 ? totalHours.inMinutes / totalRecords : 0,
        'activeStudentsByAttendanceMarked': activeStudentsByAttendanceMarked,
      };
    } catch (e) {
      print('Get overall attendance stats error: $e');
      return {
        'totalRecords': 0,
        'presentRecords': 0,
        'absentRecords': 0,
        'overallAttendanceRate': 0.0,
        'totalHours': Duration.zero,
        'uniqueUsers': 0,
        'averageHoursPerRecord': 0,
        'activeStudentsByAttendanceMarked': 0,
      };
    }
  }

  // Mark attendance manually (for staff)
  Future<Map<String, dynamic>> markAttendance(String userId, String userName, String userEmail, DateTime date, bool isPresent, UserType userType, {String? notes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      final targetDate = DateTime(date.year, date.month, date.day);
      
      // Check if attendance already exists for this date
      for (int i = 0; i < attendanceJson.length; i++) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJson[i]));
        if (attendance.userId == userId && 
            attendance.date.isAtSameMomentAs(targetDate)) {
          
          // Update existing record
          final updatedAttendance = attendance.copyWith(
            isPresent: isPresent,
            notes: notes,
            status: isPresent ? AttendanceStatus.pending : AttendanceStatus.approved,
          );
          
          attendanceJson[i] = jsonEncode(updatedAttendance.toJson());
          await prefs.setStringList(_attendanceKey, attendanceJson);
          
          // Add to pending approvals if marked as present
          if (isPresent) {
            await _addToPendingApprovals(updatedAttendance);
          }
          
          // Log to API
          try {
            await ApiService.logError({
              'type': 'attendance_manual',
              'user_id': userId,
              'user_name': userName,
              'date': targetDate.toIso8601String(),
              'is_present': isPresent,
              'notes': notes ?? '',
              'message': 'Manual attendance marked',
            });
          } catch (e) {
            print('Failed to log attendance to API: $e');
          }
          
          return {
            'success': true,
            'message': isPresent ? 'Attendance marked as present. Awaiting approval.' : 'Attendance marked as absent.',
            'attendance': updatedAttendance,
          };
        }
      }
      
      // Create new record
      final newAttendance = Attendance(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        date: targetDate,
        isPresent: isPresent,
        notes: notes,
        status: isPresent ? AttendanceStatus.pending : AttendanceStatus.approved,
        userType: userType,
      );

      attendanceJson.add(jsonEncode(newAttendance.toJson()));
      await prefs.setStringList(_attendanceKey, attendanceJson);
      
      // Add to pending approvals if marked as present
      if (isPresent) {
        await _addToPendingApprovals(newAttendance);
      }
      
      // Log to API
      try {
        await ApiService.logError({
          'type': 'attendance_manual',
          'user_id': userId,
          'user_name': userName,
          'date': targetDate.toIso8601String(),
          'is_present': isPresent,
          'notes': notes ?? '',
          'message': 'Manual attendance created',
        });
      } catch (e) {
        print('Failed to log attendance to API: $e');
      }
      
      return {
        'success': true,
        'message': isPresent ? 'Attendance marked as present. Awaiting approval.' : 'Attendance marked as absent.',
        'attendance': newAttendance,
      };
    } catch (e) {
      print('Mark attendance error: $e');
      return {
        'success': false,
        'message': 'Failed to mark attendance: $e',
      };
    }
  }

  // Export attendance data to API
  Future<Map<String, dynamic>> exportAttendanceData() async {
    try {
      final allAttendance = await getAllAttendance();
      final attendanceData = allAttendance.map((a) => a.toJson()).toList();
      
      final response = await ApiService.logError({
        'type': 'attendance_export',
        'data': attendanceData,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Attendance data export',
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Attendance data exported successfully',
          'recordCount': attendanceData.length,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to export attendance data',
        };
      }
    } catch (e) {
      print('Export attendance data error: $e');
      return {
        'success': false,
        'message': 'Failed to export attendance data: $e',
      };
    }
  }

  // Mark attendance as present (requires approval)
  Future<Map<String, dynamic>> markAttendancePresent(String userId, String userName, String userEmail, UserType userType, {String? notes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      // Check if attendance already exists for today
      for (int i = 0; i < attendanceJson.length; i++) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJson[i]));
        if (attendance.userId == userId && 
            attendance.date.isAtSameMomentAs(todayDate)) {
          
          // Update existing record
          final updatedAttendance = attendance.copyWith(
            isPresent: true,
            notes: notes,
            status: AttendanceStatus.pending,
          );
          
          attendanceJson[i] = jsonEncode(updatedAttendance.toJson());
          await prefs.setStringList(_attendanceKey, attendanceJson);
          
          // Add to pending approvals
          await _addToPendingApprovals(updatedAttendance);
          
          return {
            'success': true,
            'message': 'Attendance marked as present. Awaiting approval.',
            'attendance': updatedAttendance,
          };
        }
      }
      
      // Create new attendance record
      final newAttendance = Attendance(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        date: todayDate,
        isPresent: true,
        notes: notes,
        status: AttendanceStatus.pending,
        userType: userType,
      );

      attendanceJson.add(jsonEncode(newAttendance.toJson()));
      await prefs.setStringList(_attendanceKey, attendanceJson);
      
      // Add to pending approvals
      await _addToPendingApprovals(newAttendance);
      
      return {
        'success': true,
        'message': 'Attendance marked as present. Awaiting approval.',
        'attendance': newAttendance,
      };
    } catch (e) {
      print('Mark attendance present error: $e');
      return {
        'success': false,
        'message': 'Failed to mark attendance: $e',
      };
    }
  }

  // Add attendance to pending approvals list
  Future<void> _addToPendingApprovals(Attendance attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList(_pendingApprovalsKey) ?? [];
      
      // Check if already in pending list
      bool alreadyExists = false;
      for (String pendingStr in pendingJson) {
        final pending = Attendance.fromJson(jsonDecode(pendingStr));
        if (pending.id == attendance.id) {
          alreadyExists = true;
          break;
        }
      }
      
      if (!alreadyExists) {
        pendingJson.add(jsonEncode(attendance.toJson()));
        await prefs.setStringList(_pendingApprovalsKey, pendingJson);
      }
    } catch (e) {
      print('Add to pending approvals error: $e');
    }
  }

  // Get pending approvals for staff (student attendance)
  Future<List<Attendance>> getPendingStudentApprovals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList(_pendingApprovalsKey) ?? [];
      
      List<Attendance> pendingApprovals = [];
      
      for (String pendingStr in pendingJson) {
        final attendance = Attendance.fromJson(jsonDecode(pendingStr));
        if (attendance.userType == UserType.student && 
            attendance.status == AttendanceStatus.pending) {
          pendingApprovals.add(attendance);
        }
      }
      
      // Sort by date (newest first)
      pendingApprovals.sort((a, b) => b.date.compareTo(a.date));
      return pendingApprovals;
    } catch (e) {
      print('Get pending student approvals error: $e');
      return [];
    }
  }

  // Get pending approvals for admin (staff attendance)
  Future<List<Attendance>> getPendingStaffApprovals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList(_pendingApprovalsKey) ?? [];
      
      List<Attendance> pendingApprovals = [];
      
      for (String pendingStr in pendingJson) {
        final attendance = Attendance.fromJson(jsonDecode(pendingStr));
        if (attendance.userType == UserType.staff && 
            attendance.status == AttendanceStatus.pending) {
          pendingApprovals.add(attendance);
        }
      }
      
      // Sort by date (newest first)
      pendingApprovals.sort((a, b) => b.date.compareTo(a.date));
      return pendingApprovals;
    } catch (e) {
      print('Get pending staff approvals error: $e');
      return [];
    }
  }

  // Approve attendance
  Future<Map<String, dynamic>> approveAttendance(String attendanceId, String approvedBy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      final pendingJson = prefs.getStringList(_pendingApprovalsKey) ?? [];
      
      // Update main attendance record
      for (int i = 0; i < attendanceJson.length; i++) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJson[i]));
        if (attendance.id == attendanceId) {
          final updatedAttendance = attendance.copyWith(
            status: AttendanceStatus.approved,
            approvedBy: approvedBy,
            approvedAt: DateTime.now(),
          );
          
          attendanceJson[i] = jsonEncode(updatedAttendance.toJson());
          await prefs.setStringList(_attendanceKey, attendanceJson);
          
          // Remove from pending approvals
          await _removeFromPendingApprovals(attendanceId);
          
          // Send email notification if userEmail is available
          if (attendance.userEmail.isNotEmpty) {
            await sendAttendanceEmailNotification(
              userName: attendance.userName,
              userEmail: attendance.userEmail,
              date: attendance.date,
              isApproved: true,
              actionBy: approvedBy,
              notes: attendance.notes,
            );
          }
          
          return {
            'success': true,
            'message': 'Attendance approved successfully',
            'attendance': updatedAttendance,
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Attendance record not found',
      };
    } catch (e) {
      print('Approve attendance error: $e');
      return {
        'success': false,
        'message': 'Failed to approve attendance: $e',
      };
    }
  }

  // Reject attendance
  Future<Map<String, dynamic>> rejectAttendance(String attendanceId, String rejectedBy, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attendanceJson = prefs.getStringList(_attendanceKey) ?? [];
      
      // Update main attendance record
      for (int i = 0; i < attendanceJson.length; i++) {
        final attendance = Attendance.fromJson(jsonDecode(attendanceJson[i]));
        if (attendance.id == attendanceId) {
          final updatedAttendance = attendance.copyWith(
            status: AttendanceStatus.rejected,
            approvedBy: rejectedBy,
            approvedAt: DateTime.now(),
            rejectionReason: reason,
            isPresent: false,
          );
          
          attendanceJson[i] = jsonEncode(updatedAttendance.toJson());
          await prefs.setStringList(_attendanceKey, attendanceJson);
          
          // Remove from pending approvals
          await _removeFromPendingApprovals(attendanceId);
          
          // Send email notification if userEmail is available
          if (attendance.userEmail.isNotEmpty) {
            await sendAttendanceEmailNotification(
              userName: attendance.userName,
              userEmail: attendance.userEmail,
              date: attendance.date,
              isApproved: false,
              actionBy: rejectedBy,
              rejectionReason: reason,
            );
          }
          
          return {
            'success': true,
            'message': 'Attendance rejected successfully',
            'attendance': updatedAttendance,
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Attendance record not found',
      };
    } catch (e) {
      print('Reject attendance error: $e');
      return {
        'success': false,
        'message': 'Failed to reject attendance: $e',
      };
    }
  }

  // Remove from pending approvals
  Future<void> _removeFromPendingApprovals(String attendanceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList(_pendingApprovalsKey) ?? [];
      
      pendingJson.removeWhere((pendingStr) {
        final attendance = Attendance.fromJson(jsonDecode(pendingStr));
        return attendance.id == attendanceId;
      });
      
      await prefs.setStringList(_pendingApprovalsKey, pendingJson);
    } catch (e) {
      print('Remove from pending approvals error: $e');
    }
  }

  // Send email notification for attendance status change
  Future<void> sendAttendanceEmailNotification({
    required String userName,
    required String userEmail,
    required DateTime date,
    required bool isApproved,
    required String actionBy,
    String? rejectionReason,
    String? notes,
  }) async {
    try {
      final subject = isApproved 
          ? 'Attendance Approved - ${DateFormat('MMM dd, yyyy').format(date)}'
          : 'Attendance Rejected - ${DateFormat('MMM dd, yyyy').format(date)}';
      
      final status = isApproved ? 'APPROVED' : 'REJECTED';
      
      String body = '''
Dear $userName,

Your attendance for ${DateFormat('EEEE, MMMM d, yyyy').format(date)} has been $status.

Details:
- Date: ${DateFormat('EEEE, MMMM d, yyyy').format(date)}
- Status: $status
- Action By: $actionBy
- Action Date: ${DateFormat('MMM dd, yyyy at HH:mm').format(DateTime.now())}
''';

      if (notes?.isNotEmpty == true) {
        body += '- Notes: $notes\n';
      }
      
      if (!isApproved && rejectionReason?.isNotEmpty == true) {
        body += '- Rejection Reason: $rejectionReason\n';
      }
      
      body += '''

If you have any questions, please contact your supervisor.

Best regards,
StartupWorld Team
''';

      // Create email URI
      final emailUri = Uri(
        scheme: 'mailto',
        path: userEmail,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      // Launch email client
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        print('Could not launch email client');
      }
    } catch (e) {
      print('Send email notification error: $e');
    }
  }
} 