// lib/screens/teacher_email_composer.dart

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

class TeacherEmailComposer extends StatefulWidget {
  final String recipientEmail;
  final String teacherName;

  const TeacherEmailComposer({
    super.key,
    required this.recipientEmail,
    required this.teacherName,
  });

  @override
  State<TeacherEmailComposer> createState() => _TeacherEmailComposerState();
}

class _TeacherEmailComposerState extends State<TeacherEmailComposer> {
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
        title: 'Student Progress Inquiry',
        subject: 'Regarding a student inquiry',
        body: 'Dear ${widget.teacherName},\n\nI hope this email finds you well. I am writing to you regarding a matter concerning a student. Please let me know the best time to connect to discuss their progress.\n\nSincerely,\n[Your Name]',
      ),
      EmailTemplate(
        title: 'Schedule a Meeting',
        subject: 'Meeting Request: [Student Name] - [Date]',
        body: 'Dear ${widget.teacherName},\n\nI would like to request a meeting with you to discuss the progress of [Student Name]. I am available on [Date] at [Time]. Please let me know if this works for you or if another time would be better.\n\nThank you,\n[Your Name]',
      ),
      EmailTemplate(
        title: 'General Information Request',
        subject: 'Request for Information',
        body: 'Dear ${widget.teacherName},\n\nI hope this email finds you well. I am writing to request some general information regarding [Topic]. Could you please provide details on this matter when you have a moment?\n\nBest regards,\n[Your Name]',
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
    // via a backend API call.
    // final String recipient = _recipientController.text;
    // final String cc = _ccController.text;
    // final String subject = _subjectController.text;
    // final String body = _bodyController.text;

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