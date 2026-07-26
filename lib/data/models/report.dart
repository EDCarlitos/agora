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
  final String? incidenciaId;
  final String title;
  final ReportArea? area;
  final String classroom;
  final String building;
  final DateTime dateTime;
  final String details;
  final ReportStatus status;
  final String reportedBy;
  final String? imageUrl;
  final String? evidenceUrl;

  const Report({
    required this.id,
    required this.title,
    this.incidenciaId,
    this.area,
    required this.classroom,
    required this.building,
    required this.dateTime,
    required this.details,
    required this.status,
    required this.reportedBy,
    this.imageUrl,
    this.evidenceUrl,
  });

  /// Factory para construir un Reporte desde el JSON del Backend (Centraliza el parseo)
  factory Report.fromJson(Map<String, dynamic> json, {String? overrideId}) {
    final aula = json['aula'] ?? {};
    final edificio = aula['edificio'] ?? {};
    final reportante = json['reportante'] ?? {};
    final imagenes = json['imagenes'] as List? ?? [];

    ReportStatus parsedStatus = ReportStatus.pendiente;
    if (json['estado'] == 'ACEPTADO') parsedStatus = ReportStatus.enProceso;
    if (json['estado'] == 'FINALIZADO' || json['estado'] == 'RECHAZADO') parsedStatus = ReportStatus.resuelto;

    String? incId;
    String? evidenciaUrl;

    if (json['incidencia'] != null) {
      incId = json['incidencia']['id'].toString();
      
      // --- NUEVO: Leer el estado de la incidencia ---
      final incEstado = json['incidencia']['estado'];
      if (incEstado == 'finalizada' || incEstado == 'cerrada') {
        parsedStatus = ReportStatus.resuelto;
      }

      // OPCIONAL: Extraer la imagen de evidencia si existe para mostrarla en el detalle
      if (json['incidencia']['evidencia'] != null) {
        final imgsEvidencia = json['incidencia']['evidencia']['imagenes'] as List? ?? [];
        if (imgsEvidencia.isNotEmpty) {
          evidenciaUrl = imgsEvidencia[0] is String 
              ? imgsEvidencia[0] 
              : imgsEvidencia[0]['url'];
        }
      }
    }

    return Report(
      id: overrideId ?? json['id'].toString(),
      incidenciaId: incId,
      title: json['titulo'] ?? 'Sin título',
      classroom: aula['nombre'] ?? 'Sin aula',
      building: edificio['nombre'] ?? 'Sin edificio',
      dateTime: json['fechaCreacion'] != null ? DateTime.parse(json['fechaCreacion']).toLocal() : DateTime.now(),
      details: json['descripcion'] ?? 'Sin detalles',
      status: parsedStatus, // <-- Usamos el status corregido
      reportedBy: reportante['username'] ?? reportante['email'] ?? 'Usuario',
      imageUrl: imagenes.isNotEmpty ? imagenes[0]['url'] : null,
      evidenceUrl: evidenciaUrl, 
    );
  }

  /// Propiedad calculada para delegar la lógica de fechas fuera de la UI
  String get timeAgo {
    final now = DateTime.now();
    final localDate = dateTime.toLocal();
    final difference = now.difference(localDate);

    if (difference.inMinutes < 1) return 'Hace un momento';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'Hace 1 día';
    return 'Hace ${difference.inDays} días';
  }

  Report copyWith({
    String? id,
    String? incidenciaId,
    String? title,
    ReportArea? area,
    String? classroom,
    String? building,
    DateTime? dateTime,
    String? details,
    ReportStatus? status,
    String? reportedBy,
    String? imageUrl,
    String? evidenceUrl,
  }) {
    return Report(
      id: id ?? this.id,
      incidenciaId: incidenciaId ?? this.incidenciaId,
      title: title ?? this.title,
      area: area ?? this.area,
      classroom: classroom ?? this.classroom,
      building: building ?? this.building,
      dateTime: dateTime ?? this.dateTime,
      details: details ?? this.details,
      status: status ?? this.status,
      reportedBy: reportedBy ?? this.reportedBy,
      imageUrl: imageUrl ?? this.imageUrl,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    );
  }
}