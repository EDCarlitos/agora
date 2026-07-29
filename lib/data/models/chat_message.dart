class ChatMessage {
  final int? id;
  final int? incidenciaId;
  final String mensaje;
  final String tipo; // 'mensaje' | 'imagen'
  final String enviadoPor;
  final DateTime fechaEnvio;

  ChatMessage({
    this.id,
    this.incidenciaId,
    required this.mensaje,
    required this.tipo,
    required this.enviadoPor,
    required this.fechaEnvio,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
      incidenciaId: json['incidenciaId'] as int?,
      mensaje: json['mensaje'] as String? ?? json['contenido'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'mensaje',
      enviadoPor: json['enviadoPor'] as String? ?? json['remitente'] as String? ?? '',
      fechaEnvio: json['fechaEnvio'] != null
          ? DateTime.tryParse(json['fechaEnvio'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (incidenciaId != null) 'incidenciaId': incidenciaId,
    'mensaje': mensaje,
    'tipo': tipo,
    'enviadoPor': enviadoPor,
    'fechaEnvio': fechaEnvio.toIso8601String(),
  };
}
