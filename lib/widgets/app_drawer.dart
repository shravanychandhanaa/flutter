import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/create_task_screen.dart';
import '../screens/attendance_report_screen.dart';
import '../screens/terms_conditions_screen.dart';
import '../screens/delete_user_data_screen.dart';
import '../screens/crm_screen.dart'; // Import the new CRM screen

class AppDrawer extends StatelessWidget {
  final User user;
  final Color themeColor;

  const AppDrawer({super.key, required this.user, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // User info header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: themeColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
            accountName: Text(
              user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              user.email,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),

          // Navigation items - Make it scrollable
          Expanded(
            child: Container(
              height: MediaQuery.of(context).size.height - 200, // Ensure proper height
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  children: [
                    // Dashboard
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // Navigate to appropriate dashboard
                        if (user.userType == UserType.staff) {
                          Navigator.of(context).pushReplacementNamed('/staff-dashboard');
                        } else {
                          Navigator.of(context).pushReplacementNamed('/student-dashboard');
                        }
                      },
                    ),

                    // Tasks section
                    if (user.userType == UserType.staff) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Task Management',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.task),
                        title: const Text('All Tasks'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacementNamed('/staff-dashboard');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.add_task),
                        title: const Text('Create Task'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateTaskScreen(),
                            ),
                          );
                        },
                      ),
                    ],

                    // Student Management (Staff only)
                    if (user.userType == UserType.staff) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Student Management',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('Student List'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacementNamed('/staff-dashboard');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.assignment_ind),
                        title: const Text('Attendance Report'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AttendanceReportScreen(),
                            ),
                          );
                        },
                      ),
                      // New CRM ListTile
                      ListTile(
                        leading: const Icon(Icons.support_agent), // Example icon for CRM
                        title: const Text('CRM'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CrmScreen(), // Navigate to CrmScreen
                            ),
                          );
                        },
                      ),
                    ],

                    // Student specific items
                    if (user.userType == UserType.student) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'My Activities',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.assignment),
                        title: const Text('My Tasks'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacementNamed('/student-dashboard');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.check_circle),
                        title: const Text('Attendance'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacementNamed('/student-dashboard');
                        },
                      ),
                    ],

                    const Divider(),

                    // Settings
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: Navigate to settings screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon!')),
                        );
                      },
                    ),

                    // Help
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help & Support'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: Navigate to help screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Help & Support coming soon!')),
                        );
                      },
                    ),

                    const Divider(),

                    // Terms and Conditions
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms & Conditions'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/terms-conditions');
                      },
                    ),

                    const SizedBox(height: 8),

                    // Delete User Data
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text('Delete User Data'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/delete-user-data');
                      },
                    ),

                    const SizedBox(height: 16),

                    // Logout
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.logout();

                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // App version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'StartupWorld v1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}