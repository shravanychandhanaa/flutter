// lib/screens/college_crm_screen.dart

import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // REMOVE THIS LINE
import 'in_app_email_composer.dart'; // ADD THIS LINE

class CollegeCrmScreen extends StatefulWidget {
  const CollegeCrmScreen({super.key});

  @override
  State<CollegeCrmScreen> createState() => _CollegeCrmScreenState();
}

class _CollegeCrmScreenState extends State<CollegeCrmScreen> {
  String? _selectedState;
  String? _selectedCity;
  String? _selectedCollegeType;
  final TextEditingController _collegeNameSearchController = TextEditingController();

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu', 'Delhi',
    'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
  ];

  Map<String, List<String>> _citiesByState = {
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
    'Delhi': ['New Delhi', 'Noida', 'Gurgaon', 'Faridabad'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai'],
    'Uttar Pradesh': [' Lucknow', 'Kanpur', 'Ghaziabad', 'Agra'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur'],
    'Telangana': ['Hyderabad', 'Warangal'],
  };

  final List<String> _collegeTypes = [
    'University',
    'Engineering College',
    'Medical College',
    'Arts & Science College',
    'Management Institute',
    'Polytechnic',
    'Pharmacy College',
    'Law College',
    'Architecture College',
    'Agriculture College'
  ];

  List<SimulatedCollege> _allColleges = [];
  List<SimulatedCollege> _filteredColleges = [];

  @override
  void initState() {
    super.initState();
    _initializeColleges();
    _filterColleges();
  }

  void _initializeColleges() {
    _allColleges = [
      SimulatedCollege(name: 'Indian Institute of Technology Bombay', state: 'Maharashtra', city: 'Mumbai', type: 'Engineering College', email: 'admissions@iitb.ac.in'),
      SimulatedCollege(name: 'Indian Institute of Technology Delhi', state: 'Delhi', city: 'New Delhi', type: 'Engineering College', email: 'admissions@iitd.ac.in'),
      SimulatedCollege(name: 'Ahmedabad University', state: 'Gujarat', city: 'Ahmedabad', type: 'University', email: 'admissions@ahduni.edu.in'),
      SimulatedCollege(name: 'Sardar Vallabhbhai National Institute of Technology', state: 'Gujarat', city: 'Surat', type: 'Engineering College', email: 'admissions@svnit.ac.in'),
      SimulatedCollege(name: 'Veer Narmad South Gujarat University', state: 'Gujarat', city: 'Surat', type: 'University', email: 'vnsgu@vnsgu.ac.in'),
      SimulatedCollege(name: 'University of Pune', state: 'Maharashtra', city: 'Pune', type: 'University', email: 'admissions@unipune.ac.in'),
      SimulatedCollege(name: 'All India Institute of Medical Sciences Delhi', state: 'Delhi', city: 'New Delhi', type: 'Medical College', email: 'admissions@aiims.edu'),
      SimulatedCollege(name: 'National Institute of Technology Tiruchirappalli', state: 'Tamil Nadu', city: 'Tiruchirappalli', type: 'Engineering College', email: 'admissions@nitt.edu'),
      SimulatedCollege(name: 'Indian Institute of Management Ahmedabad', state: 'Gujarat', city: 'Ahmedabad', type: 'Management Institute', email: 'admissions@iima.ac.in'),
      SimulatedCollege(name: 'Birla Institute of Technology and Science, Pilani', state: 'Rajasthan', city: 'Pilani', type: 'Engineering College', email: 'admissions@pilani.bits-pilani.ac.in'),
      SimulatedCollege(name: 'Manipal Academy of Higher Education', state: 'Karnataka', city: 'Manipal', type: 'University', email: 'admissions@manipal.edu'),
      SimulatedCollege(name: 'Pandit Deendayal Energy University', state: 'Gujarat', city: 'Gandhinagar', type: 'University', email: 'admissions@pdeu.ac.in'),
      SimulatedCollege(name: 'Gujarat Technological University', state: 'Gujarat', city: 'Gandhinagar', type: 'University', email: 'info@gtu.ac.in'),
      SimulatedCollege(name: 'Delhi University', state: 'Delhi', city: 'New Delhi', type: 'University', email: 'info@du.ac.in'),
      SimulatedCollege(name: 'St. Xavier\'s College', state: 'Maharashtra', city: 'Mumbai', type: 'Arts & Science College', email: 'admissions@xaviers.edu'),
      SimulatedCollege(name: 'Loyola College', state: 'Tamil Nadu', city: 'Chennai', type: 'Arts & Science College', email: 'admissions@loyolacollege.edu'),
      SimulatedCollege(name: 'NALSAR University of Law', state: 'Telangana', city: 'Hyderabad', type: 'Law College', email: 'admissions@nalsar.ac.in'),
      SimulatedCollege(name: 'Jawaharlal Nehru Medical College, Belagavi', state: 'Karnataka', city: 'Belagavi', type: 'Medical College', email: 'jnmcadmission@kls.ac.in'),
    ];
  }

  void _filterColleges() {
    setState(() {
      _filteredColleges = _allColleges.where((college) {
        bool matchesState = _selectedState == null || _selectedState!.isEmpty || college.state == _selectedState;
        bool matchesCity = _selectedCity == null || _selectedCity!.isEmpty || college.city == _selectedCity;
        bool matchesType = _selectedCollegeType == null || _selectedCollegeType!.isEmpty || college.type == _selectedCollegeType;
        bool matchesName = _collegeNameSearchController.text.isEmpty ||
                          college.name.toLowerCase().contains(_collegeNameSearchController.text.toLowerCase());
        return matchesState && matchesCity && matchesType && matchesName;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedState = null;
      _selectedCity = null;
      _selectedCollegeType = null;
      _collegeNameSearchController.clear();
      _filterColleges();
    });
  }

  // NEW: Navigate to the in-app email composer screen
  void _navigateToEmailComposer(SimulatedCollege college) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InAppEmailComposer(
          recipientEmail: college.email,
          collegeName: college.name,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _collegeNameSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('College Search & Outreach', style: TextStyle(color: Colors.white)),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Colleges',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      hint: const Text('Select State'),
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _indianStates.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedState = newValue;
                          _selectedCity = null;
                          _filterColleges();
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: const Text('Select City'),
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: (_selectedState != null && _citiesByState.containsKey(_selectedState))
                          ? _citiesByState[_selectedState]!.map((String city) {
                                return DropdownMenuItem<String>(
                                  value: city,
                                  child: Text(city),
                                );
                              }).toList()
                          : [],
                      onChanged: (_selectedState != null && _citiesByState.containsKey(_selectedState))
                          ? (String? newValue) {
                                setState(() {
                                  _selectedCity = newValue;
                                  _filterColleges();
                                });
                              }
                          : null,
                      isDense: _selectedState == null || !_citiesByState.containsKey(_selectedState),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedCollegeType,
                      hint: const Text('Select College Type'),
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _collegeTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCollegeType = newValue;
                          _filterColleges();
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _collegeNameSearchController,
                      decoration: InputDecoration(
                        labelText: 'Search College Name',
                        hintText: 'e.g., IIT Bombay',
                        border: const UnderlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _collegeNameSearchController.clear();
                            _filterColleges();
                          },
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) => _filterColleges(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Filters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Search Results (${_filteredColleges.length} colleges)',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF764ba2)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredColleges.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No colleges found matching your criteria.\nTry adjusting the filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredColleges.length,
                      itemBuilder: (context, index) {
                        final college = _filteredColleges[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  college.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                                ),
                                const SizedBox(height: 5),
                                Text('Type: ${college.type}', style: const TextStyle(fontSize: 14)),
                                Text('Location: ${college.city}, ${college.state}', style: const TextStyle(fontSize: 14)),
                                Text('Email: ${college.email}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _navigateToEmailComposer(college), // CHANGED THIS LINE
                                    icon: const Icon(Icons.email),
                                    label: const Text('Send Email'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF764ba2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimulatedCollege {
  final String name;
  final String state;
  final String city;
  final String type;
  final String email;

  SimulatedCollege({
    required this.name,
    required this.state,
    required this.city,
    required this.type,
    required this.email,
  });
}