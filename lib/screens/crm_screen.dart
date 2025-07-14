// lib/screens/crm_screen.dart

import 'package:flutter/material.dart';
import 'college_crm_screen.dart';
import 'student_crm_screen.dart';
import 'teacher_crm_screen.dart';
import 'sponsor_crm_screen.dart'; // <--- ADD THIS LINE

class CrmScreen extends StatelessWidget {
  const CrmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Dashboard', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.only(bottom: 25.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF764ba2),
                    Color(0xFF667eea),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to CRM!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Navigate through your client relationships and operations effortlessly.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Navigation Options for CRM Modules ---

          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF667eea)),
              title: const Text('Colleges'),
              subtitle: const Text('Manage college information and leads'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed('/college-crm');
              },
            ),
          ),

          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF764ba2)),
              title: const Text('Students'),
              subtitle: const Text('Manage student profiles and applications'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed('/student-crm');
              },
            ),
          ),

          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF667eea)),
              title: const Text('Teachers'),
              subtitle: const Text('Manage teacher records and assignments'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed('/teacher-crm');
              },
            ),
          ),

          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: const Icon(Icons.business, color: Color(0xFF764ba2)),
              title: const Text('Companies'),
              subtitle: const Text('Manage company partnerships for placements and internships'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Companies Management (Coming Soon!)')),
                );
              },
            ),
          ),

          // NEW: Sponsor Option: Navigates to the Sponsor CRM screen
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: const Icon(Icons.handshake, color: Color(0xFF667eea)), // Icon for Sponsors
              title: const Text('Sponsors'),
              subtitle: const Text('Manage sponsor relationships and agreements'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed('/sponsor-crm'); // <--- CHANGED THIS LINE
              },
            ),
          ),

          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF764ba2)),
              title: const Text('Send Bulk Email'),
              subtitle: const Text('Compose and send emails to multiple contacts'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Bulk Email Sender (Coming Soon!)')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}