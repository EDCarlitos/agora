import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';

class StudentDashboardViewModel extends ChangeNotifier {
  // In-memory list of reports
  final List<Report> _reports = [
    Report(
      id: 'r1',
      title: 'Proyector no enciende',
      description: 'El proyector del aula 201 no responde al control remoto ni al botón de encendido manual.',
      location: 'Edificio A - Aula 201',
      type: ReportType.incidencia,
      status: ReportStatus.pendiente,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      reportedBy: 'Carlos Estudiante',
      category: 'Tecnología',
    ),
    Report(
      id: 'r2',
      title: 'Calculadora Casio fx-991LA',
      description: 'Olvidé mi calculadora científica plateada en la mesa del fondo de la biblioteca.',
      location: 'Edificio Central - Biblioteca',
      type: ReportType.objetoPerdido,
      status: ReportStatus.enProceso,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      reportedBy: 'Carlos Estudiante',
      category: 'Accesorios',
      contactPhone: '555-0199',
    ),
    Report(
      id: 'r3',
      title: 'Fuga de agua en sanitario de varones',
      description: 'El lavamanos izquierdo tiene una gotera constante que inunda parte del suelo.',
      location: 'Edificio B - Planta Baja',
      type: ReportType.incidencia,
      status: ReportStatus.resuelto,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      reportedBy: 'Juan Pérez',
      category: 'Infraestructura',
    ),
    Report(
      id: 'r4',
      title: 'Termo metálico azul',
      description: 'Termo de agua marca Yeti color azul marino, con calcomanía de la facultad de ciencias.',
      location: 'Canchas Deportivas',
      type: ReportType.objetoPerdido,
      status: ReportStatus.resuelto,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      reportedBy: 'Maria Lopez',
      category: 'Artículos Personales',
      contactPhone: '555-0144',
    ),
  ];

  ReportStatus? _statusFilter;
  ReportStatus? get statusFilter => _statusFilter;

  ReportType? _typeFilter;
  ReportType? get typeFilter => _typeFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Returns the filtered list of reports.
  List<Report> get filteredReports {
    return _reports.where((report) {
      final matchesStatus = _statusFilter == null || report.status == _statusFilter;
      final matchesType = _typeFilter == null || report.type == _typeFilter;
      return matchesStatus && matchesType;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  /// Sets the active status filter.
  void setStatusFilter(ReportStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Sets the active type filter.
  void setTypeFilter(ReportType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  /// Resets all filters.
  void resetFilters() {
    _statusFilter = null;
    _typeFilter = null;
    notifyListeners();
  }

  /// Creates and adds a new report to the database.
  Future<void> addReport({
    required String title,
    required String description,
    required String location,
    required ReportType type,
    required String category,
    String? contactPhone,
    required String reportedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Simulate short network latency
    await Future.delayed(const Duration(milliseconds: 600));

    final newReport = Report(
      id: 'r${_reports.length + 1}',
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      type: type,
      status: ReportStatus.pendiente,
      createdAt: DateTime.now(),
      reportedBy: reportedBy,
      category: category.trim(),
      contactPhone: contactPhone?.trim(),
    );

    _reports.insert(0, newReport);
    _isLoading = false;
    notifyListeners();
  }
}
