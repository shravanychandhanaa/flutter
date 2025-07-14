// lib/screens/teacher_crm_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:provider/provider.dart'; 

// Import the new email composer screen
import 'teacher_email_composer.dart'; 

// You'll likely need a Teacher model
class Teacher {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String department;
  final String status; 

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    required this.department,
    required this.status,
  });
}

// You'll also need a TeacherProvider for managing teacher data
class TeacherProvider with ChangeNotifier {
  List<Teacher> _teachers = [
    // Sample data
    Teacher(
      id: 'T001',
      name: 'Dr. Emily White',
      email: 'emily.white@example.com',
      phone: '+919876543210',
      subject: 'Physics',
      department: 'Science',
      status: 'Active',
    ),
    Teacher(
      id: 'T002',
      name: 'Mr. David Lee',
      email: 'david.lee@example.com',
      phone: '+919988776655',
      subject: 'Mathematics',
      department: 'Math',
      status: 'Active',
    ),
    Teacher(
      id: 'T003',
      name: 'Ms. Sarah Connor',
      email: 'sarah.connor@example.com',
      phone: '+917766554433',
      subject: 'English Literature',
      department: 'Humanities',
      status: 'On Leave',
    ),
    Teacher(
      id: 'T004',
      name: 'Dr. Arjun Singh',
      email: 'arjun.singh@example.com',
      phone: '+919000111222',
      subject: 'Computer Science',
      department: 'IT',
      status: 'Active',
    ),
    Teacher(
      id: 'T005',
      name: 'Mrs. Priya Sharma',
      email: 'priya.sharma@example.com',
      phone: '+918888877777',
      subject: 'Biology',
      department: 'Science',
      status: 'Active',
    ),
  ];

  List<Teacher> get teachers => _teachers;

  // You would add methods here for fetching, adding, editing, deleting teachers
}


class TeacherCrmScreen extends StatefulWidget {
  const TeacherCrmScreen({super.key});

  @override
  State<TeacherCrmScreen> createState() => _TeacherCrmScreenState();
}

class _TeacherCrmScreenState extends State<TeacherCrmScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Teacher> _filteredTeachers = [];

  @override
  void initState() {
    super.initState();
    _filteredTeachers = Provider.of<TeacherProvider>(context, listen: false).teachers;
    _searchController.addListener(_filterTeachers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTeachers);
    _searchController.dispose();
    super.dispose();
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeachers = Provider.of<TeacherProvider>(context, listen: false)
          .teachers
          .where((teacher) =>
              teacher.name.toLowerCase().contains(query) ||
              teacher.email.toLowerCase().contains(query) ||
              teacher.subject.toLowerCase().contains(query) ||
              teacher.department.toLowerCase().contains(query))
          .toList();
    });
  }

  // Function to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $phoneNumber')),
      );
    }
  }

  // UPDATED: This function now navigates to the new custom composer
  void _sendEmail(String emailAddress, String teacherName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherEmailComposer(
          recipientEmail: emailAddress,
          teacherName: teacherName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher CRM', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: Consumer<TeacherProvider>(
        builder: (context, teacherProvider, child) {
          if (_filteredTeachers.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(child: Text('No teachers found.'));
          } else if (_filteredTeachers.isEmpty && _searchController.text.isEmpty) {
            return const Center(child: Text('No teachers available.'));
          }
          return ListView.builder(
            itemCount: _filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = _filteredTeachers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Subject: ${teacher.subject}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Department: ${teacher.department}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Status: ${teacher.status}',
                        style: TextStyle(
                          fontSize: 16,
                          color: teacher.status == 'Active' ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () => _makePhoneCall(teacher.phone),
                            tooltip: 'Call ${teacher.name}',
                          ),
                          IconButton(
                            icon: const Icon(Icons.email, color: Colors.red),
                            // UPDATED: Call the new function with teacher data
                            onPressed: () => _sendEmail(teacher.email, teacher.name),
                            tooltip: 'Email ${teacher.name}',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit teacher functionality coming soon!')),
                              );
                            },
                            tooltip: 'Edit ${teacher.name}',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delete teacher functionality coming soon!')),
                              );
                            },
                            tooltip: 'Delete ${teacher.name}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add new teacher functionality coming soon!')),
          );
        },
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}