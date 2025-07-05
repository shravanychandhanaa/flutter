import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/student_list_item.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/student_list_provider.dart';
import '../config/app_config.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teamController = TextEditingController();
  final _projectController = TextEditingController();
  final _notesController = TextEditingController();
  final _remarkController = TextEditingController();
  
  String? _selectedUserId;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Students will be loaded automatically by the StudentListProvider
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _teamController.dispose();
    _projectController.dispose();
    _notesController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isStaff = currentUser?.userType == UserType.staff;
    
    // For staff, require student selection
    if (isStaff && _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student to assign the task to'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (currentUser != null) {
      final success = await taskProvider.createTask(
        taskId: "",
        activityStatus: "assigned", 
        taskTitle: _titleController.text.trim(),
        remark: _remarkController.text.trim(),
        studentId: isStaff ? _selectedUserId! : currentUser.id, // For students, assign to themselves
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        team: _teamController.text.trim(),
        project: _projectController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isStaff ? 'Task created successfully!' : 'Task posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isStaff ? 'Failed to create task' : 'Failed to post task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final isStaff = currentUser?.userType == UserType.staff;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(isStaff ? 'Create New Task' : 'Post My Task'),
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Icon(
                              Icons.add_task,
                              size: 60,
                              color: Color(0xFF667eea),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              isStaff ? 'StartupWorld - Create Task' : 'StartupWorld - Post My Task',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2d3748),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Task Title
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Task Title *',
                              prefixIcon: Icon(Icons.title),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a task title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Task Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Task Description *',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a task description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Remark
                          TextFormField(
                            controller: _remarkController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Remark *',
                              prefixIcon: Icon(Icons.comment),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a remark';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Assign to Student (only for staff)
                          if (isStaff) ...[
                            Consumer<StudentListProvider>(
                              builder: (context, studentListProvider, child) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedUserId,
                                  decoration: const InputDecoration(
                                    labelText: 'Assign to Student *',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down, size: 24, color: Colors.black),
                                  items: studentListProvider.isLoading
                                      ? [const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('Loading students...'),
                                        )]
                                      : studentListProvider.students.map((StudentListItem student) {
                                          return DropdownMenuItem<String>(
                                            value: student.uid ?? student.id,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(Icons.person, size: 24, color: Colors.blueGrey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          student.displayName,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          student.displayCollege,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const Divider(height: 12, thickness: 1),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  onChanged: studentListProvider.isLoading ? null : (String? newValue) {
                                    setState(() {
                                      _selectedUserId = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a student';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Team
                          TextFormField(
                            controller: _teamController,
                            decoration: const InputDecoration(
                              labelText: 'Team *',
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a team name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Project
                          TextFormField(
                            controller: _projectController,
                            decoration: const InputDecoration(
                              labelText: 'Project *',
                              prefixIcon: Icon(Icons.work),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a project name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Due Date
                          InkWell(
                            onTap: _selectDueDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date (Optional)',
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _dueDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                                    : 'Select due date',
                                style: TextStyle(
                                  color: _dueDate != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Notes
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Additional Notes (Optional)',
                              prefixIcon: Icon(Icons.note),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Create Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      isStaff ? 'Create Task' : 'Post Task',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 