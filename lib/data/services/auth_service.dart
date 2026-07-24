import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../../utils/api_config.dart';
import 'notification_service.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  String? _jwtToken; 

  User? get currentUser => _currentUser;
  String? get token => _jwtToken;

  // 1. Respetamos tu instancia original de GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // --- INICIO DE SESIÓN CON GOOGLE Y TU API ---
  Future<User> loginWithGoogle() async {
    try {
      // 2. Usamos tu método de inicialización
      await _googleSignIn.initialize(
        serverClientId: '899888080842-c4cgcpipjtrp5jillvme36qglr3j4kr6.apps.googleusercontent.com',
      );
      
      // 3. Usamos tu método de autenticación
      final googleUser = await _googleSignIn.authenticate();
      

      // 4. Extraemos el idToken para la API
      final authentication = googleUser.authentication;
      final String? idToken = authentication.idToken;

      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Google para enviarlo al servidor.');
      }

      // 5. Enviamos el token a tu API en Docker
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/google/token');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      // 6. Procesamos la respuesta real de la base de datos
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Guardamos el JWT
        _jwtToken = data['token'];
        
        // Creamos el objeto User con la data del backend
        final Map<String, dynamic> userData = data['user'];
        _currentUser = User(
          id: userData['id'].toString(),
          name: userData['username'] ?? googleUser.displayName ?? 'Usuario',
          email: userData['email'],
          role: _parseRole(userData['role']),
          photoUrl: googleUser.photoUrl,
        );

        // Registramos el token FCM del dispositivo en el backend
        await NotificationService().registerDeviceToken(_jwtToken!);

        return _currentUser!;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error de autenticación en el servidor');
      }

    } catch (e) {
      throw Exception('Error al conectar con Google o la API: $e');
    }
  }

  // --- INICIO DE SESIÓN CON CORREO Y CONTRASEÑA ---
  Future<User> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrUsername': email.trim(),
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        
        final Map<String, dynamic> userData = data['user'];
        _currentUser = User(
          id: userData['id'].toString(),
          name: userData['username'] ?? 'Usuario',
          email: userData['email'],
          role: _parseRole(userData['role']),
        );

        // Registramos el token FCM del dispositivo en el backend
        await NotificationService().registerDeviceToken(_jwtToken!);

        return _currentUser!;
      } else {
        throw Exception('Credenciales inválidas. Por favor intenta de nuevo.');
      }
    } catch (e) {
       throw Exception('Error al conectar con el servidor: $e');
    }
  }

  // --- CERRAR SESIÓN ---
  Future<void> logout() async {
    if (_jwtToken != null) {
      // Desvinculamos el token del dispositivo en el backend antes de borrar JWT
      await NotificationService().unregisterDeviceToken(_jwtToken!);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _jwtToken = null;
  }

  // --- ASIGNACIÓN DE ROLES DESDE LA API ---
  UserRole _parseRole(String? roleString) {
    if (roleString == null) return UserRole.estudiante;
    
    switch (roleString.toUpperCase()) {
      case 'ADMIN': return UserRole.administrador;
      case 'SISTEMAS': return UserRole.sistemas;
      case 'MANTENIMIENTO': return UserRole.mantenimiento;
      case 'LIMPIEZA': return UserRole.limpieza;
      case 'USER':
      default: return UserRole.estudiante;
    }
  }
}