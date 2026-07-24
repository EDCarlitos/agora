import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/chat_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../view_models/student_dashboard_view_model.dart';
import '../../widgets/message_bubble.dart';

class Message {
  final String text;
  final bool isOutgoing;
  final DateTime time;
  final String? imageUrl;
  final bool isSystem;

  Message({
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
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  
  late ReportStatus _currentReportStatus;
  final _picker = ImagePicker();
  
  final _chatService = ChatService();
  final _viewModel = StudentDashboardViewModel(); 

  @override
  void initState() {
    super.initState();
    _currentReportStatus = widget.report.status;
    _loadChatData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- 1. CARGAR DATOS DESDE LA API ---
  void _loadChatData() async {
    try {
      final token = AuthService().token;
      if (token == null) return;
      
      final incidenciaId = int.parse(widget.report.id); // Pasamos el ID de incidencia en el mockReport
      final chatData = await _chatService.getChatDetail(token, incidenciaId);

      final msgsJson = chatData['mensajes'] as List;
      
      setState(() {
        // Mensaje inicial de sistema para dar contexto visual
        _messages.add(
          Message(
            text: 'Conectado al chat de soporte para el reporte en ${widget.report.classroom}.',
            isOutgoing: false,
            time: DateTime.now(),
            isSystem: true,
          )
        );
        
        // Mapear los mensajes de la API
        _messages.addAll(msgsJson.map((m) => _parseApiMessage(m)).toList());
        _isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error al cargar chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el historial: $e')),
        );
      }
    }
  }

  // Mapea el JSON de la BD a nuestra clase Message
  Message _parseApiMessage(Map<String, dynamic> m) {
    final enviadoPor = m['enviadoPor'];
    // Validar si fue enviado por nosotros comparando username o email
    final isOutgoing = (enviadoPor == widget.currentUser.name || enviadoPor == widget.currentUser.email);
    final isImagen = m['tipo'] == 'imagen';

    return Message(
      text: isImagen ? '' : m['mensaje'],
      imageUrl: isImagen ? m['mensaje'] : null,
      isOutgoing: isOutgoing,
      time: DateTime.parse(m['fechaEnvio']).toLocal(),
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
      final incidenciaId = int.parse(widget.report.id);
      final tipo = imagePath != null ? 'imagen' : 'mensaje';

      final newMsgJson = await _chatService.sendMessage(
        jwtToken: token,
        incidenciaId: incidenciaId,
        tipo: tipo,
        contenido: imagePath == null ? msgText : null,
        imagePath: imagePath,
      );

      setState(() {
        _messages.add(_parseApiMessage(newMsgJson));
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

  void _showAttachmentMenu() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261D16) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Enviar Adjunto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    color: Colors.blue.shade600,
                    onTap: () async {
                      Navigator.pop(context);
                      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                      if (file != null) _sendMessage(imagePath: file.path);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.image_rounded,
                    label: 'Galería',
                    color: AppTheme.primaryColor,
                    onTap: () async {
                      Navigator.pop(context);
                      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (file != null) _sendMessage(imagePath: file.path);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
              if (_currentReportStatus != ReportStatus.resuelto)
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
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file_rounded, color: AppTheme.primaryColor),
                        onPressed: _showAttachmentMenu,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF261D16) : const Color(0xFFF5F2EE),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? Colors.white : AppTheme.secondaryColor,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _sendMessage(),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: isDark ? const Color(0xFF1C140E) : Colors.white,
                  child: Center(
                    child: Text(
                      'Este reporte ha sido marcado como Terminado y no se permiten más mensajes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
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