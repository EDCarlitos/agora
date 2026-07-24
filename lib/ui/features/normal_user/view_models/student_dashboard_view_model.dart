import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/report.dart';
import '../../../../data/services/report_service.dart';
import '../../../../data/services/auth_service.dart'; // Importante para obtener el token
import '../../../../data/services/notification_service.dart';
import '../../../../data/services/aula_service.dart';
import '../../../../data/services/chat_service.dart';

class StudentDashboardViewModel extends ChangeNotifier {
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

  List<Report> getMyReports(User user) {
    // Filtramos estrictamente bajo la condición de que el reportante
    // coincida con el nombre de usuario o el correo de la sesión actual.
    final filtered = _reports.where((r) => 
      r.reportedBy == user.name || r.reportedBy == user.email
    ).toList();
    
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return filtered;
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
          });
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar notificaciones desde la API: $e');
    }
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
          _reports.add(_mapBackendToReport(jsonReport));
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

        _reports.insert(0, _mapBackendToReport(newApiReport));
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

  // --- MAPPER: Backend JSON a Frontend Model ---
  Report _mapBackendToReport(Map<String, dynamic> json) {
    String? imageUrl;
    
    // 1. Extraemos la imagen de Cloudinary
    if (json['imagenes'] != null && (json['imagenes'] as List).isNotEmpty) {
      imageUrl = json['imagenes'][0]['url']; 
    }
    String? incId;
    if (json['incidencia'] != null) {
      incId = json['incidencia']['id'].toString();
    }   

    // REPORTANTE
    String nombreReportante = 'Usuario Desconocido';
    if (json['reportante'] != null) {
      nombreReportante = json['reportante']['username'] ?? json['reportante']['email'] ?? 'Usuario';
    }

    // AULA
    String aula = 'Aula no asignada';
    if (json['aula'] != null) {
      if (json['aula'] is Map<String, dynamic>) {
        aula = json['aula']['nombre'] ?? 'Aula no asignada';
      } else {
        aula = json['aula'].toString();
      }
    }

    // EDIFICIO
    String edificio = 'Edificio no asignado';
    if (json['aula'] != null && json['aula']['edificio'] != null) {
      if (json['aula']['edificio'] is Map<String, dynamic>) {
        edificio = json['aula']['edificio']['nombre'] ?? 'Edificio no asignado';
      } else {
        // Por si alguna vez mandan solo el texto en lugar del objeto
        edificio = json['aula']['edificio'].toString();
      }
    }

    // AREA
    ReportArea areaInferida = ReportArea.sistema;
    final tipoStr = (json['tipo'] ?? '').toLowerCase();
    if (tipoStr.contains('limpieza') || tipoStr.contains('basura') || tipoStr.contains('derrame')) {
      areaInferida = ReportArea.limpieza;
    } else if (tipoStr.contains('silla') || tipoStr.contains('puerta') || tipoStr.contains('pizarrón')) {
      areaInferida = ReportArea.mantenimiento;
    }

    // MODELO TOTAL
    return Report(
      id: json['id'].toString(),
      incidenciaId: incId, // <-- NUEVO
      title: json['titulo'] ?? 'Sin título',
      area: areaInferida,
      classroom: aula,
      building: edificio,
      dateTime: json['fechaCreacion'] != null ? DateTime.parse(json['fechaCreacion']) : DateTime.now(),
      details: json['descripcion'] ?? 'Sin detalles',
      status: _parseStatus(json['estado']),
      reportedBy: nombreReportante,
      imageUrl: imageUrl,
    );
  }
  
  ReportStatus _parseStatus(String? status) {
    if (status == 'ACEPTADO') return ReportStatus.enProceso;
    if (status == 'RECHAZADO') return ReportStatus.resuelto;
    return ReportStatus.pendiente; // 'NUEVO'
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