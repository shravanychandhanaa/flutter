import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/api_client.dart';
import '../widgets/environment_selector.dart';
import '../config/environment.dart';
import '../config/app_config.dart';
import 'register_screen.dart';
import 'student_dashboard.dart';
import 'staff_dashboard.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserType _selectedUserType = UserType.student;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  Environment _selectedEnvironment = Environment.development;

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = EnvironmentConfig.environment;
    print('🔧 LoginScreen initState: _selectedEnvironment = $_selectedEnvironment');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEnvironmentChanged(Environment newEnvironment) {
    print('🔄 LoginScreen: Environment changed from $_selectedEnvironment to $newEnvironment');
    setState(() {
      _selectedEnvironment = newEnvironment;
    });
    
    // Update the environment configuration in both systems
    switch (newEnvironment) {
      case Environment.development:
        EnvironmentConfig.setEnvironment(Environment.development);
        break;
      case Environment.testing:
        EnvironmentConfig.setEnvironment(Environment.testing);
        break;
      case Environment.production:
        EnvironmentConfig.setEnvironment(Environment.production);
        break;
    }
    
    // Verify the environment was updated correctly
    print('🔧 EnvironmentConfig.environment after change: ${EnvironmentConfig.environment}');
    print('🔧 EnvironmentConfig.baseUrl after change: ${EnvironmentConfig.baseUrl}');
    print('🔧 AppConfig.baseUrl after change: ${AppConfig.baseUrl}');
    print('🔧 AppConfig.apiKey after change: ${AppConfig.apiKey.substring(0, 10)}...');
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${_getEnvironmentDisplayName(newEnvironment)} environment'),
        duration: const Duration(seconds: 2),
        backgroundColor: _getEnvironmentColor(newEnvironment),
      ),
    );
  }

  String _getEnvironmentDisplayName(Environment env) {
    switch (env) {
      case Environment.development:
        return 'Development';
      case Environment.testing:
        return 'Testing';
      case Environment.production:
        return 'Production';
    }
  }

  Color _getEnvironmentColor(Environment env) {
    switch (env) {
      case Environment.development:
        return Colors.orange;
      case Environment.testing:
        return Colors.blue;
      case Environment.production:
        return Colors.green;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug logging for environment
      print('🔐 LOGIN ATTEMPT DEBUG');
      print('🔧 EnvironmentConfig.environment: ${EnvironmentConfig.environment}');
      print('🔧 EnvironmentConfig.baseUrl: ${EnvironmentConfig.baseUrl}');
      print('🔧 AppConfig.baseUrl: ${AppConfig.baseUrl}');
      print('🔧 AppConfig.apiKey: ${AppConfig.apiKey.substring(0, 10)}...');
      print('👤 User Type: $_selectedUserType');
      print('📧 Email: ${_emailController.text.trim()}');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userType: _selectedUserType,
        rememberMe: _rememberMe,
      );

      if (!mounted) return; // Check again before setState

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        final user = authProvider.currentUser;
        if (user != null) {
          if (user.userType == UserType.student) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const StudentDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const StaffDashboard()),
            );
          }
        }
      } else if (mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Invalid credentials';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Validate input based on user type
  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return _selectedUserType == UserType.student 
          ? 'Please enter your email' 
          : 'Please enter your username or email';
    }
    
    if (_selectedUserType == UserType.student) {
      if (!value.contains('@')) {
        return 'Please enter a valid email address';
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Center(
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 80,
                          color: Color(0xFF667eea),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'StartupWorld',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Environment Selector
                        EnvironmentSelector(
                          initialEnvironment: _selectedEnvironment,
                          onEnvironmentChanged: _onEnvironmentChanged,
                        ),
                        const SizedBox(height: 16),
                        // User Type Selection
                        DropdownButtonFormField<UserType>(
                          value: _selectedUserType,
                          decoration: const InputDecoration(
                            labelText: 'User Type',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          items: UserType.values.map((UserType userType) {
                            return DropdownMenuItem<UserType>(
                              value: userType,
                              child: Text(userType.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (UserType? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedUserType = newValue;
                                // Clear the input field when switching user types
                                _emailController.clear();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Dynamic input field based on user type
                        TextFormField(
                          controller: _emailController,
                          keyboardType: _selectedUserType == UserType.student 
                              ? TextInputType.emailAddress 
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: _selectedUserType == UserType.student 
                                ? 'Email Address' 
                                : 'Username or Email',
                            hintText: _selectedUserType == UserType.student 
                                ? 'Enter your email address' 
                                : 'Enter username or email',
                            prefixIcon: Icon(_selectedUserType == UserType.student 
                                ? Icons.email 
                                : Icons.person),
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateInput,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Remember Me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF667eea),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: Color(0xFF2d3748),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Test Environment Configuration Button
                        ElevatedButton(
                          onPressed: () {
                            print('🧪 TESTING ENVIRONMENT CONFIGURATION');
                            print('🔧 EnvironmentConfig.environment: ${EnvironmentConfig.environment}');
                            print('🔧 EnvironmentConfig.baseUrl: ${EnvironmentConfig.baseUrl}');
                            print('🔧 AppConfig.baseUrl: ${AppConfig.baseUrl}');
                            
                            // Test API client
                            final testClient = apiClient;
                            print('🔧 API Client Base URL: ${testClient.options.baseUrl}');
                            print('🔧 API Client Timeout: ${testClient.options.connectTimeout}');
                            
                            // Show in snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Environment: ${EnvironmentConfig.environment}\nBase URL: ${testClient.options.baseUrl}'),
                                duration: const Duration(seconds: 5),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Test Environment Config',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Don\'t have an account? Sign up',
                            style: TextStyle(color: Color(0xFF667eea)),
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
      ),
    );
  }
} 