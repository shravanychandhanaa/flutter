import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedUserId = 'all';
  List<User> _allUsers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    _allUsers = await authProvider.getAllUsers();
    await attendanceProvider.loadAllAttendance();
    await attendanceProvider.loadOverallStats();
    
    setState(() {});
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

  Future<void> _applyFilters() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    await attendanceProvider.loadAllAttendance(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    await attendanceProvider.loadOverallStats(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    if (_selectedUserId != 'all') {
      await attendanceProvider.loadUserStats(
        _selectedUserId,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedUserId = 'all';
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StartupWorld - Attendance Report'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer2<AuthProvider, AttendanceProvider>(
        builder: (context, authProvider, attendanceProvider, child) {
          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Summary
                  if (_startDate != null || _endDate != null || _selectedUserId != 'all')
                    Card(
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
                                if (_selectedUserId != 'all')
                                  Chip(label: Text('User: ${_getUserName(_selectedUserId)}')),
                                if (_startDate != null && _endDate != null)
                                  Chip(label: Text('Date: ${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Overall Statistics
                  if (attendanceProvider.overallStats != null) ...[
                    const Text(
                      'Overall Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        _buildStatCard(
                          'Total Records',
                          attendanceProvider.overallStats!['totalRecords'].toString(),
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Present',
                          attendanceProvider.overallStats!['presentRecords'].toString(),
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Absent',
                          attendanceProvider.overallStats!['absentRecords'].toString(),
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Attendance Rate',
                          '${attendanceProvider.overallStats!['overallAttendanceRate'].toStringAsFixed(1)}%',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Individual User Statistics
                  if (_selectedUserId != 'all' && attendanceProvider.userStats != null) ...[
                    const Text(
                      'Individual Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        _buildStatCard(
                          'Total Days',
                          attendanceProvider.userStats!['totalDays'].toString(),
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Present Days',
                          attendanceProvider.userStats!['presentDays'].toString(),
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Absent Days',
                          attendanceProvider.userStats!['absentDays'].toString(),
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Attendance Rate',
                          '${attendanceProvider.userStats!['attendanceRate'].toStringAsFixed(1)}%',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Attendance Records
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance Records',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${attendanceProvider.allAttendance.length} records',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (attendanceProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (attendanceProvider.allAttendance.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                color: Colors.grey[500],
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
                      itemCount: attendanceProvider.allAttendance.length,
                      itemBuilder: (context, index) {
                        final attendance = attendanceProvider.allAttendance[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: attendance.isPresent ? Colors.green : Colors.red,
                              child: Icon(
                                attendance.isPresent ? Icons.check : Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              attendance.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${DateFormat('MMM dd, yyyy').format(attendance.date)}'),
                                if (attendance.checkInTime != null)
                                  Text('Check In: ${attendance.formattedCheckInTime}'),
                                if (attendance.checkOutTime != null)
                                  Text('Check Out: ${attendance.formattedCheckOutTime}'),
                                if (attendance.totalHours != null)
                                  Text('Hours: ${attendance.formattedTotalHours}'),
                                if (attendance.notes != null && attendance.notes!.isNotEmpty)
                                  Text('Notes: ${attendance.notes}'),
                              ],
                            ),
                            trailing: attendance.isCheckedIn
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Attendance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Select User',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All Users'),
                  ),
                  ..._allUsers.map((user) => DropdownMenuItem(
                    value: user.id,
                    child: Text(user.name),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value!;
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 