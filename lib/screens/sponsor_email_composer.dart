// lib/screens/sponsor_email_composer.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

class SponsorEmailComposer extends StatefulWidget {
  final String recipientEmail;
  final String sponsorName;

  const SponsorEmailComposer({
    super.key,
    required this.recipientEmail,
    required this.sponsorName,
  });

  @override
  State<SponsorEmailComposer> createState() => _SponsorEmailComposerState();
}

class _SponsorEmailComposerState extends State<SponsorEmailComposer> {
  late TextEditingController _recipientController;
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  // Define your pre-written templates
  late final List<EmailTemplate> _templates;
  late EmailTemplate _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.recipientEmail);

    _templates = [
      EmailTemplate(
        title: 'Initial Outreach',
        subject: 'Sponsorship Inquiry - ${widget.sponsorName}',
        body: 'Dear ${widget.sponsorName} Team,\n\nI hope this email finds you well. I am writing to discuss a potential partnership opportunity. We believe a collaboration could be mutually beneficial. Please let me know the best time to connect.\n\nSincerely,\n[Your Name]',
      ),
      EmailTemplate(
        title: 'Follow-up on Proposal',
        subject: 'Follow-up: Sponsorship Proposal',
        body: 'Dear ${widget.sponsorName} Team,\n\nI am following up on the sponsorship proposal we sent over last week. Did you have a chance to review it? I am happy to answer any questions you may have.\n\nBest regards,\n[Your Name]',
      ),
      EmailTemplate(
        title: 'Thank You',
        subject: 'Thank You for Your Sponsorship!',
        body: 'Dear ${widget.sponsorName} Team,\n\nOn behalf of our entire organization, I would like to extend a heartfelt thank you for your generous sponsorship. Your support is invaluable and will help us achieve our goals.\n\nSincerely,\n[Your Name]',
      ),
    ];

    // Set the initial template and populate the fields
    _selectedTemplate = _templates.first;
    _subjectController.text = _selectedTemplate.subject;
    _bodyController.text = _selectedTemplate.body;
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

  Future<void> _sendEmail() async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: _recipientController.text,
      queryParameters: {
        'subject': _subjectController.text,
        'body': _bodyController.text,
        'cc': _ccController.text,
      },
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email app for ${_recipientController.text}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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