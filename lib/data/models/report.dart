enum ReportStatus {
  pendiente,
  enProceso,
  resuelto;

  String get displayName {
    switch (this) {
      case ReportStatus.pendiente:
        return 'Pendiente';
      case ReportStatus.enProceso:
        return 'En Proceso';
      case ReportStatus.resuelto:
        return 'Resuelto';
    }
  }
}

enum ReportArea {
  sistema,
  limpieza,
  mantenimiento;

  String get displayName {
    switch (this) {
      case ReportArea.sistema:
        return 'Sistemas';
      case ReportArea.limpieza:
        return 'Limpieza';
      case ReportArea.mantenimiento:
        return 'Mantenimiento';
    }
  }
}

class Report {
  final String id;
  final String title; // Nombre del reporte
  final ReportArea? area; // Area (sistema, limpieza, mantenimiento)
  final String classroom; // Aula
  final String building; // Edificio
  final DateTime dateTime; // Hora y fecha
  final String details; // Detalles del reporte
  final ReportStatus status;
  final String reportedBy;
  final String? imageUrl; // Reference image URL

  const Report({
    required this.id,
    required this.title,
    this.area,
    required this.classroom,
    required this.building,
    required this.dateTime,
    required this.details,
    required this.status,
    required this.reportedBy,
    this.imageUrl,
  });

  Report copyWith({
    String? id,
    String? title,
    ReportArea? area,
    String? classroom,
    String? building,
    DateTime? dateTime,
    String? details,
    ReportStatus? status,
    String? reportedBy,
    String? imageUrl,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      area: area ?? this.area,
      classroom: classroom ?? this.classroom,
      building: building ?? this.building,
      dateTime: dateTime ?? this.dateTime,
      details: details ?? this.details,
      status: status ?? this.status,
      reportedBy: reportedBy ?? this.reportedBy,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
