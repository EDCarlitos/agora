import 'dart:async';
import 'dart:convert';
import '../../widgets/agora_network_image.dart';
import 'package:http/http.dart' as http;
import '../../../../utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/chat.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../data/services/chat_service.dart';
import '../../../../data/services/chat_websocket_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../students/view_models/student_dashboard_view_model.dart';
import '../../widgets/image_source_bottom_sheet.dart';
import '../../widgets/message_bubble.dart';
import '../../system/view_models/systems_dashboard_view_model.dart';

class Message {
  final int? id;
  final String text;
  final bool isOutgoing;
  final DateTime time;
  final String? imageUrl;
  final bool isSystem;

  Message({
    this.id,
    required this.text,
    required this.isOutgoing,
    required this.time,
    this.imageUrl,
    this.isSystem = false,
  });
}

class ChatRoomView extends StatefulWidget {
  final Report report;
  final User currentUser;

  const ChatRoomView({
    super.key,
    required this.report,
    required this.currentUser,
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  String _estadoIncidenciaAPI = 'abierta';
  Map<String, dynamic>? _evidenciaFinal;
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  StreamSubscription? _wsSubscription;
  
  late ReportStatus _currentReportStatus;
  final _picker = ImagePicker();
  
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _currentReportStatus = widget.report.status;
    _loadChatData();
    
    final incidenciaIdStr = widget.report.incidenciaId ?? widget.report.id;
    
    // Validamos el rol para limpiar las notificaciones en el ViewModel correcto
    if (widget.currentUser.role == UserRole.sistemas) {
      SystemsDashboardViewModel().markChatNotificationsAsRead(incidenciaIdStr);
    } else {
      StudentDashboardViewModel().markChatNotificationsAsRead(incidenciaIdStr);
    }
  }

  @override
  void dispose() {
    final incidenciaIdStr = widget.report.incidenciaId ?? widget.report.id;
    final incidenciaId = int.tryParse(incidenciaIdStr);
    if (incidenciaId != null) {
      ChatWebSocketService().leaveRoom(incidenciaId);
    }
    _wsSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addMessageIfNotExists(Message parsedMsg) {
    final exists = _messages.any((m) {
      if (parsedMsg.id != null && m.id != null) {
        return m.id == parsedMsg.id;
      }
      return m.text == parsedMsg.text &&
          m.imageUrl == parsedMsg.imageUrl &&
          m.isOutgoing == parsedMsg.isOutgoing &&
          m.time.difference(parsedMsg.time).inSeconds.abs() < 5;
    });
    if (!exists) {
      _messages.add(parsedMsg);
    }
  }

  void _setupWebSocket(String token, int incidenciaId) {
    final ws = ChatWebSocketService();
    ws.connect(token);
    ws.joinRoom(incidenciaId);

    _wsSubscription?.cancel();
    _wsSubscription = ws.stream.listen((data) {
      if (data['type'] == 'new_message' && data['incidenciaId'] == incidenciaId) {
        final rawMsg = data['mensaje'];
        if (rawMsg != null && rawMsg is Map<String, dynamic>) {
          final chatMsg = ChatMessage.fromJson(rawMsg);
          final parsedMsg = _parseChatMessage(chatMsg);

          if (mounted) {
            setState(() {
              _addMessageIfNotExists(parsedMsg);
            });
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }
        }
      }
    });
  }

  // --- 1. CARGAR DATOS DESDE LA API ---
  void _loadChatData() async {
    try {
      final token = AuthService().token;
      if (token == null) return;

      final incidenciaIdStr = widget.report.incidenciaId ?? widget.report.id;
      final incidenciaId = int.parse(incidenciaIdStr);

      _setupWebSocket(token, incidenciaId);

      // 1. Cargar Mensajes
      final chatData = await _chatService.getChatDetail(token, incidenciaId);
      final msgs = chatData.mensajes;

      // 2. Cargar Estado y Evidencia haciendo fetch al endpoint existente
      final url = Uri.parse('${ApiConfig.baseUrl}/incidencias/$incidenciaId');
      final incidenciaRes = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (incidenciaRes.statusCode == 200) {
        final data = jsonDecode(incidenciaRes.body)['incidencia'];
        _estadoIncidenciaAPI = data['estado'] ?? 'abierta';
        _evidenciaFinal = data['evidencia'];
      }
      
      setState(() {
        _messages.clear();
        _messages.add(
          Message(
            text: 'Conectado al chat de soporte para el reporte en ${widget.report.classroom}.',
            isOutgoing: false,
            time: DateTime.now(),
            isSystem: true,
          )
        );

        _messages.addAll(msgs.map((m) => _parseChatMessage(m)).toList());
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
      }
    }
  }

  // Mapea el modelo ChatMessage a nuestra clase Message de la vista
  Message _parseChatMessage(ChatMessage m) {
    final enviadoPor = m.enviadoPor;
    final isOutgoing = (enviadoPor == widget.currentUser.name || enviadoPor == widget.currentUser.email);
    final isImagen = m.tipo == 'imagen';

    return Message(
      id: m.id,
      text: isImagen ? '' : m.mensaje,
      imageUrl: isImagen ? m.mensaje : null,
      isOutgoing: isOutgoing,
      time: m.fechaEnvio.toLocal(),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- 2. ENVIAR MENSAJE ---
  Future<void> _sendMessage({String? text, String? imagePath}) async {
    final msgText = text ?? _textController.text.trim();
    if (msgText.isEmpty && imagePath == null) return;

    if (imagePath == null) {
      _textController.clear();
    }
    
    setState(() => _isTyping = true);

    try {
      final token = AuthService().token!;
      final incidenciaIdStr = widget.report.incidenciaId ?? widget.report.id;
      final incidenciaId = int.parse(incidenciaIdStr);
      final tipo = imagePath != null ? 'imagen' : 'mensaje';

      final newMsg = await _chatService.sendMessage(
        jwtToken: token,
        incidenciaId: incidenciaId,
        tipo: tipo,
        contenido: imagePath == null ? msgText : null,
        imagePath: imagePath,
      );

      setState(() {
        _addMessageIfNotExists(_parseChatMessage(newMsg));
        _isTyping = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() => _isTyping = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAttachmentMenu() async {
    final source = await ImageSourceBottomSheet.show(context);
    if (source != null) {
      final file = await _picker.pickImage(source: source, imageQuality: 70);
      if (file != null) {
        _sendMessage(imagePath: file.path);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleBgOutgoing = AppTheme.primaryColor;
    final bubbleBgIncoming = isDark ? const Color(0xFF261D16) : Colors.white;
    final textOutgoingColor = Colors.white;
    final textIncomingColor = isDark ? Colors.white.withOpacity(0.85) : AppTheme.secondaryColor;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
              child: const Icon(Icons.support_agent_rounded, size: 18, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.secondaryColor,
                    ),
                  ),
                  Text(
                    'Soporte Técnico',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF140D09) : const Color(0xFFFAF5F0),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Área de Mensajes
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(
                          msg: _messages[index],
                          bgOutgoing: bubbleBgOutgoing,
                          bgIncoming: bubbleBgIncoming,
                          textOutColor: textOutgoingColor,
                          textInColor: textIncomingColor,
                        );
                      },
                    ),
              ),

              // Indicador de Carga al enviar
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 12, top: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text(
                        'Enviando...',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

              // Barra inferior para escribir
              if (_estadoIncidenciaAPI == 'finalizada' || _estadoIncidenciaAPI == 'cerrada')
                Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF1C140E) : Colors.white,
                  child: Column(
                    children: [
                      // Tarjeta de Evidencia enviada por el técnico
                      if (_evidenciaFinal != null)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text('Incidencia Resuelta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _evidenciaFinal!['descripcion'] ?? 'Resuelta sin comentarios adicionales.',
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                              ),
                              if (_evidenciaFinal!['imagenes'] != null && (_evidenciaFinal!['imagenes'] as List).isNotEmpty)
                                ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 80,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: (_evidenciaFinal!['imagenes'] as List).length,
                                      itemBuilder: (context, i) => Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: AgoraNetworkImage(
                                          imageUrl: _evidenciaFinal!['imagenes'][i],
                                          height: 80,
                                          width: 80,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  )
                                ]
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
                        child: Text(
                          'Este reporte ha sido marcado como Terminado por Sistemas y no se permiten más mensajes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C140E) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFEBE7),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
                          onPressed: _showAttachmentMenu,
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF261D16) : const Color(0xFFF5F2EE),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            onPressed: () => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}