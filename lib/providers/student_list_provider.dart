import 'package:flutter/foundation.dart';
import '../models/student_list_item.dart';
import '../services/api_service.dart';

class StudentListProvider with ChangeNotifier {
  List<StudentListItem> _students = [];
  List<StudentListItem> _filteredStudents = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filter variables
  String _searchKeyword = '';
  String _selectedTeam = '';
  String _selectedProject = '';
  String _selectedStatus = '';
  String _selectedCollege = '';
  String _selectedWorkCategory = '';
  String _selectedWorkType = '';
  String _selectedActivityStatus = '';
  String _selectedTeamLeader = '';
  String _selectedState = '';
  String _selectedCity = '';
  String _fromDate = '';
  String _toDate = '';

  // Getters
  List<StudentListItem> get students => _students;
  List<StudentListItem> get filteredStudents => _filteredStudents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Filter getters
  String get searchKeyword => _searchKeyword;
  String get selectedTeam => _selectedTeam;
  String get selectedProject => _selectedProject;
  String get selectedStatus => _selectedStatus;
  String get selectedCollege => _selectedCollege;
  String get selectedWorkCategory => _selectedWorkCategory;
  String get selectedWorkType => _selectedWorkType;
  String get selectedActivityStatus => _selectedActivityStatus;
  String get selectedTeamLeader => _selectedTeamLeader;
  String get selectedState => _selectedState;
  String get selectedCity => _selectedCity;
  String get fromDate => _fromDate;
  String get toDate => _toDate;

