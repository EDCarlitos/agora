import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/report.dart';
import '../../../../data/services/report_service.dart';
import '../../../../data/services/auth_service.dart'; // Importante para obtener el token
import '../../../../data/services/notification_service.dart';
import '../../../../data/services/aula_service.dart';
import '../../../../data/services/chat_service.dart';
import '../../widgets/shared_chats_tab.dart';

class StudentDashboardViewModel extends ChangeNotifier implements IChatViewModel { // <-- 2. Agrega "implements IChatViewModel"
  static final StudentDashboardViewModel _instance = StudentDashboardViewModel._internal();
  factory StudentDashboardViewModel() => _instance;
  
  StudentDashboardViewModel._internal() {
    loadReports();
    loadNotifications();
  }

  final ReportService _reportService = ReportService();
  final NotificationService _notificationService = NotificationService();
  final List<Report> _reports = [];
  final ChatService _chatService = ChatService(); // <-- Instancia del nuevo servicio
  final AulaService _aulaService = AulaService();
  
  // Lista de notificaciones cargada dinámicamente desde el backend
  final List<Map<String, dynamic>> notifications = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<Report> get allReports => _reports;
  List<Report> get incidents => _reports..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  List<Report> get recentIncidents {
    final now = DateTime.now();
    return incidents.where((r) {
      final localDate = r.dateTime.toLocal();
      return now.difference(localDate).inHours <= 24;
    }).take(5).toList();
  }

