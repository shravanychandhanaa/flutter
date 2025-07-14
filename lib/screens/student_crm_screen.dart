// lib/screens/student_crm_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'student_email_composer.dart'; // ADD THIS LINE

class StudentCrmScreen extends StatefulWidget {
  const StudentCrmScreen({super.key});

  @override
  State<StudentCrmScreen> createState() => _StudentCrmScreenState();
}

class Student {
  String id;
  String name;
  String email;
  String phone;
  String course;
  String status;
  String notes;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.course,
    required this.status,
    this.notes = '',
  });

  // Helper to create a copy for editing
  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? course,
    String? status,
    String? notes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      course: course ?? this.course,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class _StudentCrmScreenState extends State<StudentCrmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCourse;
  String? _selectedStatus;
  Student? _editingStudent; // Null if adding, not null if editing

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];

  final List<String> _courses = [
    'B.Tech - Computer Science',
    'B.Tech - Electronics',
    'B.Com - Accounting',
    'BBA - Marketing',
    'MBA - Finance',
    'M.Sc - Physics',
    'MBBS',
    'B.Arch',
    'B.Pharm',
  ];

  final List<String> _statuses = [
    'New Lead',
    'Contacted',
    'Interested',
    'Applied',
    'Admitted',
    'Enrolled',
    'Rejected',
    'Dormant',
  ];

  @override
  void initState() {
    super.initState();
    _initializeStudents();
    _filterStudents();
    _searchController.addListener(_filterStudents);
  }

  void _initializeStudents() {
    // Simulate some initial student data
    _allStudents = [
      Student(id: 'S001', name: 'Alok Singh', email: 'alok.s@example.com', phone: '9876543210', course: 'B.Tech - Computer Science', status: 'Enrolled', notes: 'Excellent academic record.'),
      Student(id: 'S002', name: 'Priya Sharma', email: 'priya.s@example.com', phone: '8765432109', course: 'MBA - Finance', status: 'Applied', notes: 'Follow up for GMAT scores.'),
      Student(id: 'S003', name: 'Rahul Kumar', email: 'rahul.k@example.com', phone: '7654321098', course: 'B.Com - Accounting', status: 'New Lead', notes: 'Sent brochure via email.'),
      Student(id: 'S004', name: 'Anjali Desai', email: 'anjali.d@example.com', phone: '9988776655', course: 'B.Arch', status: 'Interested', notes: 'Attended webinar on architecture design.'),
      Student(id: 'S005', name: 'Siddharth Jain', email: 'siddharth.j@example.com', phone: '9123456789', course: 'MBBS', status: 'Admitted', notes: 'Awaiting final fee payment.'),
    ];
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final searchText = _searchController.text.toLowerCase();
        return student.name.toLowerCase().contains(searchText) ||
               student.email.toLowerCase().contains(searchText) ||
               student.phone.toLowerCase().contains(searchText);
      }).toList();
    });
  }

  void _addOrUpdateStudent() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_editingStudent == null) {
          // Add new student
          final newStudent = Student(
            id: 'S${(_allStudents.length + 1).toString().padLeft(3, '0')}', // Simple ID generation
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            course: _selectedCourse!,
            status: _selectedStatus!,
            notes: _notesController.text,
          );
          _allStudents.add(newStudent);
        } else {
          // Update existing student
          final index = _allStudents.indexWhere((s) => s.id == _editingStudent!.id);
          if (index != -1) {
            _allStudents[index] = _editingStudent!.copyWith(
              name: _nameController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              course: _selectedCourse,
              status: _selectedStatus,
              notes: _notesController.text,
            );
          }
          _editingStudent = null; // Clear editing state
        }
        _clearForm();
        _filterStudents(); // Re-filter to update the list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingStudent == null ? 'Student Added!' : 'Student Updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editStudent(Student student) {
    setState(() {
      _editingStudent = student;
      _nameController.text = student.name;
      _emailController.text = student.email;
      _phoneController.text = student.phone;
      _selectedCourse = student.course;
      _selectedStatus = student.status;
      _notesController.text = student.notes;
    });
    // Scroll to the top to show the form
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _deleteStudent(String id) {
    setState(() {
      _allStudents.removeWhere((student) => student.id == id);
      _filterStudents();
      if (_editingStudent?.id == id) {
        _clearForm();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student Deleted!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _notesController.clear();
    setState(() {
      _selectedCourse = null;
      _selectedStatus = null;
      _editingStudent = null;
    });
  }

  void _callStudent(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make call: $e')),
      );
    }
  }
  
  // REMOVE THIS METHOD:
  /*
  void _emailStudent(String emailAddress, String studentName) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Inquiry regarding your application',
        'body': 'Dear $studentName,\n\n',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email client: $e')),
      );
    }
  }
  */

  // ADD THIS NEW METHOD
  void _navigateToEmailComposer(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentEmailComposer(
          recipientEmail: student.email,
          studentName: student.name,
        ),
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student CRM', style: TextStyle(color: Colors.white)),
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
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add/Edit Student Form
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingStudent == null ? 'Add New Student' : 'Edit Student',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                          hintText: 'e.g., Jane Doe',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter student name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'e.g., jane.doe@example.com',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g., +91 9876543210',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        hint: const Text('Select Course/Program'),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        items: _courses.map((String course) {
                          return DropdownMenuItem<String>(
                            value: course,
                            child: Text(course, overflow: TextOverflow.ellipsis), // Added overflow
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCourse = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a course';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        hint: const Text('Select Status'),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        items: _statuses.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status, overflow: TextOverflow.ellipsis), // Added overflow
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes/Remarks',
                          hintText: 'Any additional information',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addOrUpdateStudent,
                              icon: Icon(_editingStudent == null ? Icons.add : Icons.save),
                              label: Text(_editingStudent == null ? 'Add Student' : 'Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          if (_editingStudent != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _clearForm,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Student List Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Students by Name, Email, or Phone',
                hintText: 'e.g., Alok or alok@example.com',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterStudents();
                  },
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) => _filterStudents(),
            ),
            const SizedBox(height: 20),
            Text(
              'All Students (${_filteredStudents.length})',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF764ba2)),
            ),
            const SizedBox(height: 10),

            // Student List
            _filteredStudents.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No students found matching your criteria.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true, // Important for ListView inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Important
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded( // Use Expanded for title to prevent overflow
                                    child: Text(
                                      student.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${student.id}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text('Course: ${student.course}', style: const TextStyle(fontSize: 14)),
                              Text('Status: ${student.status}', style: const TextStyle(fontSize: 14)),
                              Text('Email: ${student.email}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                              Text('Phone: ${student.phone}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                              if (student.notes.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text('Notes: ${student.notes}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editStudent(student),
                                    tooltip: 'Edit Student',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green),
                                    onPressed: () => _callStudent(student.phone),
                                    tooltip: 'Call Student',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.email, color: Colors.orange),
                                    onPressed: () => _navigateToEmailComposer(student), // UPDATED THIS LINE
                                    tooltip: 'Email Student',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteStudent(student.id),
                                    tooltip: 'Delete Student',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}