  // Get unique values for filter dropdowns
  List<String> get uniqueTeams => _students.map((s) => s.displayTeam).where((t) => t.isNotEmpty).toSet().toList()..sort();
  List<String> get uniqueProjects => _students.map((s) => s.displayProject).where((p) => p.isNotEmpty).toSet().toList()..sort();
  List<String> get uniqueColleges => _students.map((s) => s.displayCollege).where((c) => c.isNotEmpty).toSet().toList()..sort();
  List<String> get uniqueWorkCategories => _students.map((s) => s.wcName ?? '').where((w) => w.isNotEmpty).toSet().toList()..sort();
  List<String> get uniqueWorkTypes => _students.map((s) => s.wtName ?? '').where((w) => w.isNotEmpty).toSet().toList()..sort();
  List<String> get uniqueStates => _students.map((s) => s.state ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort();
  List<String> get uniqueCities => _students.map((s) => s.city ?? '').where((c) => c.isNotEmpty).toSet().toList()..sort();

  // Load student list from API
  Future<void> loadStudentList() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear search keyword to get all students
      _searchKeyword = '';

      final response = await ApiService.getStudentList({
        'SL_search': 1,
        'keyword': '', // Empty keyword to get all students
        'teams': '',
        'project': '',
        'status': '',
        'cname': '',
        'work_cat': '',
        'work_type': '',
        'activity_status': '',
        'teamleader': '',
        'fromdate': '',
        'todate': '',
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        print('📥 Student list response: $responseData');
        
        if (responseData['responseStatus'] == 200) {
          final staffDetails = responseData['Staff_Details'] as List? ?? [];
          _students = staffDetails.map<StudentListItem>((json) => StudentListItem.fromJson(json)).toList();
          _applyFilters();
          print('✅ Loaded ${_students.length} students');
        } else {
          _errorMessage = responseData['responseMessage'] ?? 'Failed to load students';
          print('❌ API Error: $_errorMessage');
        }
      } else {
        _errorMessage = 'Network error: ${response.statusCode}';
        print('❌ Network Error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Failed to load students: $e';
      print('❌ Load students error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search students with keyword
  Future<void> searchStudents(String keyword) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _searchKeyword = keyword;

      final response = await ApiService.getStudentList({
        'SL_search': 1,
        'keyword': keyword,
        'teams': _selectedTeam,
        'project': _selectedProject,
        'status': _selectedStatus,
        'cname': _selectedCollege,
        'work_cat': _selectedWorkCategory,
        'work_type': _selectedWorkType,
        'activity_status': _selectedActivityStatus,
        'teamleader': _selectedTeamLeader,
        'fromdate': _fromDate,
        'todate': _toDate,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['responseStatus'] == 200) {
          final staffDetails = responseData['Staff_Details'] as List? ?? [];
          _students = staffDetails.map<StudentListItem>((json) => StudentListItem.fromJson(json)).toList();
          _applyFilters();
          print('✅ Found ${_students.length} students for keyword: $keyword');
        } else {
          _errorMessage = responseData['responseMessage'] ?? 'Failed to search students';
          print('❌ Search API Error: $_errorMessage');
        }
      } else {
        _errorMessage = 'Network error: ${response.statusCode}';
        print('❌ Search Network Error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Failed to search students: $e';
      print('❌ Search students error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apply filters to the student list
  void _applyFilters() {
    _filteredStudents = _students.where((student) {
      // Keyword search
      if (_searchKeyword.isNotEmpty) {
        final keyword = _searchKeyword.toLowerCase();
        final matchesKeyword = student.displayName.toLowerCase().contains(keyword) ||
                              student.displayEmail.toLowerCase().contains(keyword) ||
                              student.displayMobile.contains(keyword) ||
                              student.displayCollege.toLowerCase().contains(keyword) ||
                              student.displayProject.toLowerCase().contains(keyword);
        if (!matchesKeyword) return false;
      }

      // Team filter
      if (_selectedTeam.isNotEmpty && student.displayTeam != _selectedTeam) {
        return false;
      }

      // Project filter
      if (_selectedProject.isNotEmpty && student.displayProject != _selectedProject) {
        return false;
      }

      // Status filter
      if (_selectedStatus.isNotEmpty) {
        if (_selectedStatus == 'Active' && !student.isActive) return false;
        if (_selectedStatus == 'Inactive' && student.isActive) return false;
      }

      // College filter
      if (_selectedCollege.isNotEmpty && student.displayCollege != _selectedCollege) {
        return false;
      }

      // Work category filter
      if (_selectedWorkCategory.isNotEmpty && student.wcName != _selectedWorkCategory) {
        return false;
      }

      // Work type filter
      if (_selectedWorkType.isNotEmpty && student.wtName != _selectedWorkType) {
        return false;
      }

      // Activity status filter
      if (_selectedActivityStatus.isNotEmpty && student.userStatus != _selectedActivityStatus) {
        return false;
      }

      // Team leader filter
      if (_selectedTeamLeader.isNotEmpty) {
        if (_selectedTeamLeader == 'Yes' && !student.isTeamLeader) return false;
        if (_selectedTeamLeader == 'No' && student.isTeamLeader) return false;
      }

      // State filter
      if (_selectedState.isNotEmpty && student.state != _selectedState) {
        return false;
      }

      // City filter
      if (_selectedCity.isNotEmpty && student.city != _selectedCity) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Set search keyword
  void setSearchKeyword(String keyword) {
    if (keyword.isEmpty) {
      // If keyword is empty, load all students
      loadStudentList();
    } else {
      // If keyword is provided, search for students
      searchStudents(keyword);
    }
  }

  // Set team filter
  void setTeamFilter(String team) {
    _selectedTeam = team;
    _applyFilters();
  }

  // Set project filter
  void setProjectFilter(String project) {
    _selectedProject = project;
    _applyFilters();
  }

  // Set status filter
  void setStatusFilter(String status) {
    _selectedStatus = status;
    _applyFilters();
  }

  // Set college filter
  void setCollegeFilter(String college) {
    _selectedCollege = college;
    _applyFilters();
  }

  // Set work category filter
  void setWorkCategoryFilter(String workCategory) {
    _selectedWorkCategory = workCategory;
    _applyFilters();
  }

  // Set work type filter
  void setWorkTypeFilter(String workType) {
    _selectedWorkType = workType;
    _applyFilters();
  }

  // Set activity status filter
  void setActivityStatusFilter(String activityStatus) {
    _selectedActivityStatus = activityStatus;
    _applyFilters();
  }

  // Set team leader filter
  void setTeamLeaderFilter(String teamLeader) {
    _selectedTeamLeader = teamLeader;
    _applyFilters();
  }

  // Set state filter
  void setStateFilter(String state) {
    _selectedState = state;
    _applyFilters();
  }

  // Set city filter
  void setCityFilter(String city) {
    _selectedCity = city;
    _applyFilters();
  }

  // Set date range
  void setDateRange(String fromDate, String toDate) {
    _fromDate = fromDate;
    _toDate = toDate;
    loadStudentList(); // Reload with date filters
  }

  // Clear all filters
  void clearFilters() {
    _searchKeyword = '';
    _selectedTeam = '';
    _selectedProject = '';
    _selectedStatus = '';
    _selectedCollege = '';
    _selectedWorkCategory = '';
    _selectedWorkType = '';
    _selectedActivityStatus = '';
    _selectedTeamLeader = '';
    _selectedState = '';
    _selectedCity = '';
    _fromDate = '';
    _toDate = '';
    _applyFilters();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all filters and reload all students
  Future<void> clearAllFilters() async {
    _searchKeyword = '';
    _selectedTeam = '';
    _selectedProject = '';
    _selectedStatus = '';
    _selectedCollege = '';
    _selectedWorkCategory = '';
    _selectedWorkType = '';
    _selectedActivityStatus = '';
    _selectedTeamLeader = '';
    _selectedState = '';
    _selectedCity = '';
    _fromDate = '';
    _toDate = '';
    
    await loadStudentList();
  }
} 