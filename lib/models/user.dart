enum UserType { student, staff }

class User {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final String? team;
  final String? project;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.team,
    this.project,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType.name,
      'team': team,
      'project': project,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    UserType userType;
    try {
      // Try to parse the userType from the JSON
      final userTypeString = json['userType'] as String? ?? 'student';
      if (userTypeString.contains('.')) {
        // Handle toString() format: "UserType.student"
        final enumName = userTypeString.split('.').last;
        userType = UserType.values.firstWhere(
          (e) => e.name == enumName,
          orElse: () => UserType.student, // Default fallback
        );
      } else {
        // Handle name format: "student"
        userType = UserType.values.firstWhere(
          (e) => e.name == userTypeString,
          orElse: () => UserType.student, // Default fallback
        );
      }
    } catch (e) {
      print('Error parsing UserType: ${json['userType']}, defaulting to student');
      userType = UserType.student; // Default fallback
    }

    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: userType,
      team: json['team'],
      project: json['project'],
    );
  }
} 