import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/student_bottom_navigation.dart';
import 'login_screen.dart';
import 'create_task_screen.dart';
import 'dart:async';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  bool _isOpenToTasks = false;
  Timer? _timer;
  Map<String, DateTime> _taskStartTimes = {}; // Track start times for in-progress tasks

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    // Start timer to update time display for in-progress tasks and attendance
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      // Set current user in task provider for correct task reloading
      taskProvider.setCurrentUser(authProvider.currentUser!.id, authProvider.currentUser!.userType);
      
      await taskProvider.loadTasksForUser(authProvider.currentUser!.id);
      await attendanceProvider.loadTodayAttendance(authProvider.currentUser!.id);
      
      // Initialize task start times for in-progress tasks
      final tasks = taskProvider.tasks;
      for (final task in tasks) {
        if (task.status == TaskStatus.inProgress && task.startedAt != null) {
          _taskStartTimes[task.id] = task.startedAt!;
        }
      }
      
      // Check if user is open to tasks
      final openTasks = await taskProvider.getOpenTasks(authProvider.currentUser!.id);
      setState(() {
        _isOpenToTasks = openTasks.any((task) => 
          task.assignedTo == authProvider.currentUser!.id && task.isOpenToTask);
      });
    }
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.updateTaskStatus(task.id, newStatus);
    
    // Track start time for in-progress tasks
    if (newStatus == TaskStatus.inProgress) {
      _taskStartTimes[task.id] = DateTime.now();
    } else if (newStatus == TaskStatus.completed) {
      _taskStartTimes.remove(task.id); // Clear start time when completed
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task status updated to ${newStatus.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateTaskNotes(Task task) async {
    final TextEditingController notesController = TextEditingController(
      text: task.notes ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Task Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(notesController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.updateTaskNotes(task.id, result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task notes updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleOpenToTasks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await taskProvider.setUserOpenToTasks(
        authProvider.currentUser!.id, 
        !_isOpenToTasks
      );
      
      setState(() {
        _isOpenToTasks = !_isOpenToTasks;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOpenToTasks 
              ? 'You are now open to new tasks' 
              : 'You are no longer open to new tasks'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.open:
        return Colors.purple;
    }
  }

  // Get theme color based on user type and team leader status
  Color _getThemeColor() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return const Color(0xFF43A047); // Default green for students
    
    // For students, always use green
    if (user.userType == UserType.student) {
      return const Color(0xFF43A047); // Green
    }
    
    // For staff, check if they are team leader
    if (user.userType == UserType.staff) {
      // Check team leader status from session data
      final sessionData = authProvider.sessionData;
      final isTeamLeader = sessionData?['team_leader_status'] == 'true' || 
                          sessionData?['team_leader_status'] == true;
      
      if (isTeamLeader) {
        return const Color(0xFF4CAF50); // Mix of green and blue (teal-green)
      } else {
        return const Color(0xFF667eea); // Blue for regular staff
      }
    }
    
    return const Color(0xFF43A047); // Default green
  }

  Future<void> _showPostTaskDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController teamController = TextEditingController();
    final TextEditingController projectController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Current Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Task Description *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: teamController,
                decoration: const InputDecoration(
                  labelText: 'Team *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: projectController,
                decoration: const InputDecoration(
                  labelText: 'Project *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  teamController.text.trim().isEmpty ||
                  projectController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop({
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'team': teamController.text.trim(),
                'project': projectController.text.trim(),
                'notes': notesController.text.trim(),
              });
            },
            child: const Text('Post Task'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _postCurrentTask(result);
    }
  }

  Future<void> _postCurrentTask(Map<String, String> taskData) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final success = await taskProvider.createTask(
        title: taskData['title']!,
        description: taskData['description']!,
        studentId: authProvider.currentUser!.id,
        team: taskData['team']!,
        project: taskData['project']!,
        notes: taskData['notes']!.isEmpty ? null : taskData['notes'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the task list
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmStatusUpdate(
    Task task, 
    TaskStatus newStatus, 
    String actionTitle, 
    String confirmationMessage
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionTitle),
        content: Text(confirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateTaskStatus(task, newStatus);
    }
  }

  Future<void> _checkIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final success = await attendanceProvider.checkIn(
        authProvider.currentUser!.id,
        authProvider.currentUser!.name,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked in!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already checked in today'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _checkOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final success = await attendanceProvider.checkOut(authProvider.currentUser!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked out!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active check-in found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildDashboardTab() {
    return Consumer3<AuthProvider, TaskProvider, AttendanceProvider>(
      builder: (context, authProvider, taskProvider, attendanceProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = taskProvider.tasks;
        final todayAttendance = attendanceProvider.todayAttendance;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 150.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: _getThemeColor(),
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Student Dashboard',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isOpenToTasks,
                          onChanged: (value) => _toggleOpenToTasks(),
                          activeColor: _getThemeColor(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Open to Tasks Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          _isOpenToTasks ? Icons.check_circle : Icons.cancel,
                          color: _isOpenToTasks ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOpenToTasks ? 'Open to New Tasks' : 'Not Open to New Tasks',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isOpenToTasks 
                                  ? 'Staff can assign you new tasks'
                                  : 'You will not receive new task assignments',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Cards
                const Text(
                  'My Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive grid based on screen width
                    final screenWidth = constraints.maxWidth;
                    final crossAxisCount = screenWidth > 600 ? 4 : 2;
                    final childWidth = (screenWidth - (crossAxisCount - 1) * 12 - 32) / crossAxisCount;
                    
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childWidth / 100, // Responsive aspect ratio
                      children: [
                        _buildStatCard('Total Tasks', tasks.length, Colors.blue),
                        _buildStatCard('In Progress', tasks.where((t) => t.status == TaskStatus.inProgress).length, Colors.orange),
                        _buildStatCard('Completed', tasks.where((t) => t.status == TaskStatus.completed).length, Colors.green),
                        _buildStatCard('Assigned', tasks.where((t) => t.status == TaskStatus.assigned).length, Colors.purple),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Today's Attendance
                if (todayAttendance != null) ...[
                  const Text(
                    'Today\'s Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            todayAttendance.isPresent ? Icons.check_circle : Icons.cancel,
                            color: todayAttendance.isPresent ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todayAttendance.isPresent ? 'Present' : 'Absent',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Date: ${DateFormat('MMM dd, yyyy').format(todayAttendance.date)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (todayAttendance.checkInTime != null)
                                  Text(
                                    'Check-in: ${DateFormat('HH:mm').format(todayAttendance.checkInTime!)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recent Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1; // Switch to Tasks tab
                        });
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (tasks.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks assigned yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.take(3).length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            task.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${task.team} • ${task.project}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (task.status == TaskStatus.inProgress) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.timer, size: 12, color: Colors.blue[600]),
                                    const SizedBox(width: 2),
                                    Text(
                                      _getFormattedTimeSpent(task),
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task.status.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;

        return Column(
          children: [
            // Task Count Display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You have ${tasks.length} task${tasks.length == 1 ? '' : 's'} assigned',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Show status breakdown
                  if (tasks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${tasks.where((t) => t.status == TaskStatus.assigned).length} Pending',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${tasks.where((t) => t.status == TaskStatus.inProgress).length} In Progress',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${tasks.where((t) => t.status == TaskStatus.completed).length} Completed',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Tasks List
            Expanded(
              child: taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks assigned yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tasks will appear here when assigned by staff',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(task.status),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            task.status.name.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      task.description,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.group, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.team,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.work, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.project,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Assigned: ${DateFormat('MMM dd, yyyy').format(task.assignedDate)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (task.dueDate != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    // Show timer for in-progress tasks
                                    if (task.status == TaskStatus.inProgress) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.timer, size: 16, color: Colors.blue[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Time: ${_getFormattedTimeSpent(task)}',
                                            style: TextStyle(
                                              color: Colors.blue[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (task.status == TaskStatus.assigned)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _confirmStatusUpdate(
                                                task, 
                                                TaskStatus.inProgress,
                                                'Start Task',
                                                'Are you sure you want to start this task? This will begin time tracking.',
                                              ),
                                              icon: const Icon(Icons.play_arrow, size: 16),
                                              label: const Text('Start Task'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        if (task.status == TaskStatus.inProgress) ...[
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _confirmStatusUpdate(
                                                task, 
                                                TaskStatus.completed,
                                                'Complete Task',
                                                'Are you sure you want to mark this task as completed? This will stop time tracking.',
                                              ),
                                              icon: const Icon(Icons.check, size: 16),
                                              label: const Text('Complete'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (task.status != TaskStatus.completed)
                                          TextButton.icon(
                                            onPressed: () => _updateTaskNotes(task),
                                            icon: const Icon(Icons.note_add, size: 16),
                                            label: const Text('Add Notes'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: _getThemeColor(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Attendance Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 64,
                color: _getThemeColor(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_getAppBarTitle()),
            backgroundColor: _getThemeColor(),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          drawer: AppDrawer(user: user, themeColor: _getThemeColor()),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardTab(),
              _buildTasksTab(),
              _buildAttendanceTab(),
              _buildProfileTab(),
            ],
          ),
          bottomNavigationBar: StudentBottomNavigation(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTap,
            themeColor: _getThemeColor(),
          ),
          floatingActionButton: _currentIndex == 1 // Tasks tab
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateTaskScreen(),
                      ),
                    );
                  },
                  backgroundColor: _getThemeColor(),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Student Dashboard';
      case 1:
        return 'My Tasks';
      case 2:
        return 'Attendance';
      case 3:
        return 'Profile';
      default:
        return 'Student Dashboard';
    }
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calculate current time spent for a task
  Duration _getCurrentTimeSpent(Task task) {
    if (task.status == TaskStatus.inProgress) {
      // Use tracked start time if available, otherwise use task's startedAt
      final startTime = _taskStartTimes[task.id] ?? task.startedAt;
      if (startTime != null) {
        return DateTime.now().difference(startTime);
      }
    }
    return task.timeSpent ?? Duration.zero;
  }

  // Get formatted time string for a task
  String _getFormattedTimeSpent(Task task) {
    final duration = _getCurrentTimeSpent(task);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
} 