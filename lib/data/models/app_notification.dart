class AppNotification {
  final String id;
  final String titulo;
  final String mensaje;
  final String? tipo;
  final bool leido;
  final DateTime fecha;
  final String? incidenciaId;

  AppNotification({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.tipo,
    this.leido = false,
    required this.fecha,
    this.incidenciaId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] as String? ?? json['title'] as String? ?? 'Notificación',
      mensaje: json['mensaje'] as String? ?? json['body'] as String? ?? json['message'] as String? ?? '',
      tipo: json['tipo'] as String? ?? json['type'] as String?,
      leido: json['leido'] as bool? ?? json['read'] as bool? ?? false,
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString())?.toLocal() ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now()
              : DateTime.now()),
      incidenciaId: json['incidenciaId']?.toString() ?? json['data']?['incidenciaId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'mensaje': mensaje,
    if (tipo != null) 'tipo': tipo,
    'leido': leido,
    'fecha': fecha.toIso8601String(),
    if (incidenciaId != null) 'incidenciaId': incidenciaId,
  };

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
