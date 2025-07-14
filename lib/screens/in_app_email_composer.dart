// lib/screens/in_app_email_composer.dart

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

class InAppEmailComposer extends StatefulWidget {
  final String recipientEmail;
  final String collegeName;

  const InAppEmailComposer({
    super.key,
    required this.recipientEmail,
    required this.collegeName,
  });

  @override
  State<InAppEmailComposer> createState() => _InAppEmailComposerState();
}

class _InAppEmailComposerState extends State<InAppEmailComposer> {
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
        title: 'General Admission Inquiry',
        subject: 'Admission Inquiry: ${widget.collegeName}',
        body: 'Dear Admissions Team,\n\nI am writing to inquire about the admission process for the upcoming academic year at ${widget.collegeName}.\n\nCould you please provide more information on:\n\n1. Available courses and programs.\n2. Admission criteria and eligibility.\n3. Application deadlines.\n4. Any scholarship opportunities.\n\nThank you for your time and assistance.\n\nSincerely,\n[Your Name]',
      ),
      EmailTemplate(
        title: 'Financial Aid & Scholarships',
        subject: 'Inquiry on Financial Aid: ${widget.collegeName}',
        body: 'Dear Admissions Team,\n\nI am writing to request information regarding the financial aid and scholarship opportunities at ${widget.collegeName}. Could you please provide details on the application process for these programs?\n\nThank you,\n[Your Name]',
      ),
      EmailTemplate(
        title: 'Program-Specific Inquiry',
        subject: 'Inquiry about [Program Name] Program: ${widget.collegeName}',
        body: 'Dear Admissions Team,\n\nI am interested in the [Program Name] program at ${widget.collegeName} and would like to request more information.\n\nCould you provide details on the curriculum, faculty, and career outcomes for this program? I would also appreciate hearing about any prerequisites or specific application requirements.\n\nThank you for your assistance.\n\nSincerely,\n[Your Name]',
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
    // This is the key part that requires a backend.
    // In a real application, you would send the email here using an API call.
    // Example:
    // final String recipient = _recipientController.text;
    // final String cc = _ccController.text; // USE THE NEW CC VALUE
    // final String subject = _subjectController.text;
    // final String body = _bodyController.text;
    // await YourApi.sendEmail(recipient, cc, subject, body);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email Sent! (Placeholder)'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(); // Go back to the previous screen
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