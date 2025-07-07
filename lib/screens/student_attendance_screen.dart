import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../screens/student_dashboard.dart';
import '../screens/staff_dashboard.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isMarkingAttendance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayAttendance();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayAttendance() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await attendanceProvider.loadTodayAttendance(authProvider.currentUser!.id);
    }
  }

  Future<void> _markAttendancePresent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;

    // Check if user email is available
    final userEmail = authProvider.currentUser!.email;
    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not available. Please contact administrator.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isMarkingAttendance = true;
    });

    try {
      final success = await attendanceProvider.markAttendancePresent(
        authProvider.currentUser!.id,
        authProvider.currentUser!.name,
        userEmail,
        authProvider.currentUser!.userType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (success && mounted) {
        _notesController.clear();
        await _loadTodayAttendance();
        // Auto-navigate to dashboard after marking attendance
        final userType = authProvider.currentUser!.userType;
        if (userType == UserType.student) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
            (route) => false,
          );
        } else if (userType == UserType.staff) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const StaffDashboard()),
            (route) => false,
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceProvider.errorMessage ?? 'Failed to mark attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAttendance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AttendanceProvider, AuthProvider>(
        builder: (context, attendanceProvider, authProvider, child) {
          final todayAttendance = attendanceProvider.todayAttendance;
          final currentUser = authProvider.currentUser;

          if (currentUser == null) {
            return const Center(
              child: Text('Please log in to mark attendance'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Today's date
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Today\'s Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current attendance status
                if (todayAttendance != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                todayAttendance.isPresent ? Icons.check_circle : Icons.cancel,
                                color: todayAttendance.isPresent ? Colors.green : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todayAttendance.isPresent ? 'Present' : 'Absent',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: todayAttendance.isPresent ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildStatusChip(todayAttendance.status),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (todayAttendance.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Notes:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              todayAttendance.notes!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                          if (todayAttendance.rejectionReason?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              todayAttendance.rejectionReason!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ],
                          if (todayAttendance.status == AttendanceStatus.rejected && todayAttendance.approvedBy != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Rejected by:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              todayAttendance.approvedBy!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ],
                          if (todayAttendance.status == AttendanceStatus.approved && todayAttendance.approvedBy != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Approved by:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              todayAttendance.approvedBy!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Mark attendance form
                if (todayAttendance == null || !todayAttendance.isPresent) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mark Attendance as Present',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'Add any notes about your attendance...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isMarkingAttendance ? null : _markAttendancePresent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isMarkingAttendance
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Mark as Present',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Information card
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Attendance Approval Process',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'When you mark yourself as present, your attendance will be sent to staff for approval. You will be notified once it is approved or rejected.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case AttendanceStatus.pending:
        color = Colors.orange;
        text = 'Pending Approval';
        icon = Icons.schedule;
        break;
      case AttendanceStatus.approved:
        color = Colors.green;
        text = 'Approved';
        icon = Icons.check_circle;
        break;
      case AttendanceStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 