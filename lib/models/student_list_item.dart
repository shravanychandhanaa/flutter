class StudentListItem {
  final String? id;
  final String? assignDate;
  final String? stdMobile;
  final String? stdEmail;
  final String? uid;
  final String? curdate;
  final String? studentName;
  final String? collegeId;
  final String? college;
  final String? requestProject;
  final String? projectName;
  final String? projectCode;
  final String? staffName;
  final String? mentorName;
  final String? wcName;
  final String? wtName;
  final String? teamName;
  final String? teamLeader;
  final String? projectId;
  final String? collegeName;
  final String? applicationNumber;
  final String? state;
  final String? city;
  final String? pass;
  final String? userStatus;
  final String? hobbies;

  StudentListItem({
    this.id,
    this.assignDate,
    this.stdMobile,
    this.stdEmail,
    this.uid,
    this.curdate,
    this.studentName,
    this.collegeId,
    this.college,
    this.requestProject,
    this.projectName,
    this.projectCode,
    this.staffName,
    this.mentorName,
    this.wcName,
    this.wtName,
    this.teamName,
    this.teamLeader,
    this.projectId,
    this.collegeName,
    this.applicationNumber,
    this.state,
    this.city,
    this.pass,
    this.userStatus,
    this.hobbies,
  });

  factory StudentListItem.fromJson(Map<String, dynamic> json) {
    return StudentListItem(
      id: json['id']?.toString(),
      assignDate: json['assign_date'],
      stdMobile: json['std_mobile'],
      stdEmail: json['std_email'],
      uid: json['uid']?.toString(),
      curdate: json['curdate'],
      studentName: json['student_name'],
      collegeId: json['college_id'],
      college: json['college'],
      requestProject: json['request_project'],
      projectName: json['project_name'],
      projectCode: json['project_code'],
      staffName: json['staff_name'],
      mentorName: json['mentor_name'],
      wcName: json['wc_name'],
      wtName: json['wt_name'],
      teamName: json['team_name'],
      teamLeader: json['team_leader']?.toString(),
      projectId: json['project_id']?.toString(),
      collegeName: json['college_name'],
      applicationNumber: json['application_number'],
      state: json['state'],
      city: json['city'],
      pass: json['pass'],
      userStatus: json['user_status']?.toString(),
      hobbies: json['hobbies'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assign_date': assignDate,
      'std_mobile': stdMobile,
      'std_email': stdEmail,
      'uid': uid,
      'curdate': curdate,
      'student_name': studentName,
      'college_id': collegeId,
      'college': college,
      'request_project': requestProject,
      'project_name': projectName,
      'project_code': projectCode,
      'staff_name': staffName,
      'mentor_name': mentorName,
      'wc_name': wcName,
      'wt_name': wtName,
      'team_name': teamName,
      'team_leader': teamLeader,
      'project_id': projectId,
      'college_name': collegeName,
      'application_number': applicationNumber,
      'state': state,
      'city': city,
      'pass': pass,
      'user_status': userStatus,
      'hobbies': hobbies,
    };
  }

  // Helper methods
  bool get isActive => userStatus == "1";
  bool get isTeamLeader => teamLeader == "1";
  String get displayName => studentName ?? 'Unknown Student';
  String get displayEmail => stdEmail ?? 'No email';
  String get displayMobile => stdMobile ?? 'No mobile';
  String get displayCollege => collegeName ?? college ?? 'Unknown College';
  String get displayProject => projectName ?? 'No Project';
  String get displayTeam => teamName ?? 'No Team';
} 