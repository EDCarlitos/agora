import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/admin_user_service.dart';

class UsersViewModel extends ChangeNotifier {
  final AdminUserService _adminUserService = AdminUserService();

  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Cargar usuarios desde la API con soporte de búsqueda y filtro por backend
  Future<void> loadUsers({String? search, UserRole? role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedUsers = await _adminUserService.getUsers(search: search, role: role);
      _users = fetchedUsers;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crear un nuevo usuario en la API
  Future<bool> addUser({
    required String email,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdUser = await _adminUserService.createUser(
        email: email,
        username: username,
        password: password,
        role: role,
      );
      _users.insert(0, createdUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar un usuario existente en la API
  Future<bool> updateUser({
    required String id,
    required String email,
    required String username,
    String? password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _adminUserService.updateUser(
        id: id,
        email: email,
        username: username,
        password: password,
        role: role,
      );

      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar usuario en la API
  Future<bool> removeUser(User user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminUserService.deleteUser(user.id);
      _users.removeWhere((u) => u.id == user.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
