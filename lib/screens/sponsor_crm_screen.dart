// lib/screens/sponsor_crm_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'sponsor_email_composer.dart'; // IMPORT THE NEW TEMPLATE

// Sponsor Model
class Sponsor {
  String id;
  String name;
  String contactPerson;
  String email;
  String phone;
  String industry;
  String sponsorshipType;
  String status; // e.g., Active, Pending, Completed, Declined
  String notes;

  Sponsor({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.industry,
    required this.sponsorshipType,
    required this.status,
    this.notes = '',
  });

  // Helper for creating a copy when editing
  Sponsor copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? email,
    String? phone,
    String? industry,
    String? sponsorshipType,
    String? status,
    String? notes,
  }) {
    return Sponsor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      industry: industry ?? this.industry,
      sponsorshipType: sponsorshipType ?? this.sponsorshipType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

// Sponsor Provider (for state management with sample data)
class SponsorProvider with ChangeNotifier {
  List<Sponsor> _sponsors = [
    Sponsor(
      id: 'SP001',
      name: 'Tech Innovators Inc.',
      contactPerson: 'Alice Wonderland',
      email: 'alice@techinnovators.com',
      phone: '+1234567890',
      industry: 'Technology',
      sponsorshipType: 'Event Sponsorship',
      status: 'Active',
      notes: 'Signed for annual tech symposium.',
    ),
    Sponsor(
      id: 'SP002',
      name: 'Global Finance Group',
      contactPerson: 'Bob Builder',
      email: 'bob@globalfinance.com',
      phone: '+1987654321',
      industry: 'Finance',
      sponsorshipType: 'Scholarship Fund',
      status: 'Pending',
      notes: 'Awaiting final approval on scholarship terms.',
    ),
    Sponsor(
      id: 'SP003',
      name: 'Eco-Solutions Ltd.',
      contactPerson: 'Charlie Green',
      email: 'charlie@ecosolutions.com',
      phone: '+442012345678',
      industry: 'Environment',
      sponsorshipType: 'Project Funding',
      status: 'Completed',
      notes: 'Successfully funded the clean energy project.',
    ),
    Sponsor(
      id: 'SP004',
      name: 'MediCare Pharma',
      contactPerson: 'Dr. Diana Prince',
      email: 'diana@medicare.com',
      phone: '+919999988888',
      industry: 'Healthcare',
      sponsorshipType: 'Research Grant',
      status: 'Active',
      notes: 'Providing grants for medical research.',
    ),
    Sponsor(
      id: 'SP005',
      name: 'Artistic Creations Studio',
      contactPerson: 'Eve Smith',
      email: 'eve@artisticcreations.com',
      phone: '+61412345678',
      industry: 'Arts & Culture',
      sponsorshipType: 'Cultural Event',
      status: 'Declined',
      notes: 'Declined due to budget constraints this year.',
    ),
  ];

  List<Sponsor> get sponsors => _sponsors;

  // For adding/updating/deleting (placeholders for now)
  void addSponsor(Sponsor sponsor) {
    _sponsors.add(sponsor);
    notifyListeners();
  }

  void updateSponsor(Sponsor updatedSponsor) {
    final index = _sponsors.indexWhere((s) => s.id == updatedSponsor.id);
    if (index != -1) {
      _sponsors[index] = updatedSponsor;
      notifyListeners();
    }
  }

  void deleteSponsor(String id) {
    _sponsors.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}

class SponsorCrmScreen extends StatefulWidget {
  const SponsorCrmScreen({super.key});

  @override
  State<SponsorCrmScreen> createState() => _SponsorCrmScreenState();
}

class _SponsorCrmScreenState extends State<SponsorCrmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedIndustry;
  String? _selectedSponsorshipType;
  String? _selectedStatus;
  Sponsor? _editingSponsor; // Null if adding, not null if editing

  List<Sponsor> _filteredSponsors = [];

  final List<String> _industries = [
    'Technology',
    'Finance',
    'Healthcare',
    'Education',
    'Retail',
    'Manufacturing',
    'Environment',
    'Arts & Culture',
    'Other'
  ];

  final List<String> _sponsorshipTypes = [
    'Event Sponsorship',
    'Scholarship Fund',
    'Project Funding',
    'In-Kind Donation',
    'Research Grant',
    'Marketing Partnership',
    'Other'
  ];

  final List<String> _statuses = [
    'Active',
    'Pending',
    'Completed',
    'Declined',
    'Lead',
    'Archived'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize filtered list with all sponsors from the provider
    _filteredSponsors = Provider.of<SponsorProvider>(context, listen: false).sponsors;
    _searchController.addListener(_filterSponsors);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _searchController.removeListener(_filterSponsors);
    _searchController.dispose();
    super.dispose();
  }

  void _filterSponsors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSponsors = Provider.of<SponsorProvider>(context, listen: false)
          .sponsors
          .where((sponsor) =>
              sponsor.name.toLowerCase().contains(query) ||
              sponsor.contactPerson.toLowerCase().contains(query) ||
              sponsor.email.toLowerCase().contains(query) ||
              sponsor.phone.toLowerCase().contains(query) ||
              sponsor.industry.toLowerCase().contains(query) ||
              sponsor.sponsorshipType.toLowerCase().contains(query) ||
              sponsor.status.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addOrUpdateSponsor() {
    if (_formKey.currentState!.validate()) {
      final sponsorProvider = Provider.of<SponsorProvider>(context, listen: false);
      setState(() {
        if (_editingSponsor == null) {
          // Add new sponsor
          final newSponsor = Sponsor(
            id: 'SP${(sponsorProvider.sponsors.length + 1).toString().padLeft(3, '0')}', // Simple ID generation
            name: _nameController.text,
            contactPerson: _contactPersonController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            industry: _selectedIndustry!,
            sponsorshipType: _selectedSponsorshipType!,
            status: _selectedStatus!,
            notes: _notesController.text,
          );
          sponsorProvider.addSponsor(newSponsor);
        } else {
          // Update existing sponsor
          final updatedSponsor = _editingSponsor!.copyWith(
            name: _nameController.text,
            contactPerson: _contactPersonController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            industry: _selectedIndustry,
            sponsorshipType: _selectedSponsorshipType,
            status: _selectedStatus,
            notes: _notesController.text,
          );
          sponsorProvider.updateSponsor(updatedSponsor);
          _editingSponsor = null; // Clear editing state
        }
        _clearForm();
        _filterSponsors(); // Re-filter to update the list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingSponsor == null ? 'Sponsor Added!' : 'Sponsor Updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editSponsor(Sponsor sponsor) {
    setState(() {
      _editingSponsor = sponsor;
      _nameController.text = sponsor.name;
      _contactPersonController.text = sponsor.contactPerson;
      _emailController.text = sponsor.email;
      _phoneController.text = sponsor.phone;
      _selectedIndustry = sponsor.industry;
      _selectedSponsorshipType = sponsor.sponsorshipType;
      _selectedStatus = sponsor.status;
      _notesController.text = sponsor.notes;
    });
    // Scroll to the top to show the form (if needed)
    // _scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _deleteSponsor(String id) {
    final sponsorProvider = Provider.of<SponsorProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this sponsor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              sponsorProvider.deleteSponsor(id);
              _filterSponsors(); // Update filtered list
              if (_editingSponsor?.id == id) {
                _clearForm();
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sponsor Deleted!'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _contactPersonController.clear();
    _emailController.clear();
    _phoneController.clear();
    _notesController.clear();
    setState(() {
      _selectedIndustry = null;
      _selectedSponsorshipType = null;
      _selectedStatus = null;
      _editingSponsor = null;
    });
  }

  // Function to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone app for $phoneNumber')),
      );
    }
  }

  // UPDATED: Function to navigate to the new email composer screen
  void _openEmailComposer(Sponsor sponsor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SponsorEmailComposer(
          recipientEmail: sponsor.email,
          sponsorName: sponsor.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sponsor CRM', style: TextStyle(color: Colors.white)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add/Edit Sponsor Form
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingSponsor == null ? 'Add New Sponsor' : 'Edit Sponsor',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Sponsor Name',
                          hintText: 'e.g., Tech Innovations Inc.',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter sponsor name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          hintText: 'e.g., Jane Doe (Head of Marketing)',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter contact person';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'e.g., info@sponsor.com',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g., +1 123-456-7890',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (!RegExp(r'^\+?[0-9\s-()]{7,15}$').hasMatch(value)) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedIndustry,
                        hint: const Text('Select Industry'),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        items: _industries.map((String industry) {
                          return DropdownMenuItem<String>(
                            value: industry,
                            child: Text(industry, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedIndustry = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an industry';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedSponsorshipType,
                        hint: const Text('Select Sponsorship Type'),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        items: _sponsorshipTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSponsorshipType = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a sponsorship type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        hint: const Text('Select Status'),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        items: _statuses.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes/Remarks',
                          hintText: 'Any additional information about the sponsor',
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addOrUpdateSponsor,
                              icon: Icon(_editingSponsor == null ? Icons.add : Icons.save),
                              label: Text(_editingSponsor == null ? 'Add Sponsor' : 'Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          if (_editingSponsor != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _clearForm,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Sponsor List Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Sponsors',
                hintText: 'e.g., Tech Innovators or Jane Doe',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterSponsors();
                  },
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) => _filterSponsors(),
            ),
            const SizedBox(height: 20),
            Text(
              'All Sponsors (${_filteredSponsors.length})',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF764ba2)),
            ),
            const SizedBox(height: 10),

            // Sponsor List
            _filteredSponsors.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No sponsors found matching your criteria.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true, // Important for ListView inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Important
                    itemCount: _filteredSponsors.length,
                    itemBuilder: (context, index) {
                      final sponsor = _filteredSponsors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sponsor.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${sponsor.id}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text('Contact: ${sponsor.contactPerson}', style: const TextStyle(fontSize: 14)),
                              Text('Industry: ${sponsor.industry}', style: const TextStyle(fontSize: 14)),
                              Text('Type: ${sponsor.sponsorshipType}', style: const TextStyle(fontSize: 14)),
                              Text('Status: ${sponsor.status}', style: TextStyle(fontSize: 14, color: sponsor.status == 'Active' ? Colors.green : (sponsor.status == 'Pending' ? Colors.orange : Colors.red))),
                              Text('Email: ${sponsor.email}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                              Text('Phone: ${sponsor.phone}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                              if (sponsor.notes.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text('Notes: ${sponsor.notes}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editSponsor(sponsor),
                                    tooltip: 'Edit Sponsor',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green),
                                    onPressed: () => _makePhoneCall(sponsor.phone),
                                    tooltip: 'Call Sponsor',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.email, color: Colors.orange),
                                    onPressed: () => _openEmailComposer(sponsor), // CHANGED THIS LINE
                                    tooltip: 'Email Sponsor',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSponsor(sponsor.id),
                                    tooltip: 'Delete Sponsor',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}