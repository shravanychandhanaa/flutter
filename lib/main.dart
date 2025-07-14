// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'config/environment.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/student_list_provider.dart';
// NEW: Import the teacher_crm_screen.dart and sponsor_crm_screen.dart
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/staff_dashboard.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/delete_user_data_screen.dart';
import 'models/user.dart';
import 'screens/college_crm_screen.dart';
import 'screens/student_crm_screen.dart';
import 'screens/teacher_crm_screen.dart';
import 'screens/sponsor_crm_screen.dart'; // <--- ADD THIS LINE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved environment from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final savedEnvironment = prefs.getString('selected_environment');

  if (savedEnvironment != null) {
    switch (savedEnvironment) {
      case 'development':
        EnvironmentConfig.setEnvironment(Environment.development);
        break;
      case 'testing':
        EnvironmentConfig.setEnvironment(Environment.testing);
        break;
      case 'production':
        EnvironmentConfig.setEnvironment(Environment.production);
        break;
      default:
        // Initialize with default environment
        AppConfig.initialize();
    }
  } else {
    // Initialize with default environment
    AppConfig.initialize();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => StudentListProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()), // Assuming you have this
        ChangeNotifierProvider(create: (_) => SponsorProvider()), // <--- ADD THIS LINE
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/student-dashboard': (context) => const StudentDashboard(),
          '/staff-dashboard': (context) => const StaffDashboard(),
          '/terms-conditions': (context) => const TermsConditionsScreen(),
          '/delete-user-data': (context) => const DeleteUserDataScreen(),
          '/college-crm': (context) => const CollegeCrmScreen(),
          '/student-crm': (context) => const StudentCrmScreen(),
          '/teacher-crm': (context) => const TeacherCrmScreen(),
          '/sponsor-crm': (context) => const SponsorCrmScreen(), // <--- ADD THIS LINE
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          final user = authProvider.currentUser!;
          if (user.userType == UserType.student) {
            return const StudentDashboard();
          } else {
            return const StaffDashboard();
          }
        }

        return const LoginScreen();
      },
    );
  }
}