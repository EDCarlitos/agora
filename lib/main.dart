import 'dart:async';
import 'package:flutter/material.dart';
import 'data/models/user.dart';
import 'data/services/notification_service.dart';
import 'data/services/auth_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/login/views/login_view.dart';
import 'ui/features/normal_user/views/student_dashboard_view.dart';
import 'ui/features/other_roles/role_stubs.dart';
import 'ui/features/system/views/systems_dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  User? _currentUser;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      _forceLogout();
    }
  }

  void _loginUser(User user) {
    setState(() {
      _currentUser = user;
    });

    // Iniciamos un temporizador estricto de 10 minutos
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 10), () {
      _forceLogout();
    });
  }

  void _logoutUser() {
    _sessionTimer?.cancel();
    setState(() {
      _currentUser = null;
    });
  }

  void _forceLogout() {
    if (_currentUser != null) {
      _sessionTimer?.cancel();
      AuthService().logout(); // Limpia los tokens del servicio de autenticación y FCM
      if (mounted) {
        setState(() {
          _currentUser = null;
        });
      }
    }
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
    switch (user.role) {
      case UserRole.estudiante:
        return StudentDashboardView(
          user: user,
          onLogout: _logoutUser,
        );
      case UserRole.sistemas:
        return SystemsDashboardView(
          user: user,
          onLogout: _logoutUser,
        );
      case UserRole.administrador:
        return RoleDashboardStub(
          user: user,
          onLogout: _logoutUser,
        );
      default:
        // El 'default' es obligatorio para que Flutter sepa que NUNCA retornarás null
        return RoleDashboardStub(
          user: user,
          onLogout: _logoutUser,
        );
    }
  }
}