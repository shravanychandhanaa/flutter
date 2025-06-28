import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class TaskService {
  final Uuid _uuid = const Uuid();

  // Create a new task
  Future<Map<String, dynamic>> createTask({
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
    try {
      Map<String, dynamic> taskData = {
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'assigned_by': assignedBy,
        'team': team,
        'project': project.isNotEmpty ? project : 'General',
        'project_name': project.isNotEmpty ? project : 'General',
        'due_date': dueDate?.toIso8601String(),
        'notes': notes ?? '',
        'status': 'assigned',
        'activityStatus': activityStatus ?? 'assigned',
        'activity_status': activityStatus ?? 'assigned',
        'submit': 'submit',
        'updated_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'api_key': AppConfig.apiKey,
      };

      // Add optional parameters if provided
      if (taskId != null && taskId.isNotEmpty) taskData['id'] = taskId;
      if (taskTitle != null) taskData['t_title'] = taskTitle;

      // Always add remark field - even if empty
      print('DEBUG: remark parameter received: $remark');
      print('DEBUG: remark is null: ${remark == null}');
      print('DEBUG: remark is empty: ${remark?.isEmpty ?? true}');
      print('DEBUG: remark trimmed: ${remark?.trim() ?? ""}');

      // Always set remark field (not tremark)
      taskData['remark'] = remark?.trim() ?? '';

      if (studentId != null && studentId.isNotEmpty) {
        // Ensure studentId is a valid integer for PHP
        final userId = int.tryParse(studentId);
        if (userId != null) {
          taskData['student_id'] = userId.toString(); // PHP expects 'student_id'
          print('DEBUG: Valid student ID set: ${taskData['student_id']}');
        } else {
          print('DEBUG: Invalid student ID: $studentId');
          throw Exception('Invalid student ID: $studentId');
        }
      } else {
        print('DEBUG: studentId is null or empty: $studentId');
        throw Exception('Student ID is required and cannot be empty');
      }

      // Debug logging
      print('📤 Task Data being sent: $taskData');
      print('📤 Student ID: ${taskData['student_id']}');
      print('📤 Remark field: ${taskData['remark']}');
      print('📤 Project value: "$project"');
      print('📤 Team value: "$team"');
      print('📤 Title value: "$title"');
      print('📤 Description value: "$description"');
      print('DEBUG: taskData before sending: ' + taskData.toString());

      final response = await ApiService.addTask(taskData);

      // Debug logging
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200 || responseData['status'] == 'success') {
          return {
            'success': true,
            'message': responseData['responseMessage'] ?? responseData['message'] ?? 'Task created successfully',
            'task_id': responseData['task_id'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['responseMessage'] ?? responseData['message'] ?? 'Failed to create task',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Create task error: $e');
      return {
        'success': false,
        'message': 'Failed to create task: $e',
      };
    }
  }

  // Get tasks assigned to a specific user
  Future<List<Task>> getTasksForUser(String userId) async {
    try {
      final response = await ApiService.getTaskList({
        'student_id': userId,
        'api_key': AppConfig.apiKey,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        print('📥 getTasksForUser response: $responseData');
        
        if (responseData['responseStatus'] == 200) {
          List<Task> tasks = [];
          final postsList = responseData['posts'] ?? [];
          
          print('📋 Found ${postsList.length} posts in response');
          
          for (var postData in postsList) {
            print('📋 Processing post: $postData');
            
            // Map the API response fields to Task model fields
            tasks.add(Task(
              id: postData['id']?.toString() ?? '',
              title: postData['task_title'] ?? postData['current_task'] ?? 'Untitled Task',
              description: postData['remark'] ?? '',
              assignedTo: postData['user_id']?.toString() ?? '',
              assignedBy: postData['user_id']?.toString() ?? '', // Assuming same as assignedTo for now
              team: postData['team_name'] ?? postData['team'] ?? '',
              project: postData['project_name'] ?? postData['project']?.toString() ?? '',
              assignedDate: DateTime.tryParse(postData['created_date'] ?? '') ?? DateTime.now(),
              dueDate: null, // Not provided in current response
              status: _parseTaskStatus(postData['activity_status'] ?? ''),
              notes: postData['remark'] ?? '',
              startedAt: null, // Not provided in current response
              completedAt: null, // Not provided in current response
              timeSpent: postData['time_spent'] != null && postData['time_spent'].toString().isNotEmpty 
                ? Duration(seconds: int.tryParse(postData['time_spent'].toString()) ?? 0) 
                : null,
              isOpenToTask: postData['activity_status'] == 'open',
            ));
          }
          
          print('✅ Created ${tasks.length} Task objects');
          return tasks;
        } else {
          print('❌ API returned error status: ${responseData['responseStatus']}');
        }
      }
      
      return [];
    } catch (e) {
      print('Get tasks for user error: $e');
      return [];
    }
  }

  // Get all tasks (for staff)
  Future<List<Task>> getAllTasks() async {
    try {
      print('🔍 getAllTasks called - fetching all tasks for staff view');
      
      final response = await ApiService.getAllTasksForStaff({
        'api_key': AppConfig.apiKey,
      });

      print('📥 getAllTasks response status: ${response.statusCode}');
      print('📥 getAllTasks response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        print('📥 getAllTasks response: $responseData');
        
        if (responseData['responseStatus'] == 200) {
          List<Task> tasks = [];
          
          // Handle the new response format with "Assigned Tasks Lists"
          final assignedTasksList = responseData['Assigned Tasks Lists'] ?? [];
          
          print('📋 Found ${assignedTasksList.length} assigned tasks in response');
          
          if (assignedTasksList.isEmpty) {
            print('⚠️ No assigned tasks found in response. Response structure:');
            print('   responseData keys: ${responseData.keys.toList()}');
            print('   responseData: $responseData');
          }
          
          for (var taskData in assignedTasksList) {
            print('📋 Processing assigned task: $taskData');
            
            // Map the new API response fields to Task model fields
            tasks.add(Task(
              id: taskData['student_id']?.toString() ?? '', // Use student_id as task ID for now
              title: taskData['assign_task_description']?.isNotEmpty == true 
                ? taskData['assign_task_description'] 
                : 'Task for ${taskData['student_name'] ?? 'Student'}',
              description: taskData['assign_task_description'] ?? '',
              assignedTo: taskData['student_id']?.toString() ?? '',
              assignedBy: taskData['assign_from_name'] ?? taskData['assign_from_entity'] ?? 'Unknown',
              team: '', // Not provided in this response
              project: '', // Not provided in this response
              assignedDate: DateTime.tryParse(taskData['created_date'] ?? '') ?? DateTime.now(),
              dueDate: null, // Not provided in current response
              status: TaskStatus.assigned, // Default to assigned since these are assigned tasks
              notes: taskData['assign_task_description'] ?? '',
              startedAt: null, // Not provided in current response
              completedAt: null, // Not provided in current response
              timeSpent: null, // Not provided in current response
              isOpenToTask: false, // These are assigned tasks, not open
            ));
          }
          
          print('✅ Created ${tasks.length} Task objects for staff view');
          print('📋 Task details:');
          for (var task in tasks) {
            print('   - ID: ${task.id}, Title: ${task.title}, AssignedTo: ${task.assignedTo}, Status: ${task.status}');
          }
          return tasks;
        } else {
          print('❌ API returned error status: ${responseData['responseStatus']}');
          print('❌ Error message: ${responseData['responseMessage']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('❌ Get all tasks error: $e');
      return [];
    }
  }

  // Get all tasks with custom date range (for staff)
  Future<List<Task>> getAllTasksWithDateRange(DateTime fromDate, DateTime toDate) async {
    try {
      print('🔍 getAllTasksWithDateRange called - fetching tasks from $fromDate to $toDate');
      
      final response = await ApiService.getAllTasksForStaffWithDateRange(fromDate, toDate);

      print('📥 getAllTasksWithDateRange response status: ${response.statusCode}');
      print('📥 getAllTasksWithDateRange response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        print('📥 getAllTasksWithDateRange response: $responseData');
        
        if (responseData['responseStatus'] == 200) {
          List<Task> tasks = [];
          
          // Handle the new response format with "Assigned Tasks Lists"
          final assignedTasksList = responseData['Assigned Tasks Lists'] ?? [];
          
          print('📋 Found ${assignedTasksList.length} assigned tasks in response for date range');
          
          for (var taskData in assignedTasksList) {
            print('📋 Processing assigned task: $taskData');
            
            // Map the new API response fields to Task model fields
            tasks.add(Task(
              id: taskData['student_id']?.toString() ?? '', // Use student_id as task ID for now
              title: taskData['assign_task_description']?.isNotEmpty == true 
                ? taskData['assign_task_description'] 
                : 'Task for ${taskData['student_name'] ?? 'Student'}',
              description: taskData['assign_task_description'] ?? '',
              assignedTo: taskData['student_id']?.toString() ?? '',
              assignedBy: taskData['assign_from_name'] ?? taskData['assign_from_entity'] ?? 'Unknown',
              team: '', // Not provided in this response
              project: '', // Not provided in this response
              assignedDate: DateTime.tryParse(taskData['created_date'] ?? '') ?? DateTime.now(),
              dueDate: null, // Not provided in current response
              status: TaskStatus.assigned, // Default to assigned since these are assigned tasks
              notes: taskData['assign_task_description'] ?? '',
              startedAt: null, // Not provided in current response
              completedAt: null, // Not provided in current response
              timeSpent: null, // Not provided in current response
              isOpenToTask: false, // These are assigned tasks, not open
            ));
          }
          
          print('✅ Created ${tasks.length} Task objects for date range');
          return tasks;
        } else {
          print('❌ API returned error status: ${responseData['responseStatus']}');
          print('❌ Error message: ${responseData['responseMessage']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('❌ Get all tasks with date range error: $e');
      return [];
    }
  }

  // Update task status with time tracking
  Future<Map<String, dynamic>> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      Map<String, dynamic> updateData = {
        'id': taskId,
        'activity_status': _taskStatusToString(newStatus),
        'status': _taskStatusToString(newStatus),
        'updated_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'submit': 'submit',
      };

      // Add time tracking data
      if (newStatus == TaskStatus.inProgress) {
        updateData['started_at'] = DateTime.now().toIso8601String();
        updateData['started_date'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      } else if (newStatus == TaskStatus.completed) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        updateData['completed_date'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      }

      print('📤 Updating task status: $updateData');

      final response = await ApiService.addTask(updateData);

      print('📥 Update task status response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200 || responseData['status'] == 'success') {
          return {
            'success': true,
            'message': responseData['responseMessage'] ?? responseData['message'] ?? 'Task status updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['responseMessage'] ?? responseData['message'] ?? 'Failed to update task status',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Update task status error: $e');
      return {
        'success': false,
        'message': 'Failed to update task status: $e',
      };
    }
  }

  // Update task notes
  Future<Map<String, dynamic>> updateTaskNotes(String taskId, String notes) async {
    try {
      final response = await ApiService.addTask({
        'task_id': taskId,
        'notes': notes,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Task notes updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update task notes',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Update task notes error: $e');
      return {
        'success': false,
        'message': 'Failed to update task notes: $e',
      };
    }
  }

  // Assign task to user
  Future<Map<String, dynamic>> assignTask({
    required String taskId,
    required String assignedTo,
    required String assignedBy,
  }) async {
    try {
      final response = await ApiService.assignTask({
        'task_id': taskId,
        'assigned_to': assignedTo,
        'assigned_by': assignedBy,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Task assigned successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to assign task',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Assign task error: $e');
      return {
        'success': false,
        'message': 'Failed to assign task: $e',
      };
    }
  }

  // Set user as open to tasks
  Future<Map<String, dynamic>> setUserOpenToTasks(String userId, bool isOpen) async {
    try {
      final response = await ApiService.addTask({
        'user_id': userId,
        'is_open_to_task': isOpen,
        'title': 'Open to Tasks',
        'description': 'User is available for new task assignments',
        'status': 'open',
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Availability updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update availability',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Set user open to tasks error: $e');
      return {
        'success': false,
        'message': 'Failed to update availability: $e',
      };
    }
  }

  // Get project list
  Future<List<String>> getProjectList() async {
    try {
      final response = await ApiService.getProjectList({
        'api_key': AppConfig.apiKey,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          List<String> projects = [];
          final projectsList = responseData['projects'] ?? [];
          
          for (var projectData in projectsList) {
            projects.add(projectData['name'] ?? '');
          }
          
          return projects;
        }
      }
      
      return [];
    } catch (e) {
      print('Get project list error: $e');
      return [];
    }
  }

  // Get work type list
  Future<List<String>> getWorkTypeList() async {
    try {
      final response = await ApiService.getWorkTypeList({
        'api_key': AppConfig.apiKey,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          List<String> workTypes = [];
          final workTypesList = responseData['work_types'] ?? [];
          
          for (var workTypeData in workTypesList) {
            workTypes.add(workTypeData['name'] ?? '');
          }
          
          return workTypes;
        }
      }
      
      return [];
    } catch (e) {
      print('Get work type list error: $e');
      return [];
    }
  }

  // Filter tasks by team, project, and date range
  Future<List<Task>> filterTasks({
    String? team,
    String? project,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allTasks = await getAllTasks();
    
    return allTasks.where((task) {
      bool matches = true;
      
      if (team != null && team.isNotEmpty) {
        matches = matches && task.team.toLowerCase().contains(team.toLowerCase());
      }
      
      if (project != null && project.isNotEmpty) {
        matches = matches && task.project.toLowerCase().contains(project.toLowerCase());
      }
      
      if (startDate != null) {
        matches = matches && task.assignedDate.isAfter(startDate.subtract(const Duration(days: 1)));
      }
      
      if (endDate != null) {
        matches = matches && task.assignedDate.isBefore(endDate.add(const Duration(days: 1)));
      }
      
      return matches;
    }).toList();
  }

  // Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final allTasks = await getAllTasks();
    return allTasks.where((task) => task.status == status).toList();
  }

  // Get open tasks (users who are open to new assignments)
  Future<List<Task>> getOpenTasks([String? userId]) async {
    List<Task> allTasks;
    
    if (userId != null) {
      // If user ID is provided, get tasks for that specific user
      allTasks = await getTasksForUser(userId);
    } else {
      // Otherwise get all tasks (for staff view)
      allTasks = await getAllTasks();
    }
    
    return allTasks.where((task) => task.isOpenToTask).toList();
  }

  // Helper methods for status conversion
  TaskStatus _parseTaskStatus(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return TaskStatus.assigned;
      case 'in_progress':
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'open':
        return TaskStatus.open;
      default:
        return TaskStatus.assigned;
    }
  }

  String _taskStatusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return 'assigned';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.open:
        return 'open';
    }
  }

  // Get all student tasks for staff view (new API endpoint)
  Future<List<Task>> getAllStudentTasksForStaff() async {
    try {
      print('🔍 getAllStudentTasksForStaff called - fetching all student tasks for staff view');
      
      // Use a broader date range - last 30 days instead of just today
      final now = DateTime.now();
      final fromDate = '${now.year}-${(now.month - 1).toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final toDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // Prepare request data
      Map<String, dynamic> requestData = {
        'from_date': fromDate,
        'to_date': toDate,
        'api_key': AppConfig.apiKey,
      };
      
      print('📤 Request data: $requestData');
      print('📅 Date range: $fromDate to $toDate (last 30 days)');
      
      final response = await ApiService.getAllTasksForStaff(requestData);

      print('📥 getAllStudentTasksForStaff response status: ${response.statusCode}');
      print('📥 getAllStudentTasksForStaff response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200) {
          List<Task> tasks = [];
          
          // Handle the new response format with "Assigned Tasks Lists"
          final assignedTasksList = responseData['Assigned Tasks Lists'] ?? [];
          
          print('📋 Found ${assignedTasksList.length} assigned tasks in response');
          
          if (assignedTasksList.isEmpty) {
            print('⚠️ No assigned tasks found in response. Response structure:');
            print('   responseData keys: ${responseData.keys.toList()}');
            print('   responseData: $responseData');
            
            // Try alternative response formats
            final alternativeKeys = ['tasks', 'task_list', 'data', 'posts'];
            for (var key in alternativeKeys) {
              if (responseData[key] != null) {
                print('🔍 Found alternative key: $key with ${responseData[key].length} items');
                final alternativeList = responseData[key] as List;
                for (var item in alternativeList) {
                  print('   Alternative item: $item');
                }
              }
            }
          }
          
          for (var taskData in assignedTasksList) {
            print('📋 Processing assigned task: $taskData');
            
            // Map the new API response fields to Task model fields
            tasks.add(Task(
              id: taskData['student_id']?.toString() ?? '', // Use student_id as task ID for now
              title: taskData['assign_task_description']?.isNotEmpty == true 
                ? taskData['assign_task_description'] 
                : 'Task for ${taskData['student_name'] ?? 'Student'}',
              description: taskData['assign_task_description'] ?? '',
              assignedTo: taskData['student_id']?.toString() ?? '',
              assignedBy: taskData['assign_from_name'] ?? taskData['assign_from_entity'] ?? 'Unknown',
              team: taskData['team_name'] ?? taskData['team'] ?? '', // Try to get team info
              project: taskData['project_name'] ?? taskData['project'] ?? '', // Try to get project info
              assignedDate: DateTime.tryParse(taskData['created_date'] ?? '') ?? DateTime.now(),
              dueDate: null, // Not provided in current response
              status: TaskStatus.assigned, // Default to assigned since these are assigned tasks
              notes: taskData['assign_task_description'] ?? '',
              startedAt: null, // Not provided in current response
              completedAt: null, // Not provided in current response
              timeSpent: null, // Not provided in current response
              isOpenToTask: false, // These are assigned tasks, not open
            ));
          }
          
          print('✅ Created ${tasks.length} Task objects for staff view');
          print('📋 Task details:');
          for (var task in tasks) {
            print('   - ID: ${task.id}, Title: ${task.title}, AssignedTo: ${task.assignedTo}, Status: ${task.status}');
          }
          return tasks;
        } else {
          print('❌ API returned error status: ${responseData['responseStatus']}');
          print('❌ Error message: ${responseData['responseMessage']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('❌ Get all student tasks for staff error: $e');
      return [];
    }
  }

  // Get all student tasks for staff view without date filtering (fallback method)
  Future<List<Task>> getAllStudentTasksForStaffNoDateFilter() async {
    try {
      print('🔍 getAllStudentTasksForStaffNoDateFilter called - fetching all student tasks without date filter');
      
      // Prepare request data without date filtering
      Map<String, dynamic> requestData = {
        'api_key': AppConfig.apiKey,
      };
      
      print('📤 Request data (no date filter): $requestData');
      
      final response = await ApiService.getAllTasksForStaff(requestData);

      print('📥 getAllStudentTasksForStaffNoDateFilter response status: ${response.statusCode}');
      print('📥 getAllStudentTasksForStaffNoDateFilter response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200) {
          List<Task> tasks = [];
          
          // Handle the new response format with "Assigned Tasks Lists"
          final assignedTasksList = responseData['Assigned Tasks Lists'] ?? [];
          
          print('📋 Found ${assignedTasksList.length} assigned tasks in response (no date filter)');
          
          if (assignedTasksList.isEmpty) {
            print('⚠️ No assigned tasks found in response (no date filter). Response structure:');
            print('   responseData keys: ${responseData.keys.toList()}');
            print('   responseData: $responseData');
            
            // Try alternative response formats
            final alternativeKeys = ['tasks', 'task_list', 'data', 'posts'];
            for (var key in alternativeKeys) {
              if (responseData[key] != null) {
                print('🔍 Found alternative key: $key with ${responseData[key].length} items');
                final alternativeList = responseData[key] as List;
                for (var item in alternativeList) {
                  print('   Alternative item: $item');
                }
              }
            }
          }
          
          for (var taskData in assignedTasksList) {
            print('📋 Processing assigned task (no date filter): $taskData');
            
            // Map the new API response fields to Task model fields
            tasks.add(Task(
              id: taskData['student_id']?.toString() ?? '', // Use student_id as task ID for now
              title: taskData['assign_task_description']?.isNotEmpty == true 
                ? taskData['assign_task_description'] 
                : 'Task for ${taskData['student_name'] ?? 'Student'}',
              description: taskData['assign_task_description'] ?? '',
              assignedTo: taskData['student_id']?.toString() ?? '',
              assignedBy: taskData['assign_from_name'] ?? taskData['assign_from_entity'] ?? 'Unknown',
              team: taskData['team_name'] ?? taskData['team'] ?? '', // Try to get team info
              project: taskData['project_name'] ?? taskData['project'] ?? '', // Try to get project info
              assignedDate: DateTime.tryParse(taskData['created_date'] ?? '') ?? DateTime.now(),
              dueDate: null, // Not provided in current response
              status: TaskStatus.assigned, // Default to assigned since these are assigned tasks
              notes: taskData['assign_task_description'] ?? '',
              startedAt: null, // Not provided in current response
              completedAt: null, // Not provided in current response
              timeSpent: null, // Not provided in current response
              isOpenToTask: false, // These are assigned tasks, not open
            ));
          }
          
          print('✅ Created ${tasks.length} Task objects for staff view (no date filter)');
          print('📋 Task details:');
          for (var task in tasks) {
            print('   - ID: ${task.id}, Title: ${task.title}, AssignedTo: ${task.assignedTo}, Status: ${task.status}');
          }
          return tasks;
        } else {
          print('❌ API returned error status: ${responseData['responseStatus']}');
          print('❌ Error message: ${responseData['responseMessage']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('❌ Get all student tasks for staff error (no date filter): $e');
      return [];
    }
  }

  // Try the old API endpoint to see if it returns tasks
  Future<List<Task>> tryOldApiEndpoint() async {
    try {
      print('🔍 tryOldApiEndpoint called - trying the old API endpoint');
      
      // Prepare request data
      Map<String, dynamic> requestData = {
        'api_key': AppConfig.apiKey,
      };
      
      print('📤 Request data (old endpoint): $requestData');
      
      final response = await ApiService.viewPreviousTasks(requestData);

      print('📥 tryOldApiEndpoint response status: ${response.statusCode}');
      print('📥 tryOldApiEndpoint response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200) {
          List<Task> tasks = [];
          
          // Handle the old response format
          final postsList = responseData['posts'] ?? [];
          
          print('📋 Found ${postsList.length} posts in old endpoint response');
          
          for (var taskData in postsList) {
            print('📋 Processing old endpoint task: $taskData');
            
            // Map the old API response fields to Task model fields
            tasks.add(Task(
              id: taskData['id']?.toString() ?? '',
              title: taskData['task_title'] ?? taskData['current_task'] ?? 'Untitled Task',
              description: taskData['remark'] ?? '',
              assignedTo: taskData['user_id']?.toString() ?? '',
              assignedBy: taskData['user_id']?.toString() ?? '', // Assuming same as assignedTo for now
              team: taskData['team_name'] ?? taskData['team'] ?? '',
              project: taskData['project_name'] ?? taskData['project']?.toString() ?? '',
              assignedDate: DateTime.tryParse(taskData['created_date'] ?? '') ?? DateTime.now(),
              dueDate: null, // Not provided in current response
              status: _parseTaskStatus(taskData['activity_status'] ?? ''),
              notes: taskData['remark'] ?? '',
              startedAt: null, // Not provided in current response
              completedAt: null, // Not provided in current response
              timeSpent: taskData['time_spent'] != null && taskData['time_spent'].toString().isNotEmpty 
                ? Duration(seconds: int.tryParse(taskData['time_spent'].toString()) ?? 0) 
                : null,
              isOpenToTask: taskData['activity_status'] == 'open',
            ));
          }
          
          print('✅ Created ${tasks.length} Task objects from old endpoint');
          print('📋 Task details:');
          for (var task in tasks) {
            print('   - ID: ${task.id}, Title: ${task.title}, AssignedTo: ${task.assignedTo}, Status: ${task.status}');
          }
          return tasks;
        } else {
          print('❌ Old API returned error status: ${responseData['responseStatus']}');
          print('❌ Error message: ${responseData['responseMessage']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('❌ Try old API endpoint error: $e');
      return [];
    }
  }

  // Test method to directly call the API endpoint
  Future<void> testApiEndpoint() async {
    try {
      print('🧪 Testing API endpoint directly...');
      
      // Test with different date ranges
      final testCases = [
        {
          'name': 'Today only',
          'data': <String, dynamic>{
            'from_date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
            'to_date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
            'api_key': AppConfig.apiKey,
          }
        },
        {
          'name': 'Last 30 days',
          'data': <String, dynamic>{
            'from_date': '${DateTime.now().year}-${(DateTime.now().month - 1).toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
            'to_date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
            'api_key': AppConfig.apiKey,
          }
        },
        {
          'name': 'No date filter',
          'data': <String, dynamic>{
            'api_key': AppConfig.apiKey,
          }
        },
        {
          'name': 'Last 7 days',
          'data': <String, dynamic>{
            'from_date': '${DateTime.now().subtract(Duration(days: 7)).year}-${DateTime.now().subtract(Duration(days: 7)).month.toString().padLeft(2, '0')}-${DateTime.now().subtract(Duration(days: 7)).day.toString().padLeft(2, '0')}',
            'to_date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
            'api_key': AppConfig.apiKey,
          }
        },
      ];
      
      for (var testCase in testCases) {
        print('\n🧪 Testing: ${testCase['name']}');
        print('📤 Request data: ${testCase['data']}');
        
        try {
          final response = await ApiService.getAllTasksForStaff(testCase['data'] as Map<String, dynamic>);
          print('📥 Response status: ${response.statusCode}');
          print('📥 Response data: ${response.data}');
          
          if (response.statusCode == 200) {
            final responseData = response.data;
            if (responseData['responseStatus'] == 200) {
              final assignedTasksList = responseData['Assigned Tasks Lists'] ?? [];
              print('✅ Found ${assignedTasksList.length} tasks for ${testCase['name']}');
            } else {
              print('❌ API error: ${responseData['responseMessage']}');
            }
          } else {
            print('❌ HTTP error: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ Test case failed: $e');
        }
      }
    } catch (e) {
      print('❌ Test API endpoint error: $e');
    }
  }
} 