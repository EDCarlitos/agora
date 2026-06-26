import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';

class StudentDashboardViewModel extends ChangeNotifier {
  // In-memory list of reports preloaded to match the user's image reference
  final List<Report> _reports = [
    Report(
      id: 'r1',
      title: 'Proyector sin señal',
      area: ReportArea.sistema,
      classroom: 'Aula 302',
      building: 'Edificio de Ingeniería',
      dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      details: 'El proyector muestra pantalla azul y dice "Sin Señal" al conectar el cable HDMI.',
      type: ReportType.incidencia,
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
    ),
    Report(
      id: 'r2',
      title: 'Foco parpadeando',
      area: ReportArea.mantenimiento,
      classroom: 'Aula 101',
      building: 'Edificio A',
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      details: 'La lámpara fluorescente del centro parpadea constantemente interrumpiendo la clase.',
      type: ReportType.incidencia,
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
    ),
    Report(
      id: 'r3',
      title: 'Derrame en cafetería',
      area: ReportArea.limpieza,
      classroom: 'Cafetería Central',
      building: 'Edificio Central',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      details: 'Se cayó un termo de café en el pasillo principal y está resbaloso.',
      type: ReportType.incidencia,
      status: ReportStatus.enProceso,
      reportedBy: 'Ana Estudiante',
    ),
    Report(
      id: 'r4',
      title: 'Baños sucios',
      area: ReportArea.limpieza,
      classroom: 'Edificio A, Piso 1',
      building: 'Edificio A',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      details: 'Falta papel higiénico y limpieza general en los cubículos de caballeros.',
      type: ReportType.incidencia,
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
    ),
    Report(
      id: 'r5',
      title: 'Falla de WiFi',
      area: ReportArea.sistema,
      classroom: 'Biblioteca',
      building: 'Edificio Central',
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      details: 'La red UPQROO_Alumnos no permite conectarse ni asigna dirección IP.',
      type: ReportType.incidencia,
      status: ReportStatus.pendiente,
      reportedBy: 'Sofia Estudiante',
    ),
    Report(
      id: 'r6',
      title: 'Mesa de trabajo rota',
      area: ReportArea.mantenimiento,
      classroom: 'Biblioteca Central',
      building: 'Edificio Central',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      details: 'Una de las patas de madera de la mesa redonda del fondo está desprendida.',
      type: ReportType.incidencia,
      status: ReportStatus.resuelto,
      reportedBy: 'Pedro Alumno',
    ),
    Report(
      id: 'r7',
      title: 'Aire acondicionado goteando',
      area: ReportArea.mantenimiento,
      classroom: 'Aula 101',
      building: 'Edificio A',
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      details: 'El minisplit del salón gotea agua directamente sobre las bancas de la primera fila.',
      type: ReportType.incidencia,
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
    ),
    Report(
      id: 'r8',
      title: 'Audífonos Bluetooth Negros',
      classroom: 'Laboratorio de Cómputo 2',
      building: 'Edificio C',
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      details: 'Audífonos inalámbricos marca JBL negros, olvidados al lado del monitor 12.',
      type: ReportType.objetoPerdido,
      status: ReportStatus.pendiente,
      reportedBy: 'Carlos Estudiante',
    ),
    Report(
      id: 'r9',
      title: 'Libro de Cálculo Thomas',
      classroom: 'Cubículos de estudio',
      building: 'Biblioteca',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      details: 'Pasta blanda, decimocuarta edición, tiene mi nombre escrito en la primera página.',
      type: ReportType.objetoPerdido,
      status: ReportStatus.enProceso,
      reportedBy: 'Carlos Estudiante',
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
      'title': 'Objeto Encontrado',
      'body': 'Se ha entregado un libro de cálculo en administración que coincide con tu reporte.',
      'time': 'Hace 2 horas',
      'isRead': false,
    },
    {
      'id': 'n3',
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
    return _reports.where((r) => r.type == ReportType.incidencia).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Returns only lost objects
  List<Report> get lostObjects {
    return _reports.where((r) => r.type == ReportType.objetoPerdido).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Filtered by user (for "Ver todos mis reportes")
  List<Report> getMyReports(String userName) {
    return _reports.where((r) => r.reportedBy == userName).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Adds a new report (Incident or Lost Object)
  Future<void> addReport({
    required String title,
    ReportArea? area,
    required String classroom,
    required String building,
    required DateTime dateTime,
    required String details,
    required ReportType type,
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
      type: type,
      status: ReportStatus.pendiente,
      reportedBy: reportedBy,
      imageUrl: imageUrl,
    );

    _reports.insert(0, newReport);
    
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
