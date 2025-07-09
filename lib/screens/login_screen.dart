import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/environment_selector.dart';
import '../config/environment.dart';
import 'register_screen.dart';
import 'verification_screen.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = true;
    });

    try {
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
            Navigator.of(context).pushReplacementNamed('/student-dashboard');
          } else {
            Navigator.of(context).pushReplacementNamed('/staff-dashboard');
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
            colors: [Color(0xFF667eea), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Environment selector in top-right corner
              Positioned(
                top: 16,
                right: 16,
                child: const EnvironmentSelector(),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icon/app_icon.png',
                          width: 80,
                          height: 80,
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
                                builder: (context) => const VerificationScreen(),
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
            ],
          ),
        ),
      ),
    );
  }
} 