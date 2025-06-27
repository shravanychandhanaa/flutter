import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import 'api_service.dart';

class AttendanceService {
  static const String _attendanceKey = 'attendance';
  final Uuid _uuid = const Uuid();

  // Check in a user
  Future<Map<String, dynamic>> checkIn(String userId, String userName) async {
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
        date: todayDate,
        checkInTime: today,
        isPresent: true,
      );

      attendanceJson.add(jsonEncode(newAttendance.toJson()));
      await prefs.setStringList(_attendanceKey, attendanceJson);
      
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
        'message': 'Check-in successful',
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
      
      return {
        'totalRecords': totalRecords,
        'presentRecords': presentRecords,
        'absentRecords': absentRecords,
        'overallAttendanceRate': totalRecords > 0 ? (presentRecords / totalRecords * 100).roundToDouble() : 0.0,
        'totalHours': totalHours,
        'uniqueUsers': uniqueUsers,
        'averageHoursPerRecord': totalRecords > 0 ? totalHours.inMinutes / totalRecords : 0,
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
      };
    }
  }

  // Mark attendance manually (for staff)
  Future<Map<String, dynamic>> markAttendance(String userId, String userName, DateTime date, bool isPresent, {String? notes}) async {
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
          );
          
          attendanceJson[i] = jsonEncode(updatedAttendance.toJson());
          await prefs.setStringList(_attendanceKey, attendanceJson);
          
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
            'message': 'Attendance updated successfully',
            'attendance': updatedAttendance,
          };
        }
      }
      
      // Create new record
      final newAttendance = Attendance(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        date: targetDate,
        isPresent: isPresent,
        notes: notes,
      );

      attendanceJson.add(jsonEncode(newAttendance.toJson()));
      await prefs.setStringList(_attendanceKey, attendanceJson);
      
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
        'message': 'Attendance marked successfully',
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
} 