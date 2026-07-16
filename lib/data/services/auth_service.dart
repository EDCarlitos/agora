import 'dart:async';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  //Asignación de roles
  UserRole _asignarRolPorCorreo(String email) {
    final correo = email.trim().toLowerCase();

    if (correo == 'bchapolrueda@gmail.com') {
      return UserRole.administrador;
    }
    if (correo == 'juancarlosuchdzib@gmail.com') {
      return UserRole.estudiante;
    }

    if (_mockDatabase.containsKey(correo)) {
      return _mockDatabase[correo]!.user.role;
    }
    return UserRole.estudiante; 
  }

  //Inicio con google
  Future<User> loginWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '899888080842-c4cgcpipjtrp5jillvme36qglr3j4kr6.apps.googleusercontent.com',
      );
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) {
        throw Exception('Cancelaste el inicio de sesión con Google.');
      }

      final user = User(
        id: googleUser.id,
        name: googleUser.displayName ?? 'Usuario Google',
        email: googleUser.email,
        role: _asignarRolPorCorreo(googleUser.email), 
        photoUrl: googleUser.photoUrl,
      );
      
      _currentUser = user;
      return user;
    } catch (e) {
      throw Exception('Error al conectar con Google: $e');
    }
  }

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

  // --- INICIO DE SESIÓN CON CORREO Y CONTRASEÑA ---
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

  // --- CERRAR SESIÓN ---
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
