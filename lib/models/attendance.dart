import 'user.dart';

enum AttendanceStatus { pending, approved, rejected }

class Attendance {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;
  final bool isPresent;
  final AttendanceStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final UserType userType; // To determine approval workflow

  Attendance({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.isPresent = false,
    this.status = AttendanceStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.userType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'notes': notes,
      'isPresent': isPresent,
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'userType': userType.name,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    AttendanceStatus status;
    try {
      status = AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.pending,
      );
    } catch (e) {
      status = AttendanceStatus.pending;
    }

    UserType userType;
    try {
      userType = UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.student,
      );
    } catch (e) {
      userType = UserType.student;
    }

    return Attendance(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'] ?? '',
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      notes: json['notes'],
      isPresent: json['isPresent'] ?? false,
      status: status,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectionReason: json['rejectionReason'],
      userType: userType,
    );
  }

  Attendance copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
    bool? isPresent,
    AttendanceStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    UserType? userType,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
      isPresent: isPresent ?? this.isPresent,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      userType: userType ?? this.userType,
    );
  }

  // Calculate total hours worked
  Duration? get totalHours {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!);
    }
    return null;
  }

  // Get formatted total hours
  String get formattedTotalHours {
    final hours = totalHours;
    if (hours == null) return 'Not checked out';
    
    final totalMinutes = hours.inMinutes;
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    
    if (h > 0) {
      return '${h}h ${m}m';
    } else {
      return '${m}m';
    }
  }

  // Check if currently checked in
  bool get isCheckedIn {
    return checkInTime != null && checkOutTime == null;
  }

  // Get formatted check-in time
  String get formattedCheckInTime {
    if (checkInTime == null) return 'Not checked in';
    return '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted check-out time
  String get formattedCheckOutTime {
    if (checkOutTime == null) return 'Not checked out';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }
} 