import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class DeleteUserDataScreen extends StatefulWidget {
  const DeleteUserDataScreen({super.key});

  @override
  State<DeleteUserDataScreen> createState() => _DeleteUserDataScreenState();
}

class _DeleteUserDataScreenState extends State<DeleteUserDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete User Data'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notice',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action will permanently delete all your data from our system. This includes your personal information, task history, attendance records, and account settings. This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Data Deletion Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'To request deletion of your personal data, you can:',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Contact Support'),
              subtitle: const Text('Email: support@startupworld.com'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please contact support for data deletion requests'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
