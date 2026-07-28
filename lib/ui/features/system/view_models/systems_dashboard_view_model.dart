import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/report_service.dart';
import '../../../../data/services/chat_service.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../utils/api_config.dart';
import '../../widgets/shared_chats_tab.dart';

class SystemsDashboardViewModel extends ChangeNotifier implements IChatViewModel { 

  static final SystemsDashboardViewModel _instance = SystemsDashboardViewModel._internal();
  
  factory SystemsDashboardViewModel() => _instance;
  
  SystemsDashboardViewModel._internal();

  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;


  List<dynamic> _availableReports = []; 
  List<dynamic> _myInProgressIncidents = []; 
  List<dynamic> _myResolvedIncidents = []; 
  
  List<dynamic> get availableReports => _availableReports;
  List<dynamic> get myInProgressIncidents => _myInProgressIncidents;
  List<dynamic> get myResolvedIncidents => _myResolvedIncidents;

final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  
  List<dynamic> _chats = [];
  List<dynamic> get chats => _chats;
  final List<Map<String, dynamic>> notifications = [];
  
  Timer? _pollingTimer;

  void startPolling() {
    if (_pollingTimer != null) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      loadNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> loadChats() async {
    try {
      final token = AuthService().token;
      if (token != null) {
        _chats = await _chatService.getChats(token);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar chats de sistemas: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      final token = AuthService().token;
      if (token != null) {
        final apiNotifications = await _notificationService.getNotifications(token);
        notifications.clear();
        for (var n in apiNotifications) {
          notifications.add({
            'id': n['id'].toString(),
            'title': n['titulo'] ?? 'Notificación',
            'body': n['cuerpo'] ?? '',
            'isRead': n['leida'] ?? false,
            'datos': n['datos'], 
          });
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
    }
  }

  int get totalUnreadChatMessages {
    return notifications.where((n) {
      if (n['isRead'] == true) return false;
      var datos = n['datos'];
      if (datos is String) {
        try { datos = jsonDecode(datos); } catch (_) {}
      }
      return datos != null && datos is Map && datos['tipo'] == 'NUEVO_MENSAJE';
    }).length;
  }

  int getUnreadCountForChat(String incidenciaId) {
    return notifications.where((n) {
      if (n['isRead'] == true) return false;
      var datos = n['datos'];
      if (datos is String) {
        try { datos = jsonDecode(datos); } catch (_) {}
      }
      return datos != null &&
          datos is Map &&
          datos['tipo'] == 'NUEVO_MENSAJE' &&
          datos['incidenciaId']?.toString() == incidenciaId.toString();
    }).length;
  }

  Future<void> markChatNotificationsAsRead(String incidenciaId) async {
    final token = AuthService().token;
    if (token == null) return;
    bool hasChanges = false;

    for (var n in notifications) {
      if (n['isRead'] == true) continue;
      var datos = n['datos'];
      if (datos is String) {
        try { datos = jsonDecode(datos); } catch (_) {}
      }
      if (datos != null && datos is Map && datos['tipo'] == 'NUEVO_MENSAJE' && datos['incidenciaId']?.toString() == incidenciaId.toString()) {
        n['isRead'] = true; 
        hasChanges = true;
        await _notificationService.markAsRead(token, n['id']);
      }
    }
    if (hasChanges) notifyListeners();
  }
  
  Future<void> loadDashboardData(User currentUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = AuthService().token;
      if (token != null) {
        // 1. Obtenemos TODOS los reportes desde la API
        final apiReports = await _reportService.getReports(token);
        
        // 2. Filtramos los "Disponibles" (Estado NUEVO y que correspondan a Sistemas)
        _availableReports = apiReports.where((r) {
          final estado = r['estado'];
          final tipo = (r['tipo'] ?? '').toString().toLowerCase();
          // Inferimos el área igual que en el dashboard de estudiante
          final isSistemas = !tipo.contains('limpieza') && !tipo.contains('basura') && !tipo.contains('silla'); 
          return estado == 'NUEVO' && isSistemas;
        }).toList();

        // 3. Filtramos "Mis Asignaciones" (Tienen incidencia, son mías, y están abiertas o en proceso)
        _myInProgressIncidents = apiReports.where((r) {
          final inc = r['incidencia'];
          if (inc == null) return false;
          
          final isMine = inc['id_usuarioAministrativo'] == int.parse(currentUser.id);
          final isActiva = inc['estado'] == 'abierta' || inc['estado'] == 'en_proceso' || inc['estado'] == 'reabierta';
          return isMine && isActiva;
        }).toList();

        // 4. Filtramos "Resueltos" (Tienen incidencia, son mías, y están finalizadas)
        _myResolvedIncidents = apiReports.where((r) {
          final inc = r['incidencia'];
          if (inc == null) return false;

          final isMine = inc['id_usuarioAministrativo'] == int.parse(currentUser.id);
          final isTerminada = inc['estado'] == 'finalizada' || inc['estado'] == 'cerrada';
          return isMine && isTerminada;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error cargando datos de sistemas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auto-asignarse un reporte (POST /incidencias)
  Future<bool> assignReportToMe(int reporteId, User currentUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = AuthService().token;
      if (token == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/incidencias');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reporteId': reporteId}),
      );

      if (response.statusCode == 201) {
        await loadDashboardData(currentUser); // Recargamos para actualizar las listas
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al asignarse reporte: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Finalizar incidencia con evidencia (POST /incidencias/:id/finalizar)
  Future<bool> resolveIncident(int incidenciaId, String descripcion, List<String> imagePaths, User currentUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = AuthService().token;
      if (token == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/incidencias/$incidenciaId/finalizar');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      if (descripcion.isNotEmpty) {
        request.fields['descripcion'] = descripcion;
      }

      for (String path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('imagenes', path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadDashboardData(currentUser); // Recargamos para mover a la pestaña de historial
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al finalizar incidencia: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rechazar un reporte (PATCH /reports/:id/reject)
  Future<bool> rejectReport(int reporteId, User currentUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = AuthService().token;
      if (token == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/reports/$reporteId/reject');
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await loadDashboardData(currentUser); // Recargamos para quitarlo de "Disponibles"
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al rechazar reporte: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}