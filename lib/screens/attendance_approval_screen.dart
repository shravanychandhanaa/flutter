import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../screens/attendance_report_screen.dart';

class AttendanceApprovalScreen extends StatefulWidget {
  const AttendanceApprovalScreen({super.key});

  @override
  State<AttendanceApprovalScreen> createState() => _AttendanceApprovalScreenState();
}

class _AttendanceApprovalScreenState extends State<AttendanceApprovalScreen> {
  final TextEditingController _rejectionReasonController = TextEditingController();
  String _selectedFilter = 'all'; // all, students, staff

  // For attendance report filters
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedUserId = 'all';
  List<User> _allUsers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingApprovals();
      _loadReportUsers();
    });
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingApprovals() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    await attendanceProvider.loadPendingStudentApprovals();
    await attendanceProvider.loadPendingStaffApprovals();
  }

  Future<void> _loadReportUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _allUsers = await authProvider.getAllUsers();
    setState(() {});
  }

  Future<void> _approveAttendance(Attendance attendance) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;

    final success = await attendanceProvider.approveAttendance(
      attendance.id,
      authProvider.currentUser!.name,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${attendance.userName}\'s attendance approved'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attendanceProvider.errorMessage ?? 'Failed to approve attendance'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAttendance(Attendance attendance) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;

    // Show rejection reason dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(_rejectionReasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      final success = await attendanceProvider.rejectAttendance(
        attendance.id,
        authProvider.currentUser!.name,
        reason,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${attendance.userName}\'s attendance rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _rejectionReasonController.clear();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceProvider.errorMessage ?? 'Failed to reject attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Attendance> _getFilteredApprovals() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    switch (_selectedFilter) {
      case 'students':
        return attendanceProvider.pendingStudentApprovals;
      case 'staff':
        return attendanceProvider.pendingStaffApprovals;
      default:
        return [
          ...attendanceProvider.pendingStudentApprovals,
          ...attendanceProvider.pendingStaffApprovals,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AttendanceProvider, AuthProvider>(
      builder: (context, attendanceProvider, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final pendingApprovals = _getFilteredApprovals();

        if (currentUser == null) {
          return const Center(
            child: Text('Please log in to view approvals'),
          );
        }

        final noPending = attendanceProvider.pendingStudentApprovals.isEmpty && attendanceProvider.pendingStaffApprovals.isEmpty;

        // Always show filter icon at the top
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showReportFilterDialog,
                ),
              ],
            ),
            Expanded(
              child: noPending
                  ? _buildAttendanceReportBody(context, attendanceProvider)
                  : _ApprovalsListNoAppBar(
                      pendingApprovals: pendingApprovals,
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (value) => setState(() => _selectedFilter = value),
                      approveAttendance: _approveAttendance,
                      rejectAttendance: _rejectAttendance,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceReportBody(BuildContext context, AttendanceProvider attendanceProvider) {
    return RefreshIndicator(
      onRefresh: () async {
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
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            onPressed: _clearReportFilters,
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
                            Chip(label: Text('Date: \\${DateFormat('MMM dd').format(_startDate!)} - \\${DateFormat('MMM dd').format(_endDate!)}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (attendanceProvider.overallStats != null) ...[
              const Text(
                'Overall Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Records',
                          attendanceProvider.overallStats!['totalRecords'].toString(),
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Present',
                          attendanceProvider.overallStats!['presentRecords'].toString(),
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Absent',
                          attendanceProvider.overallStats!['absentRecords'].toString(),
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Attendance Rate',
                          '${attendanceProvider.overallStats!['overallAttendanceRate'].toStringAsFixed(1)}%',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
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
                          if (attendance.status == AttendanceStatus.rejected && attendance.rejectionReason?.isNotEmpty == true)
                            Text('Rejection: ${attendance.rejectionReason}', style: const TextStyle(color: Colors.red)),
                          if (attendance.status == AttendanceStatus.rejected && attendance.approvedBy != null)
                            Text('Rejected by: ${attendance.approvedBy}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                          if (attendance.status == AttendanceStatus.approved && attendance.approvedBy != null)
                            Text('Approved by: ${attendance.approvedBy}', style: const TextStyle(color: Colors.green, fontSize: 12)),
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
  }

  void _showReportFilterDialog() {
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
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Approval Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All Approvals'),
                  ),
                  DropdownMenuItem(
                    value: 'students',
                    child: Text('Student Attendance Approvals'),
                  ),
                  DropdownMenuItem(
                    value: 'staff',
                    child: Text('Staff Attendance Approvals'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
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
                  'Date Range: \\${DateFormat('MMM dd, yyyy').format(_startDate!)} - \\${DateFormat('MMM dd, yyyy').format(_endDate!)}',
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
              setState(() {}); // To trigger UI update
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _clearReportFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedUserId = 'all';
    });
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    attendanceProvider.loadAllAttendance();
    attendanceProvider.loadOverallStats();
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

  String _getFilterText() {
    switch (_selectedFilter) {
      case 'students':
        return 'Student Approvals';
      case 'staff':
        return 'Staff Approvals';
      default:
        return 'All Pending Approvals';
    }
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
  }
}

// Helper widget for Approvals list without AppBar or filter icon
class _ApprovalsListNoAppBar extends StatelessWidget {
  final List<Attendance> pendingApprovals;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function(Attendance) approveAttendance;
  final Future<void> Function(Attendance) rejectAttendance;

  const _ApprovalsListNoAppBar({
    required this.pendingApprovals,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.approveAttendance,
    required this.rejectAttendance,
  });

  @override
  Widget build(BuildContext context) {
    // ... Copy the approvals list UI here, but exclude the AppBar and filter icon ...
    return ListView.builder(
      itemCount: pendingApprovals.length,
      itemBuilder: (context, index) {
        final approval = pendingApprovals[index];
        // ... Build each approval item ...
        return ListTile(
          title: Text(approval.userName),
          // ... other fields ...
        );
      },
    );
  }
} 