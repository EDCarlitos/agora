import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../models/user.dart';
import 'auth_service.dart';

class SystemRole {
  final int id;
  final String nombre;

  const SystemRole({required this.id, required this.nombre});

  factory SystemRole.fromJson(Map<String, dynamic> json) {
    return SystemRole(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }
}

class AdminUserService {
  static final AdminUserService _instance = AdminUserService._internal();
  factory AdminUserService() => _instance;
  AdminUserService._internal();

  Map<String, String> get _headers {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Convertir rolId del backend (1: estudiante, 2: sistemas, 3: administrador) a UserRole enum
  static UserRole rolIdToUserRole(int? rolId, String? roleName) {
    if (rolId == 1) return UserRole.estudiante;
    if (rolId == 2) return UserRole.sistemas;
    if (rolId == 3) return UserRole.administrador;

    if (roleName != null) {
      final name = roleName.toLowerCase();
      if (name.contains('admin')) return UserRole.administrador;
      if (name.contains('sistem')) return UserRole.sistemas;
      if (name.contains('estudiante')) return UserRole.estudiante;
    }
    return UserRole.estudiante;
  }

  /// Convertir UserRole enum al rolId correspondiente del backend
  static int userRoleToRolId(UserRole role) {
    switch (role) {
      case UserRole.estudiante:
        return 1;
      case UserRole.sistemas:
        return 2;
      case UserRole.administrador:
        return 3;
      default:
        return 1;
    }
  }

  /// GET /roles - Obtener roles del sistema
  Future<List<SystemRole>> getRoles() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles');
      final response = await http.get(url, headers: _headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body['data']?['roles'] ?? body['roles'] ?? [];
        return list.map((item) => SystemRole.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener los roles del servidor (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión al obtener roles: $e');
    }
  }

  /// GET /users - Listar todos los usuarios (Soporta búsqueda y filtro por API)
  Future<List<User>> getUsers({String? search, UserRole? role}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (role != null) {
        queryParams['rolId'] = userRoleToRolId(role).toString();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/users').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(uri, headers: _headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body['data']?['usuarios'] ?? body['usuarios'] ?? [];
        
        return list.map((item) {
          final int? rolId = item['rolId'];
          final String? rolNombre = item['rol']?['nombre'];
          final String username = item['username'] ?? item['email']?.split('@').first ?? 'Usuario';

          return User(
            id: item['id'].toString(),
            name: username,
            email: item['email'] ?? '',
            role: rolIdToUserRole(rolId, rolNombre),
          );
        }).toList();
      } else {
        throw Exception('Error al obtener usuarios (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al conectar con la API de usuarios: $e');
    }
  }

  /// POST /users - Crear usuario
  Future<User> createUser({
    required String email,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users');
      final rolId = userRoleToRolId(role);

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'username': username.trim(),
          'password': password,
          'rolId': rolId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final Map<String, dynamic> userData = body['data']?['usuario'] ?? body['usuario'] ?? {};
        final int? respRolId = userData['rolId'] ?? rolId;

        return User(
          id: userData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: userData['username'] ?? username,
          email: userData['email'] ?? email,
          role: rolIdToUserRole(respRolId, null),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al crear usuario.');
      }
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// PUT /users/:id - Actualizar usuario existente
  Future<User> updateUser({
    required String id,
    required String email,
    required String username,
    String? password,
    required UserRole role,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$id');
      final rolId = userRoleToRolId(role);

      final Map<String, dynamic> payload = {
        'email': email.trim(),
        'username': username.trim(),
        'rolId': rolId,
      };
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }

      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final Map<String, dynamic> userData = body['data']?['usuario'] ?? body['usuario'] ?? {};
        final int? respRolId = userData['rolId'] ?? rolId;

        return User(
          id: id,
          name: userData['username'] ?? username,
          email: userData['email'] ?? email,
          role: rolIdToUserRole(respRolId, null),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al actualizar usuario.');
      }
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// DELETE /users/:id - Eliminar usuario
  Future<void> deleteUser(String id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$id');
      final response = await http.delete(url, headers: _headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al eliminar usuario.');
      }
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}
