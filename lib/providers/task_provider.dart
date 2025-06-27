import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  List<String> _projects = [];
  List<String> _workTypes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  UserType? _currentUserType;

  List<Task> get tasks => _tasks;
  List<Task> get filteredTasks => _filteredTasks;
  List<String> get projects => _projects;
  List<String> get workTypes => _workTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set current user info
  void setCurrentUser(String userId, UserType userType) {
    _currentUserId = userId;
    _currentUserType = userType;
  }

  // Reload tasks based on current user type
  Future<void> _reloadTasks() async {
    print('🔄 _reloadTasks called:');
    print('   Current User ID: $_currentUserId');
    print('   Current User Type: $_currentUserType');
    
    if (_currentUserId != null) {
      if (_currentUserType == UserType.student) {
        print('   Reloading tasks for student: $_currentUserId');
        await loadTasksForUser(_currentUserId!);
      } else {
        print('   Reloading all tasks for staff');
        await loadAllTasks();
      }
    } else {
      print('   No current user set, skipping reload');
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load tasks for a specific user
  Future<void> loadTasksForUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getTasksForUser(userId);
      _filteredTasks = _tasks;
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      print('TaskProvider loadTasksForUser error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load all tasks (for staff)
  Future<void> loadAllTasks() async {
    print('🔄 TaskProvider.loadAllTasks() called');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📞 Calling _taskService.getAllTasks()');
      _tasks = await _taskService.getAllTasks();
      print('📥 Received ${_tasks.length} tasks from service');
      
      _filteredTasks = _tasks;
      print('✅ Set filteredTasks to ${_filteredTasks.length} tasks');
      
      // Debug: Print task details
      for (var task in _tasks) {
        print('   Task: ID=${task.id}, Title="${task.title}", AssignedTo=${task.assignedTo}, Status=${task.status}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      print('❌ TaskProvider loadAllTasks error: $e');
    }

    _isLoading = false;
    notifyListeners();
    print('🔄 TaskProvider.loadAllTasks() completed. Tasks: ${_tasks.length}, Filtered: ${_filteredTasks.length}');
  }

  // Load projects list
  Future<void> loadProjects() async {
    try {
      _projects = await _taskService.getProjectList();
      notifyListeners();
    } catch (e) {
      print('TaskProvider loadProjects error: $e');
      _errorMessage = 'Failed to load projects: $e';
      notifyListeners();
    }
  }

  // Load work types list
  Future<void> loadWorkTypes() async {
    try {
      _workTypes = await _taskService.getWorkTypeList();
      notifyListeners();
    } catch (e) {
      print('TaskProvider loadWorkTypes error: $e');
      _errorMessage = 'Failed to load work types: $e';
      notifyListeners();
    }
  }

  // Create new task
  Future<bool> createTask({
    String? taskId,
    String? activityStatus,
    String? taskTitle,
    String? remark,
    String? studentId,
    required String title,
    required String description,
    required String assignedTo,
    required String assignedBy,
    required String team,
    required String project,
    DateTime? dueDate,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _taskService.createTask(
        taskId: taskId,
        activityStatus: activityStatus,
        taskTitle: taskTitle,
        remark: remark,
        studentId: studentId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        team: team,
        project: project,
        dueDate: dueDate,
        notes: notes,
      );

      if (result['success'] == true) {
        await _reloadTasks(); // Reload tasks
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to create task';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('TaskProvider createTask error: $e');
      _errorMessage = 'Failed to create task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _taskService.updateTaskStatus(taskId, newStatus);

      if (result['success'] == true) {
        await _reloadTasks(); // Reload tasks
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update task status';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('TaskProvider updateTaskStatus error: $e');
      _errorMessage = 'Failed to update task status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update task notes
  Future<bool> updateTaskNotes(String taskId, String notes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _taskService.updateTaskNotes(taskId, notes);

      if (result['success'] == true) {
        await _reloadTasks(); // Reload tasks
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update task notes';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('TaskProvider updateTaskNotes error: $e');
      _errorMessage = 'Failed to update task notes: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Assign task to user
  Future<bool> assignTask({
    required String taskId,
    required String assignedTo,
    required String assignedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _taskService.assignTask(
        taskId: taskId,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
      );

      if (result['success'] == true) {
        await _reloadTasks(); // Reload tasks
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to assign task';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('TaskProvider assignTask error: $e');
      _errorMessage = 'Failed to assign task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Set user as open to tasks
  Future<bool> setUserOpenToTasks(String userId, bool isOpen) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _taskService.setUserOpenToTasks(userId, isOpen);

      if (result['success'] == true) {
        await _reloadTasks(); // Reload tasks
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update availability';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('TaskProvider setUserOpenToTasks error: $e');
      _errorMessage = 'Failed to update availability: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Filter tasks
  Future<void> filterTasks({
    String? team,
    String? project,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _filteredTasks = await _taskService.filterTasks(
        team: team,
        project: project,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = 'Failed to filter tasks: $e';
      print('TaskProvider filterTasks error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      return await _taskService.getTasksByStatus(status);
    } catch (e) {
      print('TaskProvider getTasksByStatus error: $e');
      return [];
    }
  }

  // Get open tasks
  Future<List<Task>> getOpenTasks([String? userId]) async {
    try {
      // Use provided userId or current user ID
      final targetUserId = userId ?? _currentUserId;
      return await _taskService.getOpenTasks(targetUserId);
    } catch (e) {
      print('TaskProvider getOpenTasks error: $e');
      return [];
    }
  }

  // Clear filters
  void clearFilters() {
    _filteredTasks = _tasks;
    _errorMessage = null;
    notifyListeners();
  }

  // Set tasks directly (for staff dashboard)
  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    _filteredTasks = tasks;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    print('✅ TaskProvider.setTasks() called with ${tasks.length} tasks');
  }
} 