enum TaskStatus { assigned, inProgress, completed, open }

class Task {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedBy;
  final String team;
  final String project;
  final DateTime assignedDate;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? notes;
  final bool isOpenToTask;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? timeSpent;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedBy,
    required this.team,
    required this.project,
    required this.assignedDate,
    this.dueDate,
    required this.status,
    this.notes,
    this.isOpenToTask = false,
    this.startedAt,
    this.completedAt,
    this.timeSpent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'team': team,
      'project': project,
      'assignedDate': assignedDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status.toString(),
      'notes': notes,
      'isOpenToTask': isOpenToTask,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeSpent': timeSpent?.inMinutes,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assignedTo'],
      assignedBy: json['assignedBy'],
      team: json['team'],
      project: json['project'],
      assignedDate: DateTime.parse(json['assignedDate']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      notes: json['notes'],
      isOpenToTask: json['isOpenToTask'] ?? false,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      timeSpent: json['timeSpent'] != null ? Duration(minutes: json['timeSpent']) : null,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? assignedBy,
    String? team,
    String? project,
    DateTime? assignedDate,
    DateTime? dueDate,
    TaskStatus? status,
    String? notes,
    bool? isOpenToTask,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? timeSpent,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      team: team ?? this.team,
      project: project ?? this.project,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isOpenToTask: isOpenToTask ?? this.isOpenToTask,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  // Calculate current time spent if task is in progress
  Duration get currentTimeSpent {
    if (status == TaskStatus.inProgress && startedAt != null) {
      return DateTime.now().difference(startedAt!);
    }
    return timeSpent ?? Duration.zero;
  }

  // Get formatted time string
  String get formattedTimeSpent {
    final duration = currentTimeSpent;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
} 