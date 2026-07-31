import '../../../../data/models/report.dart';

class SystemUtils {
  static Report parseToReport(Map<String, dynamic> json, {String? overrideId}) {
    final aula = json['aula'] ?? {};
    final edificio = aula['edificio'] ?? {};
    final reportante = json['reportante'] ?? {};
    final imagenes = json['imagenes'] as List? ?? [];
    
    List<String> parsedUrls = [];
    for (var img in imagenes) {
      if (img is String && img.isNotEmpty) {
        parsedUrls.add(img);
      } else if (img is Map && img['url'] != null) {
        parsedUrls.add(img['url'].toString());
      }
    }

    if (parsedUrls.isEmpty && json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      final imgStr = json['imageUrl'].toString();
      if (imgStr.contains(',')) {
        parsedUrls = imgStr.split(',').where((s) => s.isNotEmpty).toList();
      } else {
        parsedUrls = [imgStr];
      }
    }

    ReportStatus parsedStatus = ReportStatus.pendiente;
    if (json['estado'] == 'ACEPTADO') parsedStatus = ReportStatus.enProceso;
    if (json['estado'] == 'FINALIZADO') parsedStatus = ReportStatus.resuelto;
    if (json['estado'] == 'RECHAZADO') parsedStatus = ReportStatus.rechazado; // <-- NUEVO MAPEO
    
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
      imageUrl: parsedUrls.isNotEmpty ? parsedUrls.first : null,
      imageUrls: parsedUrls,
      area: ReportArea.sistema,
    );
  }
}