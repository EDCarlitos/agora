enum ReportType {
  incidencia,
  objetoPerdido;

  String get displayName {
    switch (this) {
      case ReportType.incidencia:
        return 'Incidencia';
      case ReportType.objetoPerdido:
        return 'Objeto Perdido';
    }
  }
}

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

class Report {
  final String id;
  final String title;
  final String description;
  final String location;
  final ReportType type;
  final ReportStatus status;
  final DateTime createdAt;
  final String reportedBy;
  final String category;
  final String? contactPhone; // Useful for lost objects

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.reportedBy,
    required this.category,
    this.contactPhone,
  });

  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    ReportType? type,
    ReportStatus? status,
    DateTime? createdAt,
    String? reportedBy,
    String? category,
    String? contactPhone,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reportedBy: reportedBy ?? this.reportedBy,
      category: category ?? this.category,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }
}
