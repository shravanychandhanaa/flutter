import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/student_list_item.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/student_list_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/staff_bottom_navigation.dart';
import 'login_screen.dart';
import 'create_task_screen.dart';
import 'attendance_report_screen.dart';
import 'attendance_approval_screen.dart';
import '../services/task_service.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;
  String _selectedFilter = 'All';
  String _teamFilter = '';
  String _projectFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  List<User> _allUsers = [];
  List<Task> _filteredTasks = [];

  // Student list filters
  final TextEditingController _searchController = TextEditingController();
  String _selectedStudentTeam = '';
  String _selectedStudentProject = '';
  String _selectedStudentStatus = '';
  String _selectedStudentCollege = '';
  String _selectedStudentWorkCategory = '';
  String _selectedStudentWorkType = '';
  String _selectedStudentState = '';
  String _selectedStudentCity = '';
  
  // New filters
  bool _teamNotAssigned = false;
  bool _projectNotAssigned = false;

  // Advanced search parameters
  bool _showAdvancedSearch = false;
  final TextEditingController _taskSearchController = TextEditingController();
  String _selectedTaskStatus = 'All';
  String _selectedTaskPriority = 'All';
  String _selectedTaskAssignee = 'All';
  String _selectedTaskAssignedBy = 'All';
  DateTime? _taskStartDate;
  DateTime? _taskEndDate;
  DateTime? _taskDueStartDate;
  DateTime? _taskDueEndDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _taskSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('🔄 StaffDashboard._loadData() called');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final studentListProvider = Provider.of<StudentListProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      print('👤 Current user: ${authProvider.currentUser!.name} (${authProvider.currentUser!.userType})');
      // Set current user in task provider for correct task reloading
      taskProvider.setCurrentUser(authProvider.currentUser!.id, authProvider.currentUser!.userType);
    } else {
      print('⚠️ No current user found');
    }
    
    // Load all student tasks using the new API endpoint
    print('📞 Loading all student tasks...');
    try {
      final taskService = TaskService();
      List<Task> tasks = await taskService.getAllStudentTasksForStaff();
      print('📥 Student tasks loaded. Tasks count: ${tasks.length}');
      
      // If no tasks found, try without date filter
      if (tasks.isEmpty) {
        print('⚠️ No tasks found with date filter, trying without date filter...');
        tasks = await taskService.getAllStudentTasksForStaffNoDateFilter();
        print('📥 Student tasks loaded (no date filter). Tasks count: ${tasks.length}');
      }
      
      // If still no tasks found, try the old API endpoint
      if (tasks.isEmpty) {
        print('⚠️ No tasks found with new endpoint, trying old API endpoint...');
        tasks = await taskService.tryOldApiEndpoint();
        print('📥 Student tasks loaded (old endpoint). Tasks count: ${tasks.length}');
      }
      
      // Update the task provider with the new tasks
      taskProvider.setTasks(tasks);
      
      print('✅ Task provider updated with ${tasks.length} tasks');
    } catch (e) {
      print('❌ Error loading student tasks: $e');
    }
    
    print('📞 Loading student list...');
    await studentListProvider.loadStudentList();
    print('📥 Students loaded. StudentListProvider.students.length: ${studentListProvider.students.length}');
    
    print('📞 Loading all users...');
    _allUsers = await authProvider.getAllUsers();
    print('📥 Users loaded. _allUsers.length: ${_allUsers.length}');
    
    setState(() {
      _filteredTasks = taskProvider.tasks;
      print('🔄 setState called. _filteredTasks.length: ${_filteredTasks.length}');
    });
    
    print('✅ StaffDashboard._loadData() completed');
  }

  Future<void> _applyFilters() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    await taskProvider.filterTasks(
      team: _teamFilter.isEmpty ? null : _teamFilter,
      project: _projectFilter.isEmpty ? null : _projectFilter,
      startDate: _startDate,
      endDate: _endDate,
    );
    
    setState(() {
      _filteredTasks = taskProvider.filteredTasks;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'All';
      _teamFilter = '';
      _projectFilter = '';
      _startDate = null;
      _endDate = null;
    });
    
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.clearFilters();
    setState(() {
      _filteredTasks = taskProvider.tasks;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _applyFilters();
    }
  }

  void _showTaskFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Status Filter',
                  border: OutlineInputBorder(),
                ),
                items: ['All', 'Assigned', 'In Progress', 'Completed', 'Open']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Team Filter',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _teamFilter = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Project Filter',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _projectFilter = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectDateRange,
                      child: const Text('Select Date Range'),
                    ),
                  ),
                ],
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Date Range: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
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
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.search, color: _getThemeColor()),
              const SizedBox(width: 8),
              const Text('Advanced Search'),
              const Spacer(),
              IconButton(
                icon: Icon(_showAdvancedSearch ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setDialogState(() {
                    _showAdvancedSearch = !_showAdvancedSearch;
                  });
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Search
                TextFormField(
                  controller: _taskSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Tasks',
                    hintText: 'Search by title, description, or keywords',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Task Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedTaskStatus,
                  decoration: const InputDecoration(
                    labelText: 'Task Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['All', 'Assigned', 'In Progress', 'Completed', 'Open']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedTaskStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Team and Project Filters
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Team',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            _teamFilter = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Project',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            _projectFilter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Assignee and Assigned By Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTaskAssignee,
                        decoration: const InputDecoration(
                          labelText: 'Assigned To',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Users')),
                          ..._allUsers.map((user) => DropdownMenuItem(
                                value: user.id,
                                child: Text(user.name),
                              )),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedTaskAssignee = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTaskAssignedBy,
                        decoration: const InputDecoration(
                          labelText: 'Assigned By',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Users')),
                          ..._allUsers.map((user) => DropdownMenuItem(
                                value: user.id,
                                child: Text(user.name),
                              )),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedTaskAssignedBy = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Range Filters
                if (_showAdvancedSearch) ...[
                  const Text(
                    'Date Filters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  
                  // Assigned Date Range
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _taskStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                _taskStartDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_taskStartDate != null 
                            ? DateFormat('MMM dd').format(_taskStartDate!)
                            : 'Start Date'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _taskEndDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                _taskEndDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_taskEndDate != null 
                            ? DateFormat('MMM dd').format(_taskEndDate!)
                            : 'End Date'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assigned Date Range',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Due Date Range
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _taskDueStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                _taskDueStartDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(_taskDueStartDate != null 
                            ? DateFormat('MMM dd').format(_taskDueStartDate!)
                            : 'Due Start'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _taskDueEndDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                _taskDueEndDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(_taskDueEndDate != null 
                            ? DateFormat('MMM dd').format(_taskDueEndDate!)
                            : 'Due End'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Due Date Range',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAdvancedFilters();
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyAdvancedFilters();
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAdvancedFilters() {
    setState(() {
      _taskSearchController.clear();
      _selectedTaskStatus = 'All';
      _selectedTaskPriority = 'All';
      _selectedTaskAssignee = 'All';
      _selectedTaskAssignedBy = 'All';
      _taskStartDate = null;
      _taskEndDate = null;
      _taskDueStartDate = null;
      _taskDueEndDate = null;
      _teamFilter = '';
      _projectFilter = '';
    });
    _clearFilters();
  }

  Future<void> _applyAdvancedFilters() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Apply basic filters
    await taskProvider.filterTasks(
      team: _teamFilter.isEmpty ? null : _teamFilter,
      project: _projectFilter.isEmpty ? null : _projectFilter,
      startDate: _taskStartDate,
      endDate: _taskEndDate,
    );
    
    // Apply additional filters
    List<Task> filteredTasks = taskProvider.filteredTasks;
    
    // Filter by status
    if (_selectedTaskStatus != 'All') {
      TaskStatus status;
      switch (_selectedTaskStatus) {
        case 'Assigned':
          status = TaskStatus.assigned;
          break;
        case 'In Progress':
          status = TaskStatus.inProgress;
          break;
        case 'Completed':
          status = TaskStatus.completed;
          break;
        case 'Open':
          status = TaskStatus.open;
          break;
        default:
          status = TaskStatus.assigned;
      }
      filteredTasks = filteredTasks.where((task) => task.status == status).toList();
    }
    
    // Filter by assignee
    if (_selectedTaskAssignee != 'All') {
      filteredTasks = filteredTasks.where((task) => task.assignedTo == _selectedTaskAssignee).toList();
    }
    
    // Filter by assigned by
    if (_selectedTaskAssignedBy != 'All') {
      filteredTasks = filteredTasks.where((task) => task.assignedBy == _selectedTaskAssignedBy).toList();
    }
    
    // Filter by search text
    if (_taskSearchController.text.isNotEmpty) {
      final searchText = _taskSearchController.text.toLowerCase();
      filteredTasks = filteredTasks.where((task) =>
        task.title.toLowerCase().contains(searchText) ||
        task.description.toLowerCase().contains(searchText)
      ).toList();
    }
    
    // Filter by due date range
    if (_taskDueStartDate != null || _taskDueEndDate != null) {
      filteredTasks = filteredTasks.where((task) {
        if (task.dueDate == null) return false;
        
        if (_taskDueStartDate != null && task.dueDate!.isBefore(_taskDueStartDate!)) {
          return false;
        }
        if (_taskDueEndDate != null && task.dueDate!.isAfter(_taskDueEndDate!)) {
          return false;
        }
        return true;
      }).toList();
    }
    
    setState(() {
      _filteredTasks = filteredTasks;
    });
  }

  void _showStudentFilterDialog() {
    final studentListProvider = Provider.of<StudentListProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF667eea)),
              const SizedBox(width: 8),
              const Text('Student Search & Filters'),
              const Spacer(),
              IconButton(
                icon: Icon(_showAdvancedSearch ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setDialogState(() {
                    _showAdvancedSearch = !_showAdvancedSearch;
                  });
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Search
                TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Students',
                    hintText: 'Search by name, email, or mobile',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    studentListProvider.setSearchKeyword(value);
                  },
                ),
                const SizedBox(height: 16),

                // Team and Project Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStudentTeam.isEmpty ? null : _selectedStudentTeam,
                        decoration: const InputDecoration(
                          labelText: 'Team',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Teams')),
                          ...studentListProvider.uniqueTeams.map((team) => DropdownMenuItem(
                            value: team,
                            child: Text(team),
                          )),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedStudentTeam = value ?? '';
                          });
                          studentListProvider.setTeamFilter(value ?? '');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStudentProject.isEmpty ? null : _selectedStudentProject,
                        decoration: const InputDecoration(
                          labelText: 'Project',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Projects')),
                          ...studentListProvider.uniqueProjects.map((project) => DropdownMenuItem(
                            value: project,
                            child: Text(project),
                          )),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedStudentProject = value ?? '';
                          });
                          studentListProvider.setProjectFilter(value ?? '');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status and College Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStudentStatus.isEmpty ? null : _selectedStudentStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Status')),
                          const DropdownMenuItem(value: 'Active', child: Text('Active')),
                          const DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedStudentStatus = value ?? '';
                          });
                          studentListProvider.setStatusFilter(value ?? '');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStudentCollege.isEmpty ? null : _selectedStudentCollege,
                        decoration: const InputDecoration(
                          labelText: 'College',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Colleges')),
                          ...studentListProvider.uniqueColleges.map((college) => DropdownMenuItem(
                            value: college,
                            child: Text(college),
                          )),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedStudentCollege = value ?? '';
                          });
                          studentListProvider.setCollegeFilter(value ?? '');
                        },
                      ),
                    ),
                  ],
                ),

                // Team/Project Not Assigned Filters
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Team Not Assigned'),
                        value: _teamNotAssigned,
                        onChanged: (value) {
                          setDialogState(() {
                            _teamNotAssigned = value ?? false;
                          });
                          studentListProvider.setTeamNotAssigned(value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Project Not Assigned'),
                        value: _projectNotAssigned,
                        onChanged: (value) {
                          setDialogState(() {
                            _projectNotAssigned = value ?? false;
                          });
                          studentListProvider.setProjectNotAssigned(value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),

                // Advanced Filters
                if (_showAdvancedSearch) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Advanced Filters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Work Category and Work Type
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStudentWorkCategory.isEmpty ? null : _selectedStudentWorkCategory,
                          decoration: const InputDecoration(
                            labelText: 'Work Category',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Categories')),
                            ...studentListProvider.uniqueWorkCategories.map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            )),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedStudentWorkCategory = value ?? '';
                            });
                            studentListProvider.setWorkCategoryFilter(value ?? '');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStudentWorkType.isEmpty ? null : _selectedStudentWorkType,
                          decoration: const InputDecoration(
                            labelText: 'Work Type',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Types')),
                            ...studentListProvider.uniqueWorkTypes.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            )),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedStudentWorkType = value ?? '';
                            });
                            studentListProvider.setWorkTypeFilter(value ?? '');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // State and City Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStudentState.isEmpty ? null : _selectedStudentState,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All States')),
                            ...studentListProvider.uniqueStates.map((state) => DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            )),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedStudentState = value ?? '';
                            });
                            studentListProvider.setStateFilter(value ?? '');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStudentCity.isEmpty ? null : _selectedStudentCity,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Cities')),
                            ...studentListProvider.uniqueCities.map((city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            )),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedStudentCity = value ?? '';
                            });
                            studentListProvider.setCityFilter(value ?? '');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Team Leader Filter
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Team Leaders Only'),
                          value: false, // Add state variable if needed
                          onChanged: (value) {
                            // Add team leader filter logic
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                studentListProvider.clearFilters();
                _searchController.clear();
                setDialogState(() {
                  _selectedStudentTeam = '';
                  _selectedStudentProject = '';
                  _selectedStudentStatus = '';
                  _selectedStudentCollege = '';
                  _selectedStudentWorkCategory = '';
                  _selectedStudentWorkType = '';
                  _selectedStudentState = '';
                  _selectedStudentCity = '';
                });
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Apply additional filters if needed
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${task.description}'),
              const SizedBox(height: 8),
              Text('Team: ${task.team}'),
              Text('Project: ${task.project}'),
              Text('Status: ${task.status.name}'),
              Text('Assigned To: ${_getUserName(task.assignedTo)}'),
              Text('Assigned By: ${_getUserName(task.assignedBy)}'),
              Text('Assigned Date: ${DateFormat('MMM dd, yyyy').format(task.assignedDate)}'),
              if (task.dueDate != null)
                Text('Due Date: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}'),
              if (task.startedAt != null)
                Text('Started: ${DateFormat('MMM dd, yyyy HH:mm').format(task.startedAt!)}'),
              if (task.completedAt != null)
                Text('Completed: ${DateFormat('MMM dd, yyyy HH:mm').format(task.completedAt!)}'),
              if (task.timeSpent != null || (task.status == TaskStatus.inProgress && task.startedAt != null))
                Text('Time Spent: ${task.formattedTimeSpent}'),
              if (task.notes != null && task.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(task.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(StudentListItem student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${student.displayEmail}'),
              Text('Mobile: ${student.displayMobile}'),
              Text('College: ${student.displayCollege}'),
              Text('Project: ${student.displayProject}'),
              Text('Team: ${student.displayTeam}'),
              Text('Status: ${student.isActive ? 'Active' : 'Inactive'}'),
              if (student.isTeamLeader) Text('Role: Team Leader'),
              if (student.mentorName != null) Text('Mentor: ${student.mentorName}'),
              if (student.wcName != null) Text('Work Category: ${student.wcName}'),
              if (student.wtName != null) Text('Work Type: ${student.wtName}'),
              if (student.state != null) Text('State: ${student.state}'),
              if (student.city != null) Text('City: ${student.city}'),
              if (student.hobbies != null) Text('Hobbies: ${student.hobbies}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _callStudent(StudentListItem student) async {
    if (student.stdMobile != null && student.stdMobile!.isNotEmpty) {
      final phoneNumber = student.stdMobile!.replaceAll(RegExp(r'[^\d+]'), '');
      final phoneUrl = 'tel:$phoneNumber';
      
      try {
        if (await canLaunchUrl(Uri.parse(phoneUrl))) {
          await launchUrl(Uri.parse(phoneUrl));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot make call to ${student.stdMobile}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error making call: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _emailStudent(StudentListItem student) async {
    if (student.stdEmail != null && student.stdEmail!.isNotEmpty) {
      final email = student.stdEmail!;
      final emailUrl = 'mailto:$email?subject=Message from StartupWorld';
      
      try {
        if (await canLaunchUrl(Uri.parse(emailUrl))) {
          await launchUrl(Uri.parse(emailUrl));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open email app for $email'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening email: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _whatsappStudent(StudentListItem student) async {
    if (student.stdMobile != null && student.stdMobile!.isNotEmpty) {
      String phoneNumber = student.stdMobile!.replaceAll(RegExp(r'[^\d]'), '');
      // If the number is 10 digits, assume it's an Indian number and add '91'
      if (phoneNumber.length == 10) {
        phoneNumber = '91' + phoneNumber;
      }
      // If the number does not start with a country code, add '91' (India)
      if (!phoneNumber.startsWith('91')) {
        phoneNumber = '91' + phoneNumber;
      }
      final whatsappAppUrl = 'whatsapp://send?phone=$phoneNumber&text=Hello ${student.displayName}, I am contacting you from StartupWorld.';
      final whatsappWebUrl = 'https://wa.me/$phoneNumber?text=Hello ${student.displayName}, I am contacting you from StartupWorld.';
      try {
        if (await canLaunchUrl(Uri.parse(whatsappAppUrl))) {
          await launchUrl(Uri.parse(whatsappAppUrl));
        } else if (await canLaunchUrl(Uri.parse(whatsappWebUrl))) {
          await launchUrl(Uri.parse(whatsappWebUrl));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open WhatsApp for ${student.stdMobile}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening WhatsApp: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getUserName(String userId) {
    final user = _allUsers.firstWhere(
      (user) => user.id == userId,
      orElse: () => User(
        id: userId,
        name: 'Unknown User',
        email: 'unknown@example.com',
        userType: UserType.student,
      ),
    );
    return user.name;
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
    
    if (user == null) return const Color(0xFF667eea); // Default blue for staff
    
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
    
    return const Color(0xFF667eea); // Default blue
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

  Map<String, int> _getTaskStats() {
    final allTasks = Provider.of<TaskProvider>(context, listen: false).tasks;
    return {
      'Total': allTasks.length,
      'Assigned': allTasks.where((t) => t.status == TaskStatus.assigned).length,
      'In Progress': allTasks.where((t) => t.status == TaskStatus.inProgress).length,
      'Completed': allTasks.where((t) => t.status == TaskStatus.completed).length,
      'Open': allTasks.where((t) => t.status == TaskStatus.open).length,
    };
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildDashboardTab() {
    return Consumer2<AuthProvider, TaskProvider>(
      builder: (context, authProvider, taskProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = _getTaskStats();
        final displayTasks = _filteredTasks.isNotEmpty ? _filteredTasks : taskProvider.tasks;
        
        // Responsive grid variables with better spacing
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth < 600 ? 2 : 4;
        final childAspectRatio = screenWidth < 600 ? 1.8 : 2.5; // Adjusted aspect ratio
        final spacing = screenWidth < 600 ? 12.0 : 16.0; // Adjusted spacing
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildStatCard('Total Tasks', stats['Total']!, Colors.blue),
                  _buildStatCard('Assigned', stats['Assigned']!, Colors.orange),
                  _buildStatCard('In Progress', stats['In Progress']!, Colors.blue),
                  _buildStatCard('Completed', stats['Completed']!, Colors.green),
                ],
              ),
              const SizedBox(height: 24),

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

              if (displayTasks.isEmpty)
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
                          'No tasks found',
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
                  itemCount: displayTasks.take(5).length,
                  itemBuilder: (context, index) {
                    final task = displayTasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${task.team} • ${task.project}',
                          style: TextStyle(color: Colors.grey[600]),
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
        );
      },
    );
  }

  Widget _buildTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final displayTasks = _filteredTasks.isNotEmpty ? _filteredTasks : taskProvider.tasks;
        
        print('🔄 _buildTasksTab() called');
        print('   _filteredTasks.length: ${_filteredTasks.length}');
        print('   taskProvider.tasks.length: ${taskProvider.tasks.length}');
        print('   displayTasks.length: ${displayTasks.length}');
        print('   taskProvider.isLoading: ${taskProvider.isLoading}');
        print('   taskProvider.errorMessage: ${taskProvider.errorMessage}');

        return Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskSearchController,
                          decoration: const InputDecoration(
                            hintText: 'Search tasks by title, description...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            // Apply search filter
                            if (value.isEmpty) {
                              setState(() {
                                _filteredTasks = taskProvider.tasks;
                              });
                            } else {
                              final searchText = value.toLowerCase();
                              setState(() {
                                _filteredTasks = taskProvider.tasks.where((task) =>
                                  task.title.toLowerCase().contains(searchText) ||
                                  task.description.toLowerCase().contains(searchText) ||
                                  task.team.toLowerCase().contains(searchText) ||
                                  task.project.toLowerCase().contains(searchText)
                                ).toList();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showAdvancedSearchDialog,
                        icon: const Icon(Icons.tune),
                        tooltip: 'Advanced Search',
                        style: IconButton.styleFrom(
                          backgroundColor: _getThemeColor(),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showTaskFilterDialog,
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Quick Filters',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          print('🔄 Manual refresh triggered');
                          try {
                            final taskService = TaskService();
                            List<Task> tasks = await taskService.getAllStudentTasksForStaff();
                            print('📥 Refreshed tasks count: ${tasks.length}');
                            
                            // If no tasks found, try without date filter
                            if (tasks.isEmpty) {
                              print('⚠️ No tasks found with date filter, trying without date filter...');
                              tasks = await taskService.getAllStudentTasksForStaffNoDateFilter();
                              print('📥 Refreshed tasks count (no date filter): ${tasks.length}');
                            }
                            
                            // If still no tasks found, try the old API endpoint
                            if (tasks.isEmpty) {
                              print('⚠️ No tasks found with new endpoint, trying old API endpoint...');
                              tasks = await taskService.tryOldApiEndpoint();
                              print('📥 Refreshed tasks count (old endpoint): ${tasks.length}');
                            }
                            
                            final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                            taskProvider.setTasks(tasks);
                            
                            setState(() {
                              _filteredTasks = tasks;
                            });
                          } catch (e) {
                            print('❌ Error refreshing tasks: $e');
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Tasks',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[200],
                          foregroundColor: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          print('🧪 Test API endpoint triggered');
                          try {
                            final taskService = TaskService();
                            await taskService.testApiEndpoint();
                          } catch (e) {
                            print('❌ Error testing API endpoint: $e');
                          }
                        },
                        icon: const Icon(Icons.bug_report),
                        tooltip: 'Test API',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange[200],
                          foregroundColor: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Quick Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedFilter == 'All',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'All';
                            });
                            _clearFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Assigned'),
                          selected: _selectedFilter == 'Assigned',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'Assigned';
                            });
                            _applyStatusFilter(TaskStatus.assigned);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('In Progress'),
                          selected: _selectedFilter == 'In Progress',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'In Progress';
                            });
                            _applyStatusFilter(TaskStatus.inProgress);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Completed'),
                          selected: _selectedFilter == 'Completed',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'Completed';
                            });
                            _applyStatusFilter(TaskStatus.completed);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Open'),
                          selected: _selectedFilter == 'Open',
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = 'Open';
                            });
                            _applyStatusFilter(TaskStatus.open);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filter Summary
            if (_selectedFilter != 'All' || _teamFilter.isNotEmpty || _projectFilter.isNotEmpty || _startDate != null || _taskSearchController.text.isNotEmpty)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Filters:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_selectedFilter != 'All')
                            Chip(label: Text('Status: $_selectedFilter')),
                          if (_teamFilter.isNotEmpty)
                            Chip(label: Text('Team: $_teamFilter')),
                          if (_projectFilter.isNotEmpty)
                            Chip(label: Text('Project: $_projectFilter')),
                          if (_startDate != null && _endDate != null)
                            Chip(label: Text('Date: ${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}')),
                          if (_taskSearchController.text.isNotEmpty)
                            Chip(label: Text('Search: ${_taskSearchController.text}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

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
                        'Showing ${displayTasks.length} of ${taskProvider.tasks.length} tasks',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Show status breakdown
                  if (displayTasks.isNotEmpty) ...[
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
                              '${displayTasks.where((t) => t.status == TaskStatus.assigned).length} Assigned',
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
                              '${displayTasks.where((t) => t.status == TaskStatus.inProgress).length} In Progress',
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
                              '${displayTasks.where((t) => t.status == TaskStatus.completed).length} Completed',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_selectedFilter != 'All' || _teamFilter.isNotEmpty || _projectFilter.isNotEmpty || _startDate != null || _taskSearchController.text.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Filtered',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
                  : displayTasks.isEmpty
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
                                'No tasks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or create new tasks',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (taskProvider.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Error: ${taskProvider.errorMessage}',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayTasks.length,
                          itemBuilder: (context, index) {
                            final task = displayTasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(task.description),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.group, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.team,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.work, size: 14, color: Colors.grey[600]),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      'Assigned to: ${_getUserName(task.assignedTo)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Date: ${DateFormat('MMM dd, yyyy').format(task.assignedDate)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () => _showTaskDetails(task),
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

  void _applyStatusFilter(TaskStatus status) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    setState(() {
      _filteredTasks = taskProvider.tasks.where((task) => task.status == status).toList();
    });
  }

  Widget _buildStudentsTab() {
    return Consumer<StudentListProvider>(
      builder: (context, studentListProvider, child) {
        return Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search students...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        studentListProvider.setSearchKeyword(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _showStudentFilterDialog,
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filter Students',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      print('🧪 Test search functionality');
                      final studentListProvider = Provider.of<StudentListProvider>(context, listen: false);
                      print('🧪 Current students: ${studentListProvider.students.length}');
                      print('🧪 Filtered students: ${studentListProvider.filteredStudents.length}');
                      print('🧪 Search keyword: "${studentListProvider.searchKeyword}"');
                      
                      // Test search with a simple keyword
                      studentListProvider.setSearchKeyword('test');
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test search completed - check console for details'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    tooltip: 'Test Search',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange[200],
                      foregroundColor: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),

            // Student Count Display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${studentListProvider.filteredStudents.length} of ${studentListProvider.students.length} students',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (studentListProvider.searchKeyword.isNotEmpty ||
                      studentListProvider.selectedTeam.isNotEmpty ||
                      studentListProvider.selectedProject.isNotEmpty ||
                      studentListProvider.selectedStatus.isNotEmpty ||
                      studentListProvider.selectedCollege.isNotEmpty ||
                      studentListProvider.selectedWorkCategory.isNotEmpty ||
                      studentListProvider.selectedWorkType.isNotEmpty ||
                      studentListProvider.selectedState.isNotEmpty ||
                      studentListProvider.selectedCity.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Filtered',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Filter Summary
            if (studentListProvider.searchKeyword.isNotEmpty ||
                studentListProvider.selectedTeam.isNotEmpty ||
                studentListProvider.selectedProject.isNotEmpty ||
                studentListProvider.selectedStatus.isNotEmpty ||
                studentListProvider.selectedCollege.isNotEmpty ||
                studentListProvider.selectedWorkCategory.isNotEmpty ||
                studentListProvider.selectedWorkType.isNotEmpty ||
                studentListProvider.selectedState.isNotEmpty ||
                studentListProvider.selectedCity.isNotEmpty)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Filters:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              studentListProvider.clearFilters();
                              _searchController.clear();
                              setState(() {
                                _selectedStudentTeam = '';
                                _selectedStudentProject = '';
                                _selectedStudentStatus = '';
                                _selectedStudentCollege = '';
                                _selectedStudentWorkCategory = '';
                                _selectedStudentWorkType = '';
                                _selectedStudentState = '';
                                _selectedStudentCity = '';
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (studentListProvider.searchKeyword.isNotEmpty)
                            Chip(label: Text('Search: ${studentListProvider.searchKeyword}')),
                          if (studentListProvider.selectedTeam.isNotEmpty)
                            Chip(label: Text('Team: ${studentListProvider.selectedTeam}')),
                          if (studentListProvider.selectedProject.isNotEmpty)
                            Chip(label: Text('Project: ${studentListProvider.selectedProject}')),
                          if (studentListProvider.selectedStatus.isNotEmpty)
                            Chip(label: Text('Status: ${studentListProvider.selectedStatus}')),
                          if (studentListProvider.selectedCollege.isNotEmpty)
                            Chip(label: Text('College: ${studentListProvider.selectedCollege}')),
                          if (studentListProvider.selectedWorkCategory.isNotEmpty)
                            Chip(label: Text('Work Category: ${studentListProvider.selectedWorkCategory}')),
                          if (studentListProvider.selectedWorkType.isNotEmpty)
                            Chip(label: Text('Work Type: ${studentListProvider.selectedWorkType}')),
                          if (studentListProvider.selectedState.isNotEmpty)
                            Chip(label: Text('State: ${studentListProvider.selectedState}')),
                          if (studentListProvider.selectedCity.isNotEmpty)
                            Chip(label: Text('City: ${studentListProvider.selectedCity}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Students List
            Expanded(
              child: studentListProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : studentListProvider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading students',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                studentListProvider.errorMessage!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  studentListProvider.clearError();
                                  studentListProvider.loadStudentList();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : studentListProvider.filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No students found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or filters',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: studentListProvider.filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = studentListProvider.filteredStudents[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.person, size: 32, color: Colors.blueGrey),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      student.displayName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: student.isActive ? Colors.green : Colors.grey,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      student.isActive ? 'ACTIVE' : 'INACTIVE',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student.displayCollege,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(student.displayEmail),
                                              Text(student.displayMobile),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(Icons.school, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      student.displayCollege,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.work, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    student.displayProject,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Icon(Icons.group, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    student.displayTeam,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (student.isTeamLeader) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.star, size: 14, color: Colors.amber),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Team Leader',
                                                      style: TextStyle(
                                                        color: Colors.amber[600],
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const Divider(height: 16, thickness: 1),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Flexible(
                                                    flex: 1,
                                                    child: InkWell(
                                                      onTap: () => _callStudent(student),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.call, size: 14, color: Colors.green[700]),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Call',
                                                              style: TextStyle(
                                                                color: Colors.green[700],
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    flex: 1,
                                                    child: InkWell(
                                                      onTap: () => _emailStudent(student),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.email, size: 14, color: Colors.blue[700]),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Email',
                                                              style: TextStyle(
                                                                color: Colors.blue[700],
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    flex: 1,
                                                    child: InkWell(
                                                      onTap: () => _whatsappStudent(student),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.chat, size: 13, color: Colors.green[700]),
                                                            const SizedBox(width: 3),
                                                            Text(
                                                              'WhatsApp',
                                                              style: TextStyle(
                                                                color: Colors.green[700],
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline),
                                          onPressed: () => _showStudentDetails(student),
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

  Widget _buildReportsTab() {
    return const AttendanceApprovalScreen();
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
              if (_currentIndex == 1) // Tasks tab
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _showAdvancedSearchDialog,
                      tooltip: 'Advanced Search',
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showTaskFilterDialog,
                      tooltip: 'Quick Filters',
                    ),
                  ],
                ),
              if (_currentIndex == 2) // Students tab
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showStudentFilterDialog,
                      tooltip: 'Filter Students',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        final studentListProvider = Provider.of<StudentListProvider>(context, listen: false);
                        studentListProvider.loadStudentList();
                      },
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          drawer: AppDrawer(user: user, themeColor: _getThemeColor()),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardTab(),
              _buildTasksTab(),
              _buildStudentsTab(),
              _buildReportsTab(),
            ],
          ),
          bottomNavigationBar: StaffBottomNavigation(
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
              : _currentIndex == 3 // Attendance tab
                  ? FloatingActionButton(
                      onPressed: () {
                        _showMarkAttendanceDialog();
                      },
                      backgroundColor: _getThemeColor(),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.person_add),
                    )
                  : null,
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Staff Dashboard';
      case 1:
        return 'Task Management';
      case 2:
        return 'Student List';
      case 3:
        return 'Attendance Approvals';
      default:
        return 'Staff Dashboard';
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

  void _showMarkAttendanceDialog() {
    final TextEditingController notesController = TextEditingController();
    String selectedUserId = '';
    bool isPresent = true;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mark Attendance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User selection
                DropdownButtonFormField<String>(
                  value: selectedUserId.isEmpty ? null : selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Select Student',
                    border: OutlineInputBorder(),
                  ),
                  items: _allUsers
                      .where((user) => user.userType == UserType.student)
                      .map((user) => DropdownMenuItem(
                            value: user.id,
                            child: Text(user.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Date selection
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Present/Absent toggle
                Row(
                  children: [
                    const Text('Status: '),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Present'),
                      selected: isPresent,
                      onSelected: (selected) {
                        setState(() {
                          isPresent = selected;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Absent'),
                      selected: !isPresent,
                      onSelected: (selected) {
                        setState(() {
                          isPresent = !selected;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
              onPressed: selectedUserId.isEmpty
                  ? null
                  : () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
                      
                      final selectedUser = _allUsers.firstWhere((user) => user.id == selectedUserId);
                      
                      final success = await attendanceProvider.markAttendance(
                        selectedUser.id,
                        selectedUser.name,
                        selectedUser.email,
                        selectedDate,
                        isPresent,
                        selectedUser.userType,
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      );
                      
                      if (success && mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Attendance marked for ${selectedUser.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(attendanceProvider.errorMessage ?? 'Failed to mark attendance'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Mark Attendance'),
            ),
          ],
        ),
      ),
    );
  }
} 