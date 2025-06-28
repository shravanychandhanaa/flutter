class StudentRegistration {
  final String entity;
  final String fullName;
  final String? dob;
  final String gender;
  final String? address1;
  final String? address2;
  final String city;
  final String? state;
  final String? pincode;
  final String college;
  final String countryCode;
  final String mobile;
  final String email;
  final String pwd;
  final String confirmPwd;
  final String likeToBe;
  final String? hearAboutUs;
  final String? other;
  final String projectName;
  final String? workCategory;
  final String? workType;
  final String collegeId;
  final String? batch;
  final String? degree;
  final String? department;
  final String? year;
  final String? whoAreYou;
  final String? durationOfProjects;
  final String? hobby;
  final String? dbKnowledge;
  final String? technologies;
  final String? otherSoftware;
  final String? otherSkills;
  final String? companyName;
  final String? fromDate;
  final String? toDate;
  final String? roleDescription;
  final String? regSource;
  final String? userImage;
  final String? studentType;
  final String? msgid;
  final String? senderid;
  final String? name;
  final String? teamName;
  final String? teamLeaderName;
  final String? teamGuideName;
  final String? teamObjective;
  final String? teamId;
  final String? site;
  final String? email1;
  final String? projectName2;
  final String? ccmail;
  final String? mobile2;
  final String? smsid;
  final String? teamGuidePhone;
  final String? teamLeaderPhone;
  final String? teamLeaderEmail;
  final String? teamGuideEmail;

  StudentRegistration({
    this.entity = 'student',
    required this.fullName,
    this.dob,
    required this.gender,
    this.address1,
    this.address2,
    required this.city,
    this.state,
    this.pincode,
    required this.college,
    required this.countryCode,
    required this.mobile,
    required this.email,
    required this.pwd,
    required this.confirmPwd,
    required this.likeToBe,
    this.hearAboutUs,
    this.other,
    required this.projectName,
    this.workCategory,
    this.workType,
    required this.collegeId,
    this.batch,
    this.degree,
    this.department,
    this.year,
    this.whoAreYou,
    this.durationOfProjects,
    this.hobby,
    this.dbKnowledge,
    this.technologies,
    this.otherSoftware,
    this.otherSkills,
    this.companyName,
    this.fromDate,
    this.toDate,
    this.roleDescription,
    this.regSource,
    this.userImage,
    this.studentType,
    this.msgid,
    this.senderid,
    this.name,
    this.teamName,
    this.teamLeaderName,
    this.teamGuideName,
    this.teamObjective,
    this.teamId,
    this.site,
    this.email1,
    this.projectName2,
    this.ccmail,
    this.mobile2,
    this.smsid,
    this.teamGuidePhone,
    this.teamLeaderPhone,
    this.teamLeaderEmail,
    this.teamGuideEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'entity': entity,
      'full_name': fullName,
      'dob': dob,
      'gender': gender,
      'address1': address1,
      'address2': address2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'college': college,
      'country_code': countryCode,
      'mobile': mobile,
      'email': email,
      'pwd': pwd,
      'confirm_pwd': confirmPwd,
      'like_to_be': likeToBe,
      'hear_about_us': hearAboutUs,
      'other': other,
      'project_name': projectName,
      'work_category': workCategory,
      'work_type': workType,
      'college_id': collegeId,
      'batch': batch,
      'degree': degree,
      'department': department,
      'year': year,
      'who_are_you': whoAreYou,
      'duration_of_projects': durationOfProjects,
      'hobby': hobby,
      'db_knowledge': dbKnowledge,
      'technologies': technologies,
      'other_software': otherSoftware,
      'other_skills': otherSkills,
      'company_name': companyName,
      'from_date': fromDate,
      'to_date': toDate,
      'role_description': roleDescription,
      'reg_source': regSource,
      'user_image': userImage,
      'student_type': studentType,
      'msgid': msgid,
      'senderid': senderid,
      'Name': name,
      'Team_Name': teamName,
      'Team_Leader_Name': teamLeaderName,
      'Team_Guide_Name': teamGuideName,
      'Team_Objective': teamObjective,
      'Team_ID': teamId,
      'site': site,
      'email1': email1,
      'Project_Name': projectName2,
      'ccmail': ccmail,
      'mobile': mobile2,
      'smsid': smsid,
      'Team_Guide_Phone': teamGuidePhone,
      'Team_Leader_Phone': teamLeaderPhone,
      'team_leader_email': teamLeaderEmail,
      'team_guide_email': teamGuideEmail,
    };
  }
} 