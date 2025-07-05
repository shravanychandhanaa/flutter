import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: 2024',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // 1. Acceptance of Terms
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing and using the StartupWorld application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            
            // 2. Description of Service
            _buildSection(
              '2. Description of Service',
              'StartupWorld provides a platform for students and staff to manage projects, track attendance, assign tasks, and collaborate on educational initiatives. The service includes but is not limited to user registration, project management, task assignment, and reporting features.',
            ),
            
            // 3. User Registration
            _buildSection(
              '3. User Registration',
              'To access certain features of the application, you must register for an account. You agree to provide accurate, current, and complete information during registration and to update such information to keep it accurate, current, and complete. You are responsible for safeguarding your password and for all activities that occur under your account.',
            ),
            
            // 4. User Conduct
            _buildSection(
              '4. User Conduct',
              'You agree not to use the service to:\n\n'
              '• Violate any applicable laws or regulations\n'
              '• Infringe upon the rights of others\n'
              '• Upload or transmit harmful, offensive, or inappropriate content\n'
              '• Attempt to gain unauthorized access to the system\n'
              '• Interfere with the proper functioning of the service\n'
              '• Use the service for commercial purposes without authorization',
            ),
            
            // 5. Privacy Policy
            _buildSection(
              '5. Privacy Policy',
              'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the service, to understand our practices regarding the collection and use of your personal information.',
            ),
            
            // 6. Data Protection
            _buildSection(
              '6. Data Protection',
              'We are committed to protecting your personal data in accordance with applicable data protection laws. We implement appropriate technical and organizational measures to ensure the security of your personal information.',
            ),
            
            // 7. Intellectual Property
            _buildSection(
              '7. Intellectual Property',
              'The service and its original content, features, and functionality are and will remain the exclusive property of StartupWorld and its licensors. The service is protected by copyright, trademark, and other laws.',
            ),
            
            // 8. User Content
            _buildSection(
              '8. User Content',
              'You retain ownership of any content you submit to the service. By submitting content, you grant us a non-exclusive, worldwide, royalty-free license to use, reproduce, modify, and distribute your content in connection with the service.',
            ),
            
            // 9. Termination
            _buildSection(
              '9. Termination',
              'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever, including without limitation if you breach the Terms.',
            ),
            
            // 10. Limitation of Liability
            _buildSection(
              '10. Limitation of Liability',
              'In no event shall StartupWorld, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
            ),
            
            // 11. Disclaimer
            _buildSection(
              '11. Disclaimer',
              'The information on this service is provided on an "as is" basis. StartupWorld makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property.',
            ),
            
            // 12. Governing Law
            _buildSection(
              '12. Governing Law',
              'These Terms shall be interpreted and governed by the laws of India, without regard to its conflict of law provisions. Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights.',
            ),
            
            // 13. Changes to Terms
            _buildSection(
              '13. Changes to Terms',
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect.',
            ),
            
            // 14. Contact Information
            _buildSection(
              '14. Contact Information',
              'If you have any questions about these Terms and Conditions, please contact us at:\n\n'
              'Email: support@startupworld.in\n'
              'Phone: +91-XXXXXXXXXX\n'
              'Address: [Your Business Address]',
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Text(
                'By using this application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 