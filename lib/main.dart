import 'package:flutter/material.dart';
import 'data/models/user.dart';
import 'ui/core/theme.dart';
import 'ui/features/login/views/login_view.dart';
import 'ui/features/normal_user/views/student_dashboard_view.dart';
import 'ui/features/other_roles/role_stubs.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _currentUser;

  void _loginUser(User user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _logoutUser() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ágora Universitario',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Dynamically follow the system settings
      debugShowCheckedModeBanner: false,
      home: _currentUser == null
          ? LoginView(onLoginSuccess: _loginUser)
          : _getDashboardForUser(_currentUser!),
    );
  }

  Widget _getDashboardForUser(User user) {
    if (user.role == UserRole.estudiante) {
      return StudentDashboardView(
        user: user,
        onLogout: _logoutUser,
      );
    } else {
      return RoleDashboardStub(
        user: user,
        onLogout: _logoutUser,
      );
    }
  }
}
