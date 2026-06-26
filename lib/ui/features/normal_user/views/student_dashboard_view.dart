import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/cloudinary_service.dart';
import '../../../core/theme.dart';
import '../view_models/student_dashboard_view_model.dart';

class StudentDashboardView extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const StudentDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  int _selectedIndex = 0;
  final _viewModel = StudentDashboardViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Tap index 1 triggers report creation form
      _openCreateReportDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _openCreateReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateReportBottomSheet(
        reportedBy: widget.user.name,
        onReportCreated: (title, area, classroom, building, details, imageUrl) async {
          await _viewModel.addReport(
            title: title,
            area: area,
            classroom: classroom,
            building: building,
            dateTime: DateTime.now(),
            details: details,
            reportedBy: widget.user.name,
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final list = _viewModel.notifications;
            return AlertDialog(
              title: const Text('Notificaciones'),
              content: SizedBox(
                width: 320,
                child: list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No tienes notificaciones en este momento.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final n = list[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              n['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(n['body'], style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              n['time'],
                              style: TextStyle(color: theme.hintColor, fontSize: 10),
                            ),
                            leading: CircleAvatar(
                              radius: 4,
                              backgroundColor: n['isRead'] ? Colors.transparent : AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _viewModel.markNotificationsAsRead();
                    Navigator.pop(context);
                  },
                  child: const Text('Marcar como leídas'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportDetail(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailView(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget bodyWidget;
    switch (_selectedIndex) {
      case 0:
        bodyWidget = _buildIncidenciasTab();
        break;
      case 2:
        bodyWidget = _buildChatTab();
        break;
      case 3:
        bodyWidget = _buildCuentaTab();
        break;
      default:
        bodyWidget = _buildIncidenciasTab();
    }

    final unreadCount = _viewModel.notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
        ),
        title: const Text(
          'Agora',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: _showNotificationsDialog,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=60'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => bodyWidget,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEFEBE7),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1C140E) : AppTheme.backgroundColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF8F7A6E),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.report_gmailerrorred_outlined),
              activeIcon: Icon(Icons.report_gmailerrorred_rounded),
              label: 'Incidencias',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 36, color: AppTheme.primaryColor),
              label: 'Agregar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Cuenta',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenciasTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listLimpieza = _viewModel.incidents.where((r) => r.area == ReportArea.limpieza).toList();
    final listSistemas = _viewModel.incidents.where((r) => r.area == ReportArea.sistema).toList();
    final listMantenimiento = _viewModel.incidents.where((r) => r.area == ReportArea.mantenimiento).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF140D09) : const Color(0xFF33261C),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reportes Recientes',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 3; // Swapped to account tab index (3 instead of 4)
                          });
                        },
                        child: const Text(
                          'Ver todos',
                          style: TextStyle(color: Color(0xFFFBBF24), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _viewModel.incidents.take(4).length,
                    itemBuilder: (context, index) {
                      final item = _viewModel.incidents[index];
                      return _buildRecentCard(item);
                    },
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Limpieza'),
                const SizedBox(height: 8),
                if (listLimpieza.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No hay reportes de Limpieza activos.'),
                  )
                else
                  ...listLimpieza.take(2).map((r) => _buildCategoryCard(r, Icons.cleaning_services_outlined, const Color(0xFFFBBF24))),

                const SizedBox(height: 20),

                _buildSectionHeader('Sistemas'),
                const SizedBox(height: 8),
                if (listSistemas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No hay reportes de Sistemas activos.'),
                  )
                else
                  ...listSistemas.take(2).map((r) => _buildCategoryCard(r, Icons.computer_outlined, const Color(0xFF3B82F6))),

                const SizedBox(height: 20),

                _buildSectionHeader('Mantenimiento'),
                const SizedBox(height: 8),
                if (listMantenimiento.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No hay reportes de Mantenimiento activos.'),
                  )
                else
                  ...listMantenimiento.take(2).map((r) => _buildCategoryCard(r, Icons.build_outlined, const Color(0xFFEF4444))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Mensajes y Soporte',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _buildChatChannelItem(
                  'Soporte Técnico (Sistemas)',
                  'Hola, revisaremos la conexión WiFi en la biblioteca hoy por la tarde.',
                  '10:32 AM',
                  true,
                ),
                _buildChatChannelItem(
                  'Administración de Mantenimiento',
                  'El reporte del proyector en el aula 302 ha sido resuelto.',
                  'Ayer',
                  false,
                ),
                _buildChatChannelItem(
                  'Limpieza - Coordinación',
                  'Recibido, enviaremos personal a limpiar el derrame.',
                  '25 Oct',
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatChannelItem(String title, String lastMsg, String time, bool unread) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          lastMsg,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: unread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: TextStyle(color: theme.hintColor, fontSize: 10)),
            if (unread) ...[
              const SizedBox(height: 4),
              const CircleAvatar(radius: 4, backgroundColor: AppTheme.primaryColor),
            ],
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat con "$title" abierto (UI Prototipo)')),
          );
        },
      ),
    );
  }

  Widget _buildCuentaTab() {
    final theme = Theme.of(context);
    final myReports = _viewModel.getMyReports(widget.user.name);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=60'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.user.email,
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.user.role.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Reportes Publicados (${myReports.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (myReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No has publicado ningún reporte aún.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myReports.length,
              itemBuilder: (context, index) {
                final report = myReports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      report.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text('${report.building} - ${report.classroom}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: report.status == ReportStatus.resuelto
                            ? Colors.green.withOpacity(0.1)
                            : report.status == ReportStatus.enProceso
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        report.status.displayName,
                        style: TextStyle(
                          color: report.status == ReportStatus.resuelto
                              ? Colors.green
                              : report.status == ReportStatus.enProceso
                                  ? Colors.blue
                                  : Colors.amber.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () => _showReportDetail(report),
                  ),
                );
              },
            ),

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: () async {
              await AuthService().logout();
              widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        Text(
          'Ver todos',
          style: TextStyle(color: AppTheme.primaryColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentCard(Report report) {
    return GestureDetector(
      onTap: () => _showReportDetail(report),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF261A12),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: report.imageUrl == null
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF1E3A8A).withOpacity(0.5),
                            const Color(0xFF3B82F6).withOpacity(0.2),
                          ],
                        )
                      : null,
                  image: report.imageUrl != null
                      ? DecorationImage(image: NetworkImage(report.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: report.imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.settings_input_hdmi_rounded,
                          color: Colors.blue.shade200,
                          size: 32,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white60, size: 12),
                const SizedBox(width: 4),
                Text(
                  report.classroom,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Report report, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: report.imageUrl == null ? color.withOpacity(0.12) : null,
            borderRadius: BorderRadius.circular(8),
            image: report.imageUrl != null
                ? DecorationImage(image: NetworkImage(report.imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: report.imageUrl == null ? Icon(icon, color: color) : null,
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(report.classroom, style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: const Text(
          'Hace 2h',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onTap: () => _showReportDetail(report),
      ),
    );
  }
}

// ----------------------------------------------------
// CREATE REPORT BOTTOM SHEET
// ----------------------------------------------------
class CreateReportBottomSheet extends StatefulWidget {
  final String reportedBy;
  final Function(
    String title,
    ReportArea? area,
    String classroom,
    String building,
    String details,
    String? imageUrl,
  ) onReportCreated;

  const CreateReportBottomSheet({
    super.key,
    required this.reportedBy,
    required this.onReportCreated,
  });

  @override
  State<CreateReportBottomSheet> createState() => _CreateReportBottomSheetState();
}

class _CreateReportBottomSheetState extends State<CreateReportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _classroomController = TextEditingController();
  final _buildingController = TextEditingController();
  final _detailsController = TextEditingController();

  ReportArea _reportArea = ReportArea.sistema;
  bool _isSaving = false;
  String? _selectedImageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _classroomController.dispose();
    _buildingController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  final _picker = ImagePicker();
  final _cloudinaryService = CloudinaryService();

  void _pickAndUploadImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() {
        _isUploading = true;
      });

      final bytes = await file.readAsBytes();
      final url = await _cloudinaryService.uploadImageBytes(
        bytes: bytes,
        fileName: file.name,
      );

      setState(() {
        _selectedImageUrl = url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      widget.onReportCreated(
        _titleController.text,
        _reportArea,
        _classroomController.text,
        _buildingController.text,
        _detailsController.text,
        _selectedImageUrl,
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Crear Nuevo Registro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              const Text('Nombre del Reporte / Incidencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Gotera en laboratorio o Proyector sin señal',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),

              const Text('Área Responsable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<ReportArea>(
                initialValue: _reportArea,
                decoration: const InputDecoration(),
                items: ReportArea.values.map((area) {
                  return DropdownMenuItem<ReportArea>(
                    value: area,
                    child: Text(area.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _reportArea = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edificio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _buildingController,
                          decoration: const InputDecoration(hintText: 'Ej: Edificio C'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aula', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _classroomController,
                          decoration: const InputDecoration(hintText: 'Ej: Aula 102'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Imagen de Referencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (_isUploading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_selectedImageUrl != null)
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_selectedImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImageUrl = null;
                          });
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Subir Imagen a Cloudinary'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              const SizedBox(height: 16),

              const Text('Detalles del Reporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Explica los detalles sobre el incidente...',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa los detalles' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: const Text('Publicar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// FULL-SCREEN DETAIL VIEW (CLONE OF INCIDENT DETAIL IMAGE)
// ----------------------------------------------------
class ReportDetailView extends StatelessWidget {
  final Report report;

  const ReportDetailView({super.key, required this.report});

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
    final ampm = report.dateTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = report.dateTime.hour > 12 
        ? report.dateTime.hour - 12 
        : (report.dateTime.hour == 0 ? 12 : report.dateTime.hour);
    final dateStr = '${displayHour.toString().padLeft(2, '0')}:${report.dateTime.minute.toString().padLeft(2, '0')} $ampm, ${report.dateTime.day} ${months[report.dateTime.month - 1]} ${report.dateTime.year}';

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
          'Incident Report',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
            fontSize: 19,
            color: AppTheme.secondaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF261D16) : const Color(0xFFEFEBE7),
                image: report.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(report.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: report.imageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.report_gmailerrorred_rounded,
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
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (report.area != null)
                    _buildMetaIconRow(
                      Icons.local_offer_outlined,
                      report.area!.displayName,
                      const Color(0xFFD97706),
                    ),
                  _buildMetaIconRow(
                    Icons.person_outline_rounded,
                    report.reportedBy,
                    isDark ? Colors.white60 : Colors.black54,
                  ),
                  _buildMetaIconRow(
                    Icons.location_on_outlined,
                    '${report.classroom}, ${report.building}',
                    isDark ? Colors.white60 : Colors.black54,
                  ),
                  _buildMetaIconRow(
                    Icons.access_time_outlined,
                    dateStr,
                    isDark ? Colors.white60 : Colors.black54,
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEFEBE7)),
                  const SizedBox(height: 20),

                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.details,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Ubicación',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${report.classroom}, ${report.building}. Piso 3, al final del pasillo a la derecha.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF555555),
                    ),
                  ),
                  
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Volver al Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
