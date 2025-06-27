class Attendance {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;
  final bool isPresent;

  Attendance({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.isPresent = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'notes': notes,
      'isPresent': isPresent,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      notes: json['notes'],
      isPresent: json['isPresent'] ?? false,
    );
  }

  Attendance copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
    bool? isPresent,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
      isPresent: isPresent ?? this.isPresent,
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