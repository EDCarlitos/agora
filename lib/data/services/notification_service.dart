import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../utils/api_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  bool _isFirebaseInitialized = false;
  String? _cachedFcmToken;

  bool get isFirebaseInitialized => _isFirebaseInitialized;

  /// Inicializa Firebase y los oyentes de FCM si están disponibles en la plataforma.
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseInitialized = true;
      _messaging = FirebaseMessaging.instance;

      // Solicitar permisos en iOS y Web
      await _messaging?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Obtención inicial del token
      _cachedFcmToken = await getDeviceToken();

      // Escuchar renovaciones de token
      _messaging?.onTokenRefresh.listen((newToken) {
        _cachedFcmToken = newToken;
      });

      // Escuchar notificaciones en primer plano (foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Notificación FCM recibida en primer plano: ${message.notification?.title}');
      });

    } catch (e) {
      debugPrint('Advertencia: No se pudo inicializar Firebase messaging (verificar google-services.json): $e');
      _isFirebaseInitialized = false;
    }
  }

  /// Detecta la plataforma actual en formato de cadena exigido por el backend.
  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  /// Obtiene el token de FCM del dispositivo.
  Future<String?> getDeviceToken() async {
    if (_cachedFcmToken != null) return _cachedFcmToken;
    try {
      if (_messaging != null) {
        _cachedFcmToken = await _messaging!.getToken();
      }
    } catch (e) {
      debugPrint('Error al obtener FCM token: $e');
    }
    return _cachedFcmToken;
  }

  /// Registra el token FCM del dispositivo en el servidor backend al iniciar sesión.
  Future<bool> registerDeviceToken(String jwtToken) async {
    try {
      final token = await getDeviceToken();
      if (token == null || token.isEmpty) {
        debugPrint('No hay token FCM disponible para registrar en el backend.');
        return false;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/devices');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'token': token,
          'plataforma': _platformName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Token FCM registrado exitosamente en la API.');
        return true;
      } else {
        debugPrint('Error al registrar token FCM en la API: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al registrar dispositivo en la API: $e');
      return false;
    }
  }

  /// Elimina el token FCM del dispositivo en el backend al cerrar sesión.
  Future<bool> unregisterDeviceToken(String jwtToken) async {
    try {
      final token = await getDeviceToken();
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          if (token != null) 'token': token,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Dispositivo desvinculado exitosamente en el backend.');
        _cachedFcmToken = null;
        return true;
      } else {
        debugPrint('Respuesta inesperada al hacer logout en la API: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al desvincular dispositivo en la API: $e');
      return false;
    }
  }

  /// Obtiene la lista de notificaciones persistidas desde el backend.
  Future<List<Map<String, dynamic>>> getNotifications(String jwtToken, {int page = 1, int limit = 20}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications?page=$page&limit=$limit');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['notificaciones'] != null) {
          return List<Map<String, dynamic>>.from(data['notificaciones']);
        }
      }
    } catch (e) {
      debugPrint('Error al obtener notificaciones de la API: $e');
    }
    return [];
  }

  /// Marca una notificación individual como leída.
  Future<bool> markAsRead(String jwtToken, dynamic id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
      return false;
    }
  }

  /// Marca todas las notificaciones como leídas.
  Future<bool> markAllAsRead(String jwtToken) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/read-all');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al marcar todas las notificaciones como leídas: $e');
      return false;
    }
  }
}
