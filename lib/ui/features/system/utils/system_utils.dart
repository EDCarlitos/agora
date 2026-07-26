import '../../../../data/models/report.dart';

class SystemUtils {
  static Report parseToReport(Map<String, dynamic> json, {String? overrideId}) {
    final aula = json['aula'] ?? {};
    final edificio = aula['edificio'] ?? {};
    final reportante = json['reportante'] ?? {};
    final imagenes = json['imagenes'] as List? ?? [];
    
    ReportStatus parsedStatus = ReportStatus.pendiente;
    if (json['estado'] == 'ACEPTADO') parsedStatus = ReportStatus.enProceso;
    if (json['estado'] == 'FINALIZADO' || json['estado'] == 'RECHAZADO') parsedStatus = ReportStatus.resuelto;
    
    // --- NUEVO: Validar también el estado de la incidencia ---
    if (json['incidencia'] != null) {
      final incEstado = json['incidencia']['estado'];
      if (incEstado == 'finalizada' || incEstado == 'cerrada') {
        parsedStatus = ReportStatus.resuelto;
      }
    }

    return Report(
      id: overrideId ?? json['id'].toString(),
      title: json['titulo'] ?? 'Sin título',
      classroom: aula['nombre'] ?? 'Sin aula',
      building: edificio['nombre'] ?? 'Sin edificio',
      dateTime: json['fechaCreacion'] != null ? DateTime.parse(json['fechaCreacion']).toLocal() : DateTime.now(),
      details: json['descripcion'] ?? '',
      status: parsedStatus, // <-- Usamos el status corregido
      reportedBy: reportante['username'] ?? reportante['email'] ?? 'Usuario',
      imageUrl: imagenes.isNotEmpty ? imagenes[0]['url'] : null,
      area: ReportArea.sistema,
    );
  }
}