import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Attempts to authenticate with the provided credentials.
  /// Returns the authenticated [User] on success, or null on failure.
  Future<User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Por favor, llena todos los campos.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      return user;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // boton de google
  Future<User?> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

   try {
      final user = await _authService.loginWithGoogle();
      return user;
    } catch (e) {
      final errorText = e.toString().replaceAll('Exception: ', '');
      
      if (errorText.contains('Cancelaste') || errorText.contains('canceled')) {
        _errorMessage = null;
      } else {
        _errorMessage = errorText;
      }
      
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any active error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
