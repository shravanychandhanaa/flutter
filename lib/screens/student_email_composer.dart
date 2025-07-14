// lib/screens/student_email_composer.dart

import 'package:flutter/material.dart';

// Class to hold the structure of an email template
class EmailTemplate {
  final String title;
  final String subject;
  final String body;

  const EmailTemplate({
    required this.title,
    required this.subject,
    required this.body,
  });
}

class StudentEmailComposer extends StatefulWidget {
  final String recipientEmail;
  final String studentName;

  const StudentEmailComposer({
    super.key,
    required this.recipientEmail,
    required this.studentName,
  });

  @override
  State<StudentEmailComposer> createState() => _StudentEmailComposerState();
}

class _StudentEmailComposerState extends State<StudentEmailComposer> {
  late TextEditingController _recipientController;
  late TextEditingController _ccController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  // Define your pre-written templates
  late final List<EmailTemplate> _templates;
  late EmailTemplate _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.recipientEmail);
    _ccController = TextEditingController();

    _templates = [
      EmailTemplate(
        title: 'Application Status Update',
        subject: 'Update on Your Application at [Your University Name]',
        body: 'Dear ${widget.studentName},\n\nI am writing to provide an update on your application. Please log in to your portal to view the latest status. If you have any questions, please feel free to reach out.\n\nSincerely,\n[Your Name/Admissions Officer]',
      ),
      EmailTemplate(
        title: 'Interview Invitation',
        subject: 'Interview Invitation for [Program Name] at [Your University Name]',
        body: 'Dear ${widget.studentName},\n\nThank you for your interest in our [Program Name] program. We would like to invite you to an interview to discuss your application further. Please check your portal for available time slots.\n\nBest regards,\n[Your Name/Admissions Officer]',
      ),
      EmailTemplate(
        title: 'Follow-up on Missing Documents',
        subject: 'Important: Missing Documents for Your Application',
        body: 'Dear ${widget.studentName},\n\nI hope this email finds you well. We have received your application, but we noticed that we are missing a few required documents, specifically [List missing documents here].\n\nTo continue processing your application, please submit these documents by [Date]. You can upload them directly to your application portal.\n\nThank you for your prompt attention to this matter.\n\nSincerely,\n[Your Name/Admissions Officer]',
      ),
    ];

    // Set the initial template and populate the fields
    _selectedTemplate = _templates.first;
    _subjectController = TextEditingController(text: _selectedTemplate.subject);
    _bodyController = TextEditingController(text: _selectedTemplate.body);
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onTemplateChanged(EmailTemplate? newTemplate) {
    if (newTemplate != null) {
      setState(() {
        _selectedTemplate = newTemplate;
        _subjectController.text = _selectedTemplate.subject;
        _bodyController.text = _selectedTemplate.body;
      });
    }
  }

  void _sendEmail() {
    // In a real application, you would implement the logic to send the email
    // using a backend API call here.
    // final String recipient = _recipientController.text;
    // final String cc = _ccController.text;
    // final String subject = _subjectController.text;
    // final String body = _bodyController.text;
    // await YourApi.sendEmail(recipient, cc, subject, body);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email Sent! (Placeholder)'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Email', style: TextStyle(color: Colors.white)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'To',
                border: UnderlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ccController,
              decoration: const InputDecoration(
                labelText: 'Cc',
                hintText: 'Optional',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // ADDED THE TEMPLATE DROPDOWN HERE
            DropdownButtonFormField<EmailTemplate>(
              value: _selectedTemplate,
              decoration: const InputDecoration(
                labelText: 'Select Template',
                border: UnderlineInputBorder(),
              ),
              items: _templates.map((template) {
                return DropdownMenuItem<EmailTemplate>(
                  value: template,
                  child: Text(template.title),
                );
              }).toList(),
              onChanged: _onTemplateChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _sendEmail,
              icon: const Icon(Icons.send),
              label: const Text('Send Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF764ba2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}