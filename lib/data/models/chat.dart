import 'chat_message.dart';

class Chat {
  final int incidenciaId;
  final String? titulo;
  final String? ultimoMensaje;
  final DateTime? fechaUltimoMensaje;
  final int unreadCount;
  final List<ChatMessage> mensajes;

  Chat({
    required this.incidenciaId,
    this.titulo,
    this.ultimoMensaje,
    this.fechaUltimoMensaje,
    this.unreadCount = 0,
    this.mensajes = const [],
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['mensajes'] as List<dynamic>? ?? [];
    return Chat(
      incidenciaId: json['incidenciaId'] as int? ?? json['id'] as int? ?? 0,
      titulo: json['titulo'] as String? ?? json['reporteTitulo'] as String?,
      ultimoMensaje: json['ultimoMensaje'] as String?,
      fechaUltimoMensaje: json['fechaUltimoMensaje'] != null
          ? DateTime.tryParse(json['fechaUltimoMensaje'].toString())?.toLocal()
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      mensajes: rawMessages
          .whereType<Map<String, dynamic>>()
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'incidenciaId': incidenciaId,
    if (titulo != null) 'titulo': titulo,
    if (ultimoMensaje != null) 'ultimoMensaje': ultimoMensaje,
    if (fechaUltimoMensaje != null) 'fechaUltimoMensaje': fechaUltimoMensaje!.toIso8601String(),
    'unreadCount': unreadCount,
    'mensajes': mensajes.map((m) => m.toJson()).toList(),
  };
}
