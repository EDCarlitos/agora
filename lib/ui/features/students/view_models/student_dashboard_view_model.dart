import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/aula.dart';
import '../../../../data/models/chat.dart';
import '../../../../data/models/app_notification.dart';
import '../../../../data/services/report_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../data/services/aula_service.dart';
import '../../../../data/services/chat_service.dart';
import '../../widgets/shared_chats_tab.dart';
import '../../../../data/services/connectivity_service.dart';
import '../../../../data/services/local_database_service.dart';

class StudentDashboardViewModel extends ChangeNotifier implements IChatViewModel {
  static final StudentDashboardViewModel _instance = StudentDashboardViewModel._internal();
  factory StudentDashboardViewModel() => _instance;
  StreamSubscription? _connectivitySubscription;
  
  StudentDashboardViewModel._internal() {
    loadReports();
    loadNotifications();
    _startNetworkListener();
  }

  final ReportService _reportService = ReportService();
  final NotificationService _notificationService = NotificationService();
  final List<Report> _reports = [];
  final ChatService _chatService = ChatService(); 
  final AulaService _aulaService = AulaService();
  final List<AppNotification> notifications = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _startNetworkListener() {
    _connectivitySubscription = ConnectivityService().onConnectivityChanged.listen((results) {
      // Si la lista de resultados NO contiene "none", significa que hay internet
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint('Internet detectado. Intentando sincronizar reportes offline...');
        syncOfflineReports();
      }
    });
  }
  
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
    final filtered = _reports.where((r) => 
      r.reportedBy == user.name || r.reportedBy == user.email
    ).toList();
    
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return filtered;
  }
  @override
  void dispose() {
    _connectivitySubscription?.cancel(); // Evitar fugas de memoria
    stopPolling();
    super.dispose();
  }


Future<void> markChatNotificationsAsRead(String incidenciaId) async {
    final token = AuthService().token;
    if (token == null) return;

    bool hasChanges = false;

    for (int i = 0; i < notifications.length; i++) {
      final n = notifications[i];
      if (n.leido) continue;

      if (n.incidenciaId == incidenciaId.toString()) {
        notifications[i] = AppNotification(
          id: n.id,
          titulo: n.titulo,
          mensaje: n.mensaje,
          tipo: n.tipo,
          leido: true,
          fecha: n.fecha,
          incidenciaId: n.incidenciaId,
        );
        hasChanges = true;
        await _notificationService.markAsRead(token, n.id);
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  Future<void> markNotificationsAsRead() async {
    final token = AuthService().token;
    if (token == null) return;
    for (int i = 0; i < notifications.length; i++) {
      final n = notifications[i];
      if (!n.leido) {
        notifications[i] = AppNotification(
          id: n.id,
          titulo: n.titulo,
          mensaje: n.mensaje,
          tipo: n.tipo,
          leido: true,
          fecha: n.fecha,
          incidenciaId: n.incidenciaId,
        );
      }
    }
    notifyListeners();
    await _notificationService.markAllAsRead(token);
  }

  // --- CARGAR NOTIFICACIONES DESDE LA API ---
  Future<void> loadNotifications() async {
    try {
      final token = AuthService().token;
      if (token != null) {
        final apiNotifications = await _notificationService.getNotifications(token);
        notifications.clear();
        notifications.addAll(apiNotifications);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar notificaciones desde la API: $e');
    }
  }

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

  @override
  int get totalUnreadChatMessages {
    return notifications.where((n) => !n.leido && n.tipo == 'NUEVO_MENSAJE').length;
  }

  @override
  int getUnreadCountForChat(String incidenciaId) {
    return notifications.where((n) => !n.leido && n.incidenciaId == incidenciaId.toString()).length;
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
        _reports.addAll(apiReports);

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
    required List<String> imagePaths,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasConnection = await ConnectivityService().isConnected;

      if (hasConnection) {
        final token = AuthService().token;
        if (token != null) {
          final newApiReport = await _reportService.createReport(
            jwtToken: token,
            titulo: title,
            descripcion: details,
            idEdificio: idEdificio,
            idAula: idAula,
            imagePaths: imagePaths,
          );
          
          _reports.insert(0, newApiReport);
          await loadNotifications();
        }
      } else {
        // MODO OFFLINE: Guardar en SQLite
        final offlineReport = Report(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          classroom: idAula.toString(), // Truco: guardamos el ID para sincronizar luego
          building: idEdificio.toString(), // Truco: guardamos el ID
          dateTime: DateTime.now(),
          details: details,
          status: ReportStatus.pendiente,
          reportedBy: reportedBy,
          // Guardamos las rutas de las fotos separadas por comas
          imageUrl: imagePaths.isNotEmpty ? imagePaths.join(',') : null, 
          area: ReportArea.sistema,
        );
        
        await LocalDatabaseService().saveIncident(offlineReport);
        _reports.insert(0, offlineReport); // Lo mostramos en la UI para que el usuario no sienta que se perdió
      }
    } catch (e) {
      debugPrint('Error al procesar el reporte: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- SINCRONIZAR REPORTES PENDIENTES ---
  Future<void> syncOfflineReports() async {
    final hasConnection = await ConnectivityService().isConnected;
    if (!hasConnection) return;

    final token = AuthService().token;
    if (token == null) return;

    try {
      // Obtenemos los reportes que se guardaron offline (los que tienen prefijo 'local_')
      final allLocal = await LocalDatabaseService().getIncidents();
      final pendingReports = allLocal.where((r) => r.id.startsWith('local_')).toList();

      for (var localReq in pendingReports) {
        List<String> paths = localReq.imageUrl != null && localReq.imageUrl!.isNotEmpty 
            ? localReq.imageUrl!.split(',') 
            : [];

        // Los enviamos a la API
        await _reportService.createReport(
          jwtToken: token,
          titulo: localReq.title,
          descripcion: localReq.details,
          idEdificio: int.parse(localReq.building), // Recuperamos los IDs
          idAula: int.parse(localReq.classroom),
          imagePaths: paths,
        );

        // Si se envió con éxito, lo borramos de SQLite
        await LocalDatabaseService().deleteIncident(localReq.id);
      }
      
      // Recargamos los reportes reales de la API
      if (pendingReports.isNotEmpty) {
        await loadReports();
      }
    } catch (e) {
      debugPrint('Error sincronizando reportes offline: $e');
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

  
  List<Aula> _aulasRaw = [];
  List<Edificio> _edificios = [];
  bool _isLoadingUbicaciones = false;

  bool get isLoadingUbicaciones => _isLoadingUbicaciones;
  List<Edificio> get edificios => _edificios;
  List<Aula> get aulasRaw => _aulasRaw;

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
        final Map<int, Edificio> edificiosMap = {};
        for (var aula in _aulasRaw) {
          final edif = aula.edificio;
          if (edif != null) {
            edificiosMap[edif.id] = edif;
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
  List<Chat> _chats = [];
  bool _isLoadingChats = false;

  List<Chat> get chats => _chats;
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
  List<Aula> getAulasPorEdificio(int edificioId) {
    return _aulasRaw.where((a) => a.idEdificio == edificioId).toList();
  }
}