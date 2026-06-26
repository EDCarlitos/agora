import 'dart:async';
import '../models/user.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // In-memory list of valid credentials and users
  final Map<String, ({String password, User user})> _mockDatabase = {
    'estudiante@univ.edu': (
      password: 'password',
      user: const User(
        id: '1',
        name: 'Carlos Estudiante',
        email: 'estudiante@univ.edu',
        role: UserRole.estudiante,
      ),
    ),
    'limpieza@univ.edu': (
      password: 'password',
      user: const User(
        id: '2',
        name: 'Ana Limpieza',
        email: 'limpieza@univ.edu',
        role: UserRole.limpieza,
      ),
    ),
    'mantenimiento@univ.edu': (
      password: 'password',
      user: const User(
        id: '3',
        name: 'Pedro Mantenimiento',
        email: 'mantenimiento@univ.edu',
        role: UserRole.mantenimiento,
      ),
    ),
    'sistemas@univ.edu': (
      password: 'password',
      user: const User(
        id: '4',
        name: 'Ing. Sofia Sistemas',
        email: 'sistemas@univ.edu',
        role: UserRole.sistemas,
      ),
    ),
    'admin@univ.edu': (
      password: 'password',
      user: const User(
        id: '5',
        name: 'Lic. Gomez Administrador',
        email: 'admin@univ.edu',
        role: UserRole.administrador,
      ),
    ),
  };

  /// Mimics network request latency and validates credentials.
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    if (_mockDatabase.containsKey(normalizedEmail)) {
      final record = _mockDatabase[normalizedEmail]!;
      if (record.password == password) {
        _currentUser = record.user;
        return record.user;
      }
    }
    throw Exception('Credenciales inválidas. Por favor intenta de nuevo.');
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
