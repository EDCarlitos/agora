import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../../data/services/local_database_service.dart';

class StudentDashboardViewModel extends ChangeNotifier {
  final LocalDatabaseService _db = LocalDatabaseService();

  // In-memory list of reports initialized with working picsum.photos images
  final List<Report> _reports = [
    Report(
      id: 'r1',
      title: 'Proyector sin señal',
      area: ReportArea.sistema,
      classroom: 'Aula 302',
      building: 'Edificio de Ingeniería',
      dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      details: 'El proyector muestra pantalla azul y dice "Sin Señal" al conectar el cable HDMI.',
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
      imageUrl: 'https://picsum.photos/id/870/600/400', // Verified working ID
    ),
    Report(
      id: 'r2',
      title: 'Foco parpadeando',
      area: ReportArea.mantenimiento,
      classroom: 'Aula 101',
      building: 'Edificio A',
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      details: 'La lámpara fluorescente del centro parpadea constantemente interrumpiendo la clase.',
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
      imageUrl: 'https://picsum.photos/id/250/600/400',
    ),
    Report(
      id: 'r3',
      title: 'Derrame en cafetería',
      area: ReportArea.limpieza,
      classroom: 'Cafetería Central',
      building: 'Edificio Central',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      details: 'Se cayó un termo de café en el pasillo principal y está resbaloso.',
      status: ReportStatus.enProceso,
      reportedBy: 'Ana Estudiante',
      imageUrl: 'https://picsum.photos/id/1084/600/400',
    ),
    Report(
      id: 'r4',
      title: 'Baños sucios',
      area: ReportArea.limpieza,
      classroom: 'Edificio A, Piso 1',
      building: 'Edificio A',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      details: 'Falta papel higiénico y limpieza general en los cubículos de caballeros.',
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
      imageUrl: 'https://picsum.photos/id/364/600/400',
    ),
    Report(
      id: 'r5',
      title: 'Falla de WiFi',
      area: ReportArea.sistema,
      classroom: 'Biblioteca',
      building: 'Edificio Central',
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      details: 'La red UPQROO_Alumnos no permite conectarse ni asigna dirección IP.',
      status: ReportStatus.pendiente,
      reportedBy: 'Sofia Estudiante',
      imageUrl: 'https://picsum.photos/id/60/600/400',
    ),
    Report(
      id: 'r6',
      title: 'Mesa de trabajo rota',
      area: ReportArea.mantenimiento,
      classroom: 'Biblioteca Central',
      building: 'Edificio Central',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      details: 'Una de las patas de madera de la mesa redonda del fondo está desprendida.',
      status: ReportStatus.resuelto,
      reportedBy: 'Pedro Alumno',
      imageUrl: 'https://picsum.photos/id/20/600/400',
    ),
    Report(
      id: 'r7',
      title: 'Aire acondicionado goteando',
      area: ReportArea.mantenimiento,
      classroom: 'Aula 101',
      building: 'Edificio A',
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      details: 'El minisplit del salón gotea agua directamente sobre las bancas de la primera fila.',
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
      imageUrl: 'https://picsum.photos/id/370/600/400',
    ),
  ];

  // In-memory list of mock notifications
  final List<Map<String, dynamic>> notifications = [
    {
      'id': 'n1',
      'title': 'Actualización de Reporte',
      'body': 'Tu reporte "Derrame en cafetería" ha cambiado a En Proceso.',
      'time': 'Hace 10 min',
      'isRead': false,
    },
    {
      'id': 'n2',
      'title': 'Reporte Resuelto',
      'body': 'La "Mesa de trabajo rota" en Biblioteca ha sido reparada.',
      'time': 'Ayer',
      'isRead': true,
    }
  ];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Report> get allReports => _reports;

  /// Returns only incidents
  List<Report> get incidents {
    return _reports
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Filtered by user (for "Ver todos mis reportes")
  List<Report> getMyReports(String userName) {
    return _reports.where((r) => r.reportedBy == userName).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Adds a new report and saves it to local SQLite database as well
  Future<void> addReport({
    required String title,
    ReportArea? area,
    required String classroom,
    required String building,
    required DateTime dateTime,
    required String details,
    required String reportedBy,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final newReport = Report(
      id: 'r${_reports.length + 1}',
      title: title.trim(),
      area: area,
      classroom: classroom.trim(),
      building: building.trim(),
      dateTime: dateTime,
      details: details.trim(),
      status: ReportStatus.pendiente,
      reportedBy: reportedBy,
      imageUrl: imageUrl,
    );

    // Save in RAM
    _reports.insert(0, newReport);
    
    // Save in Local DB (SQLite via sqflite)
    try {
      await _db.saveIncident(newReport);
    } catch (e) {
      debugPrint('Error al guardar en base de datos local: $e');
    }

    // Auto-generate a local notification for report creation
    notifications.insert(0, {
      'id': 'n${notifications.length + 1}',
      'title': 'Reporte Creado',
      'body': 'Has publicado exitosamente: "${newReport.title}".',
      'time': 'Ahora mismo',
      'isRead': false,
    });

    _isLoading = false;
    notifyListeners();
  }

  /// Marks notifications as read
  void markNotificationsAsRead() {
    for (var n in notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
  }
}
