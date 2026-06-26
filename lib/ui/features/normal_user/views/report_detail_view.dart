import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/cloudinary_service.dart';
import '../../../core/theme.dart';
import '../view_models/student_dashboard_view_model.dart';
import 'chat_room_view.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
    
    final bgDark = const Color(0xFF140D09);
    final bgLight = const Color(0xFFFAF5F0);
    final canvasBg = isDark ? bgDark : bgLight;

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
                // Original report image card
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF261D16) : const Color(0xFFEFEBE7),
                    image: _currentReport.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_currentReport.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _currentReport.imageUrl == null
                      ? Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        )
                      : null,
                ),

                Container(
                  transform: Matrix4.translationValues(0.0, -18.0, 0.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C140E) : Colors.white,
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
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? Colors.green.shade600.withValues(alpha: 0.15)
                                  : _currentReport.status == ReportStatus.enProceso
                                      ? Colors.blue.shade600.withValues(alpha: 0.15)
                                      : AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _currentReport.status.displayName,
                              style: TextStyle(
                                color: isResolved
                                    ? Colors.green.shade600
                                    : _currentReport.status == ReportStatus.enProceso
                                        ? Colors.blue.shade600
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
                          const Color(0xFFD97706),
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
                      const Divider(color: Color(0xFFEFEBE7)),
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

                      // New Section: Resolution Evidence
                      if (isResolved && _currentReport.evidenceUrl != null) ...[
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFEFEBE7)),
                        const SizedBox(height: 16),
                        const Text(
                          'Evidencia de Resolución (Cerrado)',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            color: isDark ? const Color(0xFF261D16) : const Color(0xFFF5F2EE),
                            child: Image.network(
                              _currentReport.evidenceUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Buttons Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C140E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Resolve button for staff when pending/in-progress
                  if (isStaff && !isResolved) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isResolving ? null : _resolveReport,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Resolver'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade600,
                          side: BorderSide(color: Colors.green.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Main Chat Room button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
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
                      icon: const Icon(Icons.forum_outlined, size: 18),
                      label: Text(isResolved ? 'Ver Chat' : 'Abrir Chat de Soporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resolution progress overlay
          if (_isResolving)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Subiendo evidencia a Cloudinary...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
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
