import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/cloudinary_service.dart';
import '../../../core/theme.dart';
import '../view_models/student_dashboard_view_model.dart';

class Message {
  final String text;
  final bool isOutgoing;
  final DateTime time;
  final String? imageUrl;
  final bool isAudio;
  final String? audioDuration;
  final bool isSystem;

  Message({
    required this.text,
    required this.isOutgoing,
    required this.time,
    this.imageUrl,
    this.isAudio = false,
    this.audioDuration,
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
  final List<Message> _messages = [];
  bool _isTyping = false;
  List<String> _quickReplies = [];
  
  late ReportStatus _currentReportStatus;
  bool _isResolving = false;

  final _picker = ImagePicker();
  final _cloudinaryService = CloudinaryService();
  final _viewModel = StudentDashboardViewModel(); // Shared singleton instance

  @override
  void initState() {
    super.initState();
    _currentReportStatus = widget.report.status;
    _loadInitialMessages();
    _loadQuickReplies();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadQuickReplies() {
    final area = widget.report.area;
    final isStaff = widget.currentUser.role != UserRole.estudiante;

    if (isStaff) {
      _quickReplies = [
        'Ya voy en camino',
        'Necesito más información',
        'Revisión completada',
        'Favor de confirmar solución',
      ];
    } else {
      if (area == ReportArea.sistema) {
        _quickReplies = [
          '¿Hay alguna novedad?',
          'Ya reinicié el router',
          'Sigo sin red',
          '¡Muchas gracias por resolverlo!',
        ];
      } else if (area == ReportArea.mantenimiento) {
        _quickReplies = [
          '¿A qué hora vendrán?',
          'Sigue goteando',
          '¿Ocupan más fotos?',
          'Entendido, gracias',
        ];
      } else {
        _quickReplies = [
          'Ya se encuentra limpio',
          'Falta jabón/papel',
          'Gracias por atenderlo',
          '¿Cuándo pasarán?',
        ];
      }
    }
  }

  void _loadInitialMessages() {
    // 1. System banner for report info
    _messages.add(
      Message(
        text: 'Reporte: "${widget.report.title}" en ${widget.report.classroom} (${widget.report.building}). Estado: ${_currentReportStatus.name.toUpperCase()}',
        isOutgoing: false,
        time: widget.report.dateTime,
        isSystem: true,
      ),
    );

    // 2. If the user attached an image during creation, show it in the chat
    if (widget.report.imageUrl != null && widget.report.imageUrl!.isNotEmpty) {
      _messages.add(
        Message(
          text: 'Imagen de referencia adjunta al reporte original.',
          isOutgoing: true,
          time: widget.report.dateTime,
          imageUrl: widget.report.imageUrl,
        ),
      );
    }

    // 3. Initial greeting from the corresponding department
    final areaName = widget.report.area == ReportArea.sistema
        ? 'Sistemas'
        : widget.report.area == ReportArea.mantenimiento
            ? 'Mantenimiento'
            : 'Limpieza';

    final agentName = widget.report.area == ReportArea.sistema
        ? 'Ing. Daniel Ramos'
        : widget.report.area == ReportArea.mantenimiento
            ? 'Ing. Carlos Gómez'
            : 'Coordinadora María Elena';

    _messages.add(
      Message(
        text: 'Hola. Recibimos tu reporte sobre "${widget.report.title}" para el área de $areaName. Soy el técnico asignado ($agentName) y estaré dándole seguimiento a tu caso a través de este chat.',
        isOutgoing: false,
        time: widget.report.dateTime.add(const Duration(minutes: 2)),
      ),
    );

    // 4. If the report is resolved and has evidence, load the resolution messages
    if (_currentReportStatus == ReportStatus.resuelto) {
      _messages.add(
        Message(
          text: 'Reporte marcado como RESUELTO por el técnico. Evidencia de resolución cargada con éxito a Cloudinary.',
          isOutgoing: false,
          time: widget.report.dateTime.add(const Duration(hours: 1)),
          isSystem: true,
        ),
      );

      if (widget.report.evidenceUrl != null && widget.report.evidenceUrl!.isNotEmpty) {
        _messages.add(
          Message(
            text: 'Evidencia de trabajo terminado:',
            isOutgoing: false,
            time: widget.report.dateTime.add(const Duration(hours: 1, minutes: 1)),
            imageUrl: widget.report.evidenceUrl,
          ),
        );
      }

      _messages.add(
        Message(
          text: 'He terminado de atender el reporte y adjunté la foto de evidencia. Si todo está correcto, daremos por concluido este caso. ¡Saludos!',
          isOutgoing: false,
          time: widget.report.dateTime.add(const Duration(hours: 1, minutes: 2)),
        ),
      );
    }
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

  void _sendMessage({String? text, String? imageUrl, bool isAudio = false, String? audioDuration, bool isSystem = false}) {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty && imageUrl == null && !isAudio && !isSystem) return;

    if (text == null && !isSystem) {
      _textController.clear();
    }

    // If a message is typed in this view, it is outgoing (from the currentUser's perspective)
    final actualOutgoing = !isSystem ? true : false; 


    setState(() {
      _messages.add(
        Message(
          text: messageText,
          isOutgoing: actualOutgoing,
          time: DateTime.now(),
          imageUrl: imageUrl,
          isAudio: isAudio,
          audioDuration: audioDuration,
          isSystem: isSystem,
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Only trigger bot auto-reply if the student is typing and report is not resolved
    if (widget.currentUser.role == UserRole.estudiante && _currentReportStatus != ReportStatus.resuelto && !isSystem) {
      _triggerAutoReply(messageText, imageUrl != null, isAudio);
    }
  }

  void _triggerAutoReply(String userMsg, bool isImage, bool isAudio) {
    setState(() {
      _isTyping = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final delayMillis = 1500 + (userMsg.length * 12).clamp(0, 1500);

    Timer(Duration(milliseconds: delayMillis), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;

        String replyText = '';
        final query = userMsg.toLowerCase();

        if (isImage) {
          replyText = 'Gracias por la imagen de referencia. Ya la agregamos al expediente del reporte para que el personal técnico la revise.';
        } else if (isAudio) {
          replyText = 'Mensaje de voz recibido. Nuestro operador de soporte técnico lo escuchará en un momento y te dará respuesta.';
        } else if (query.contains('hola') || query.contains('buen')) {
          replyText = '¡Hola! ¿En qué más te puedo asistir con respecto a este reporte?';
        } else if (query.contains('gracias') || query.contains('excelente')) {
          replyText = '¡De nada! Estamos para servirte. Mantendremos el estado del reporte actualizado.';
        } else if (query.contains('novedad') || query.contains('actualizaci') || query.contains('saber')) {
          replyText = 'El personal técnico ya está asignado al problema en ${widget.report.classroom}. Te notificaremos por este medio cuando se resuelva.';
        } else if (query.contains('urgente') || query.contains('rapido') || query.contains('rápido')) {
          replyText = 'Entendido. He reportado la urgencia al supervisor de área para agilizar la orden de servicio.';
        } else {
          replyText = 'Recibido. He actualizado el registro del reporte con tu comentario.';
        }

        _messages.add(
          Message(
            text: replyText,
            isOutgoing: false,
            time: DateTime.now(),
          ),
        );
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
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
                'Enviar Adjunto para Reporte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    color: Colors.blue.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        text: 'Evidencia fotográfica en tiempo real.',
                        imageUrl: 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=400&auto=format&fit=crop&q=80',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.image_rounded,
                    label: 'Galería',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        text: 'Foto de referencia adjunta.',
                        imageUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=400&auto=format&fit=crop&q=80',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.audiotrack_rounded,
                    label: 'Audio',
                    color: Colors.green.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        text: 'Nota de voz enviada',
                        isAudio: true,
                        audioDuration: '0:12',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.location_on_rounded,
                    label: 'Ubicación',
                    color: Colors.red.shade500,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        text: '📍 Ubicación: ${widget.report.classroom}, ${widget.report.building}',
                      );
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
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _resolveReport() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Show options to pick from Gallery or Camera
    final source = await showModalBottomSheet<ImageSource>(
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
                'Subir Evidencia de Resolución',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Es obligatorio adjuntar una foto para marcar este reporte como Terminado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                          child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text('Cámara', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.withValues(alpha: 0.12),
                          child: const Icon(Icons.photo_library_rounded, color: Colors.blue, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text('Galería', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    // Pick the image
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    // 2. Show upload spinner
    setState(() {
      _isResolving = true;
    });

    try {
      final bytes = await file.readAsBytes();
      
      // Upload to Cloudinary
      final cloudinaryUrl = await _cloudinaryService.uploadImageBytes(
        bytes: bytes,
        fileName: 'res_${widget.report.id}_${file.name}',
      );

      // 3. Update status in local database & in-memory viewmodel
      await _viewModel.updateReportStatus(
        widget.report.id,
        ReportStatus.resuelto,
        evidenceUrl: cloudinaryUrl,
      );

      // Add messages in chat
      _sendMessage(
        text: 'Reporte marcado como RESUELTO por ${widget.currentUser.name}. Evidencia de resolución cargada con éxito a Cloudinary.',
        isSystem: true,
      );

      _sendMessage(
        text: 'Evidencia de trabajo terminado:',
        imageUrl: cloudinaryUrl,
      );

      _sendMessage(
        text: 'He terminado de atender el reporte y adjunté la foto de evidencia. Si todo está correcto, daremos por concluido este caso. ¡Saludos!',
      );

      setState(() {
        _currentReportStatus = ReportStatus.resuelto;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte marcado como Terminado y evidencia guardada.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir evidencia a Cloudinary: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
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
    final textIncomingColor = isDark ? Colors.white.withValues(alpha: 0.85) : AppTheme.secondaryColor;

    final String titleText = widget.report.title;
    final String areaText = widget.report.area == ReportArea.sistema
        ? 'Sistemas'
        : widget.report.area == ReportArea.mantenimiento
            ? 'Mantenimiento'
            : 'Limpieza';

    // Show "Marcar como Terminado" action button for Staff if report is NOT already resolved
    final showResolveButton = widget.currentUser.role != UserRole.estudiante &&
        _currentReportStatus != ReportStatus.resuelto;

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
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Icon(
                    widget.report.area == ReportArea.sistema
                        ? Icons.laptop_mac_rounded
                        : widget.report.area == ReportArea.mantenimiento
                            ? Icons.construction_rounded
                            : Icons.cleaning_services_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1C140E) : AppTheme.backgroundColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.secondaryColor,
                    ),
                  ),
                  Text(
                    _isTyping ? 'escribiendo...' : 'en línea ($areaText)',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isTyping ? Colors.green.shade600 : Colors.grey,
                      fontWeight: _isTyping ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (showResolveButton)
            _isResolving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed: _resolveReport,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Resolver', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade600,
                        backgroundColor: Colors.green.shade600.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF140D09) : const Color(0xFFFAF5F0),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Loading/Uploading cover
              if (_isResolving)
                Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Subiendo evidencia a Cloudinary y terminando reporte...',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chat de Soporte Técnico para reporte: ${widget.report.classroom}. Estado: ${_currentReportStatus.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Messages Chat Area
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(
                      msg,
                      bubbleBgOutgoing,
                      bubbleBgIncoming,
                      textOutgoingColor,
                      textIncomingColor,
                    );
                  },
                ),
              ),

              // Typing Indicator Bouncing dots
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 12, top: 4),
                  child: Row(
                    children: [
                      const TypingIndicator(),
                      const SizedBox(width: 8),
                      Text(
                        'Soporte está respondiendo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick replies pill list
              if (_quickReplies.isNotEmpty && _currentReportStatus != ReportStatus.resuelto)
                Container(
                  height: 42,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _quickReplies.length,
                    itemBuilder: (context, index) {
                      final text = _quickReplies[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          label: Text(
                            text,
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.85) : AppTheme.secondaryColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: isDark ? const Color(0xFF261D16) : Colors.white,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE8E2DA),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () {
                            _sendMessage(text: text);
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Input Send Bar (Bottom)
              if (_currentReportStatus != ReportStatus.resuelto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C140E) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFEFEBE7),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
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
                // Nice Resolution banner instead of input bar
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

  Widget _buildMessageBubble(
    Message msg,
    Color bgOutgoing,
    Color bgIncoming,
    Color textOutColor,
    Color textInColor,
  ) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      );
    }

    final align = msg.isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = msg.isOutgoing ? bgOutgoing : bgIncoming;
    final textColor = msg.isOutgoing ? textOutColor : textInColor;
    final corners = msg.isOutgoing
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(2),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(2),
          );

    final displayTime =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: corners,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        msg.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (msg.isAudio) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: msg.isOutgoing ? Colors.white : AppTheme.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(8, (i) {
                            final heights = [10.0, 16.0, 6.0, 20.0, 14.0, 8.0, 18.0, 12.0];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 3,
                              height: heights[i],
                              decoration: BoxDecoration(
                                color: msg.isOutgoing
                                    ? Colors.white70
                                    : AppTheme.secondaryColor.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          msg.audioDuration ?? '0:00',
                          style: TextStyle(
                            fontSize: 11,
                            color: msg.isOutgoing ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (!msg.isAudio)
                    Text(
                      msg.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.8,
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),
                      Text(
                        displayTime,
                        style: TextStyle(
                          color: msg.isOutgoing
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey.shade500,
                          fontSize: 9.5,
                        ),
                      ),
                      if (msg.isOutgoing) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: -6.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Timer(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