  List<Report> getMyReports(User user) {
    // Filtramos estrictamente bajo la condición de que el reportante
    // coincida con el nombre de usuario o el correo de la sesión actual.
    final filtered = _reports.where((r) => 
      r.reportedBy == user.name || r.reportedBy == user.email
    ).toList();
    
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return filtered;
  }


Future<void> markChatNotificationsAsRead(String incidenciaId) async {
    final token = AuthService().token;
    if (token == null) return;

    bool hasChanges = false;

    // 1. Buscamos y actualizamos localmente (para que la UI reaccione instantáneamente)
    for (var n in notifications) {
      if (n['isRead'] == true) continue;
      
      var datos = n['datos'];
      if (datos is String) {
        try { datos = jsonDecode(datos); } catch (_) {}
      }

      if (datos != null && 
          datos is Map && 
          datos['tipo'] == 'NUEVO_MENSAJE' && 
          datos['incidenciaId']?.toString() == incidenciaId.toString()) {
        
        n['isRead'] = true; 
        hasChanges = true;
        
        // 2. Le avisamos a la API que esta notificación específica ya fue leída
        await _notificationService.markAsRead(token, n['id']);
      }
    }

    // 3. Si hubo cambios, repintamos la UI (desaparece el badge verde/rojo)
    if (hasChanges) {
      notifyListeners();
    }
  }
  // --- CARGAR NOTIFICACIONES DESDE LA API ---
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
            'time': n['fechaCreacion'] != null
                ? DateTime.parse(n['fechaCreacion']).toLocal().toString().substring(0, 16)
                : 'Ahora',
            'isRead': n['leida'] ?? false,
            'datos': n['datos'], // <-- ¡NUEVO! Capturamos los datos extra de tu API
          });
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar notificaciones desde la API: $e');
    }
  }

  // ==========================================
  // --- NUEVA LÓGICA DE POLLING Y CONTADORES
  // ==========================================
  Timer? _pollingTimer;

  void startPolling() {
    // Evita crear múltiples timers
    if (_pollingTimer != null) return; 
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      loadNotifications();
      // Opcional: loadChats() si también quieres que la lista de chats se refresque sola
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Cuenta las notificaciones que son específicamente de chat
  int get totalUnreadChatMessages {
    return notifications.where((n) {
      if (n['isRead'] == true) return false;
      var datos = n['datos'];
      
      // Si por alguna razón la BD lo mandó como texto plano, lo convertimos a Mapa
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
             // Usamos .toString() en ambos lados para evitar el error de (Int vs String)
             datos['incidenciaId']?.toString() == incidenciaId.toString();
    }).length;
  }
  // --- CARGAR REPORTES DESDE LA API ---
  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = AuthService().token;
      if (token != null) {
        final apiReports = await _reportService.getReports(token);
        _reports.clear();
        
        for (var jsonReport in apiReports) {
          _reports.add(Report.fromJson(jsonReport));
        }

        // También cargamos las notificaciones al refrescar reportes
        await loadNotifications();
      }
    } catch (e) {
      debugPrint('Error al cargar reportes de API: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- CREAR REPORTE EN LA API ---
  Future<void> addReport({
    required String title,
    required String details,
    required int idEdificio,
    required int idAula,
    required String reportedBy,
    String? imagePath, 
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = AuthService().token;
      if (token != null) {
        final newApiReport = await _reportService.createReport(
          jwtToken: token,
          titulo: title,
          descripcion: details,
          idEdificio: idEdificio,
          idAula: idAula, 
          imagePath: imagePath,
        );
        
        _reports.insert(0, Report.fromJson(newApiReport));
        await loadNotifications();
      }
    } catch (e) {
      debugPrint('Error al guardar en API: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markNotificationsAsRead() async {
    for (var n in notifications) {
      n['isRead'] = true;
    }
    notifyListeners();

    final token = AuthService().token;
    if (token != null) {
      await _notificationService.markAllAsRead(token);
    }
  }

  Future<void> updateReportStatus(String id, ReportStatus newStatus, {String? imageUrl, String? evidenceUrl}) async {
    // TODO: Falta el endpoint PUT/PATCH en el backend. Por ahora actualizamos en RAM.
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(
        status: newStatus,
        evidenceUrl: evidenceUrl,
      );
      notifyListeners();
    }
  }

  
  List<dynamic> _aulasRaw = [];
  List<dynamic> _edificios = [];
  bool _isLoadingUbicaciones = false;

  bool get isLoadingUbicaciones => _isLoadingUbicaciones;
  List<dynamic> get edificios => _edificios;
  List<dynamic> get aulasRaw => _aulasRaw;

  Future<void> loadUbicaciones() async {
    // Si ya las cargamos antes, no hacemos la petición de nuevo
    if (_aulasRaw.isNotEmpty) return; 

    _isLoadingUbicaciones = true;
    notifyListeners();

    try {
      final token = AuthService().token;
      if (token != null) {
        _aulasRaw = await _aulaService.getAulas(token);
        
        // Extraer edificios únicos
        final Map<int, dynamic> edificiosMap = {};
        for (var aula in _aulasRaw) {
          final edif = aula['edificio'];
          if (edif != null) {
            edificiosMap[edif['id']] = edif;
          }
        }
        _edificios = edificiosMap.values.toList();
      }
    } catch (e) {
      debugPrint('Error al cargar ubicaciones: $e');
    }

    _isLoadingUbicaciones = false;
    notifyListeners();
  }

  // ==========================================
  // --- CHATS DESDE LA API ---
  // ==========================================
  List<dynamic> _chats = [];
  bool _isLoadingChats = false;

  List<dynamic> get chats => _chats;
  bool get isLoadingChats => _isLoadingChats;

  Future<void> loadChats() async {
    _isLoadingChats = true;
    notifyListeners();

    try {
      final token = AuthService().token;
      if (token != null) {
        _chats = await _chatService.getChats(token);
      }
    } catch (e) {
      debugPrint('Error al cargar chats de API: $e');
    }

    _isLoadingChats = false;
    notifyListeners();
  }
  
  // Filtrar aulas dependiendo del edificio seleccionado
  List<dynamic> getAulasPorEdificio(int edificioId) {
    return _aulasRaw.where((a) => a['idEdificio'] == edificioId).toList();
  }
}