import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/college.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'terms_conditions_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Essential fields only
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _collegeIdController = TextEditingController();
  final _projectNameController = TextEditingController();
  
  UserType _selectedUserType = UserType.student;
  String _selectedGender = 'Male';
  String _selectedCountryCode = '+91';
  String? _selectedWorkCategory;
  College? _selectedCollege;
  bool _isLoading = false;
  bool _isLoadingColleges = false;
  bool _isLoadingProjects = false;
  bool _isLoadingWorkCategories = false;
  List<College> _colleges = [];
  String? _collegeError;
  String? _projectError;
  String? _workCategoryError;
  bool _acceptedTerms = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+86'];
  List<String> _workCategories = [];
  List<String> _projectNames = [];
  List<String> _selectedProjects = [];
  List<Map<String, String>> _projectData = []; // Store both id and name
  List<String> _selectedProjectIds = [];

  @override
  void initState() {
    super.initState();
    _loadColleges();
    _loadProjects();
    _loadWorkCategories();
  }

  void _onCollegeSelected(College? college) {
    try {
      setState(() {
        _selectedCollege = college;
        _collegeIdController.text = college?.id ?? '';
      });
    } catch (e) {
      setState(() {
        _selectedCollege = null;
        _collegeIdController.text = '';
      });
    }
  }

  Future<void> _loadColleges() async {
    try {
      setState(() {
        _isLoadingColleges = true;
        _collegeError = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final colleges = await authProvider.getAllColleges();

      if (mounted) {
        setState(() {
          _colleges = colleges;
          _isLoadingColleges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _collegeError = 'Failed to load colleges: $e';
          _isLoadingColleges = false;
        });
      }
    }
  }

  Future<void> _loadProjects() async {
    try {
      setState(() {
        _isLoadingProjects = true;
        _projectError = null;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final projects = await authProvider.getAllProjects();

      if (mounted) {
        setState(() {
          _projectData = projects;
          _projectNames = projects.map((project) => project['name']!).toList();
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _projectError = 'Failed to load projects: $e';
          _isLoadingProjects = false;
        });
      }
    }
  }

  Future<void> _loadWorkCategories() async {
    try {
      setState(() {
        _isLoadingWorkCategories = true;
        _workCategoryError = null;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final categories = await authProvider.getAllWorkCategories();

      if (mounted) {
        setState(() {
          _workCategories = categories;
          _isLoadingWorkCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _workCategoryError = 'Failed to load work categories: $e';
          _isLoadingWorkCategories = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    _collegeIdController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the Terms and Conditions to continue.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if we have all required fields for quick registration
      bool canUseQuickRegistration = _canUseQuickRegistration();

      bool success;
      
      if (canUseQuickRegistration) {
        // Use quick registration
        final result = await authProvider.quickRegistration(
          fullName: _nameController.text.trim(),
          collegeId: _collegeIdController.text.trim(),
          gender: _selectedGender.toLowerCase(),
          countryCode: _selectedCountryCode.replaceAll('+', ''),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          projectName: _selectedProjectIds.join(','),
          workCategory: _selectedWorkCategory ?? '',
        );
        
        success = result['success'] == true;
        
        if (success && mounted) {
          // Show success dialog with credentials
          _showQuickRegistrationSuccessDialog(
            result['generatedEmail'] ?? '',
            result['generatedPassword'] ?? '',
          );
          return; // Don't navigate to login screen yet
        }
      } else {
        // Use regular registration
        success = await authProvider.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          userType: _selectedUserType,
          collegeId: _collegeIdController.text.trim(),
          college: _selectedCollege?.name ?? '',
          mobile: _mobileController.text.trim(),
          countryCode: _selectedCountryCode,
          gender: _selectedGender,
          // Set default values for required fields
          city: 'To be updated',
          likeToBe: 'To be updated',
          project: _selectedProjectIds.join(','),
          workCategory: _selectedWorkCategory ?? '',
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Please sign in as ${_selectedUserType.name}.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed. Please check your details and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateName(String? value) {
    try {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your full name';
      }
      if (value.trim().length < 2) {
        return 'Name must be at least 2 characters long';
      }
      return null;
    } catch (e) {
      return 'Invalid name format';
    }
  }

  String? _validateEmail(String? value) {
    try {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your email address';
      }
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
      return null;
    } catch (e) {
      return 'Invalid email format';
    }
  }

  String? _validatePassword(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter a password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
      return null;
    } catch (e) {
      return 'Invalid password format';
    }
  }

  String? _validateConfirmPassword(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
      return null;
    } catch (e) {
      return 'Invalid confirmation format';
    }
  }

  String? _validateMobile(String? value) {
    try {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your mobile number';
      }
      final mobileRegex = RegExp(r'^\d{10}$');
      if (!mobileRegex.hasMatch(value.trim())) {
        return 'Please enter a valid 10-digit mobile number';
      }
      return null;
    } catch (e) {
      return 'Invalid mobile format';
    }
  }

  bool _canUseQuickRegistration() {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _collegeIdController.text.trim().isNotEmpty &&
        _mobileController.text.trim().isNotEmpty &&
        _selectedProjects.isNotEmpty &&
        _selectedWorkCategory != null &&
        _selectedCollege != null &&
        _selectedUserType == UserType.student;
  }

  void _showQuickRegistrationSuccessDialog(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Registration Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your account has been created successfully! Please save your login credentials:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: Color(0xFF667eea),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Username/Email:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 16,
                          color: Color(0xFF667eea),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Password:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      password,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Please save these credentials securely. You can use them to log in to your account.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Proceed to Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.person_add,
                          size: 60,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Join StartupWorld',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Complete your profile after registration',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF667eea),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Quick Registration: Fill all required fields for instant registration without password. You can set a password later.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667eea),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password (Optional for Quick Registration)',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          // Password is optional for quick registration
                          if (value == null || value.isEmpty) {
                            return null; // Allow empty password
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password (Optional for Quick Registration)',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          // Password confirmation is optional for quick registration
                          if (value == null || value.isEmpty) {
                            return null; // Allow empty password
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Mobile Number with Country Code
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCountryCode,
                              decoration: const InputDecoration(
                                labelText: 'Country Code',
                                border: OutlineInputBorder(),
                              ),
                              items: _countryCodes.map((String code) {
                                return DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(code),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCountryCode = newValue!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number *',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateMobile,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: _genderOptions.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Project Name
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownSearch<String>.multiSelection(
                              items: _projectNames,
                              selectedItems: _selectedProjects,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Project Names *',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: _isLoadingProjects
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              onChanged: _isLoadingProjects || _projectNames.isEmpty ? null : (List<String> newValues) {
                                setState(() {
                                  _selectedProjects = newValues;
                                  // Update selected project IDs based on selected names
                                  _selectedProjectIds = _projectData
                                      .where((project) => newValues.contains(project['name']))
                                      .map((project) => project['id']!)
                                      .toList();
                                  _projectNameController.text = newValues.join(', ');
                                });
                              },
                              validator: (values) {
                                if (values == null || values.isEmpty) {
                                  return 'Please select at least one project';
                                }
                                return null;
                              },
                              popupProps: const PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    labelText: 'Search Projects',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                constraints: BoxConstraints(maxHeight: 300),
                              ),
                              enabled: !_isLoadingProjects && _projectNames.isNotEmpty,
                              dropdownButtonProps: DropdownButtonProps(
                                icon: _isLoadingProjects
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.arrow_drop_down),
                              ),
                              itemAsString: (String project) => project,
                            ),
                            if (_projectError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _projectError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _loadProjects,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ] else if (_projectNames.isEmpty && !_isLoadingProjects) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'No projects available',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: _loadProjects,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667eea),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Work Category
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownSearch<String>(
                              items: _workCategories,
                              selectedItem: _workCategories.contains(_selectedWorkCategory) ? _selectedWorkCategory : null,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Work Category *',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: _isLoadingWorkCategories
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              onChanged: _isLoadingWorkCategories || _workCategories.isEmpty ? null : (String? newValue) {
                                setState(() {
                                  _selectedWorkCategory = newValue;
                                });
                              },
                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    labelText: 'Search Work Category',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              enabled: !_isLoadingWorkCategories && _workCategories.isNotEmpty,
                              dropdownButtonProps: DropdownButtonProps(
                                icon: _isLoadingWorkCategories
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.arrow_drop_down),
                              ),
                            ),
                            if (_workCategoryError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _workCategoryError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _loadWorkCategories,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ] else if (_workCategories.isEmpty && !_isLoadingWorkCategories) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'No work categories available',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: _loadWorkCategories,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667eea),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // College Dropdown (Searchable)
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownSearch<College>(
                              items: _colleges,
                              itemAsString: (College? c) => c?.name ?? '',
                              selectedItem: _selectedCollege,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: const InputDecoration(
                                  labelText: 'Select College *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              onChanged: _onCollegeSelected,
                              validator: (value) {
                                try {
                                  if (value == null) {
                                    return 'Please select a college';
                                  }
                                  return null;
                                } catch (e) {
                                  return 'Invalid college selection';
                                }
                              },
                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    labelText: 'Search College',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              enabled: !_isLoadingColleges,
                              dropdownButtonProps: DropdownButtonProps(
                                icon: _isLoadingColleges
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.arrow_drop_down),
                              ),
                            ),
                            if (_collegeError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _collegeError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _loadColleges,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ] else if (_colleges.isEmpty && !_isLoadingColleges) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'No colleges available',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: _loadColleges,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667eea),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // College ID (Non-editable)
                      TextFormField(
                        controller: _collegeIdController,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'College ID',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          hintText: 'College ID will be auto-filled when college is selected',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User Type
                      DropdownButtonFormField<UserType>(
                        value: _selectedUserType,
                        decoration: const InputDecoration(
                          labelText: 'User Type',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: UserType.values.map((UserType type) {
                          return DropdownMenuItem<UserType>(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (UserType? newValue) {
                          setState(() {
                            _selectedUserType = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Terms and Conditions Checkbox
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptedTerms = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF667eea),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _acceptedTerms = !_acceptedTerms;
                                      });
                                    },
                                    child: const Text(
                                      'I accept the Terms and Conditions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const SizedBox(width: 48), // Align with checkbox text
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TermsConditionsScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View Terms and Conditions',
                                    style: TextStyle(
                                      color: Color(0xFF667eea),
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _canUseQuickRegistration() ? 'Quick Register' : 'Register',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Sign in link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Already have an account? Sign in',
                            style: TextStyle(color: Color(0xFF667eea)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 