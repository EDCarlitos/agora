import 'package:flutter/material.dart';
import '../../system/view_models/systems_dashboard_view_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/cloudinary_service.dart';
import '../../../core/theme.dart';
import '../view_models/student_dashboard_view_model.dart';
import '../../common/views/chat_room_view.dart';
import '../../widgets/image_source_bottom_sheet.dart';
import '../../widgets/custom_buttons.dart';
import '../../widgets/agora_network_image.dart';

class ReportDetailView extends StatefulWidget {
  final Report report;
  final User currentUser;

  const ReportDetailView({
    super.key,
    required this.report,
    required this.currentUser,
  });

  @override
  State<ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends State<ReportDetailView> {
  late Report _currentReport;
  bool _isResolving = false;
  final _picker = ImagePicker();
  final _cloudinaryService = CloudinaryService();
  final _viewModel = StudentDashboardViewModel();

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  void _resolveReport() async {
    final source = await ImageSourceBottomSheet.show(context);
    if (source == null) return;

    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    setState(() {
      _isResolving = true;
    });

    try {
      final bytes = await file.readAsBytes();
      final cloudinaryUrl = await _cloudinaryService.uploadImageBytes(
        bytes: bytes,
        fileName: 'res_${_currentReport.id}_${file.name}',
      );

      await _viewModel.updateReportStatus(
        _currentReport.id,
        ReportStatus.resuelto,
        evidenceUrl: cloudinaryUrl,
      );

      setState(() {
        _currentReport = _currentReport.copyWith(
          status: ReportStatus.resuelto,
          evidenceUrl: cloudinaryUrl,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte resuelto exitosamente.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al resolver: $e'),
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
    
    // Consumimos los colores directamente del Theme
    final canvasBg = theme.scaffoldBackgroundColor;
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final ampm = _currentReport.dateTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = _currentReport.dateTime.hour > 12 
        ? _currentReport.dateTime.hour - 12 
        : (_currentReport.dateTime.hour == 0 ? 12 : _currentReport.dateTime.hour);
        
    final dateStr = '${displayHour.toString().padLeft(2, '0')}:${_currentReport.dateTime.minute.toString().padLeft(2, '0')} $ampm, ${_currentReport.dateTime.day} ${months[_currentReport.dateTime.month - 1]} ${_currentReport.dateTime.year}';

    final isStaff = widget.currentUser.role != UserRole.estudiante;
    final isResolved = _currentReport.status == ReportStatus.resuelto;
    final isRejected = _currentReport.status == ReportStatus.rechazado; // <-- NUEVA
    final isMyReport = _currentReport.reportedBy == widget.currentUser.name || _currentReport.reportedBy == widget.currentUser.email;
    final showActionPanel = isStaff || isMyReport;

    return Scaffold(
      backgroundColor: canvasBg,
      appBar: AppBar(
        backgroundColor: canvasBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de Incidencia',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
            fontSize: 19,
            color: AppTheme.secondaryColor,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: _currentReport.imageUrl == null
                      ? Container(
                          color: isDark ? AppTheme.darkSurface : AppTheme.offWhite,
                          child: Center(
                            child: Icon(Icons.image_not_supported_rounded, size: 48, color: Colors.grey.shade400),
                          ),
                        )
                      : AgoraNetworkImage(
                          imageUrl: _currentReport.imageUrl!,
                          height: 240,
                          width: double.infinity,
                          borderRadius: BorderRadius.zero, 
                        ),
                ),
                Container(
                  transform: Matrix4.translationValues(0.0, -18.0, 0.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.offBlack : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _currentReport.title,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? AppTheme.successColor.withValues(alpha: 0.15)
                                  : isRejected 
                                      ? AppTheme.errorColor.withValues(alpha: 0.15)
                                      : _currentReport.status == ReportStatus.enProceso
                                          ? AppTheme.infoColor.withValues(alpha: 0.15)
                                          : AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _currentReport.status.displayName,
                              style: TextStyle(
                                color: isResolved
                                    ? AppTheme.successColor
                                    : isRejected // <-- NUEVO COLOR TEXTO
                                        ? AppTheme.errorColor
                                        : _currentReport.status == ReportStatus.enProceso
                                            ? AppTheme.infoColor
                                            : AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_currentReport.area != null)
                        _buildMetaIconRow(
                          Icons.local_offer_outlined,
                          'Área: ${_currentReport.area!.displayName}',
                          AppTheme.warningColor,
                        ),
                      _buildMetaIconRow(
                        Icons.person_outline_rounded,
                        'Reportado por: ${_currentReport.reportedBy}',
                        isDark ? Colors.white60 : Colors.black54,
                      ),
                      _buildMetaIconRow(
                        Icons.location_on_outlined,
                        'Ubicación: ${_currentReport.classroom}, ${_currentReport.building}',
                        isDark ? Colors.white60 : Colors.black54,
                      ),
                      _buildMetaIconRow(
                        Icons.access_time_outlined,
                        'Fecha: $dateStr',
                        isDark ? Colors.white60 : Colors.black54,
                      ),
                      
                      const SizedBox(height: 16),
                      Divider(color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Detalles del Incidente',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentReport.details,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: isDark ? Colors.white70 : const Color(0xFF555555),
                        ),
                      ),
                      if (isResolved && _currentReport.evidenceUrl != null) ...[
                        const SizedBox(height: 24),
                        Divider(color: isDark ? Colors.white10 : Colors.black12),
                        const SizedBox(height: 16),
                        const Text(
                          'Evidencia de Resolución (Cerrado)',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AgoraNetworkImage(
                          imageUrl: _currentReport.evidenceUrl!,
                          height: 200,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showActionPanel)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.offBlack : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- FILA SUPERIOR: Botones de Acción (Rechazar / Asignarme / Resolver) ---
                    if (isStaff && _currentReport.status == ReportStatus.pendiente) ...[
                      Row(
                        children: [
                          Expanded(
                            child: AgoraSecondaryButton(
                              text: 'Rechazar',
                              icon: Icons.cancel_outlined,
                              color: AppTheme.errorColor,
                              onPressed: () async {
                                final success = await SystemsDashboardViewModel().rejectReport(
                                  int.parse(_currentReport.id),
                                  widget.currentUser
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reporte rechazado y descartado.'), backgroundColor: AppTheme.errorColor),
                                  );
                                  Navigator.pop(context, true); 
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AgoraPrimaryButton(
                              text: 'Asignarme',
                              icon: Icons.assignment_ind_rounded,
                              onPressed: () async {
                                final success = await SystemsDashboardViewModel().assignReportToMe(
                                  int.parse(_currentReport.id),
                                   widget.currentUser
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Incidencia asignada a ti.'), backgroundColor: AppTheme.successColor),
                                  );
                                  Navigator.pop(context, true); 
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), // Espaciado entre la fila superior y el botón de chat
                    ] else if (isStaff && _currentReport.status == ReportStatus.enProceso) ...[
                      AgoraSecondaryButton(
                        text: 'Resolver',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.successColor,
                        onPressed: _isResolving ? null : _resolveReport,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // --- FILA INFERIOR: BOTÓN DE CHAT ---
                    // --- FILA INFERIOR: BOTÓN DE CHAT ---
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AgoraPrimaryButton(
                          text: isResolved ? 'Ver Chat' : 'Abrir Chat',
                          icon: Icons.forum_outlined,
                          // Bloquear el botón si es PENDIENTE o RECHAZADO:
                          onPressed: (_currentReport.status == ReportStatus.pendiente || _currentReport.status == ReportStatus.rechazado)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomView(
                                        report: _currentReport,
                                        currentUser: widget.currentUser,
                                      ),
                                    ),
                                  );
                                },
                        ),
                        if (_currentReport.status == ReportStatus.pendiente)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              isStaff ? 'Asígnate la incidencia para chatear.' : 'En espera de un técnico.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_currentReport.status == ReportStatus.rechazado)
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Reporte rechazado. El chat no está disponible.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppTheme.errorColor,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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

  Widget _buildMetaIconRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
