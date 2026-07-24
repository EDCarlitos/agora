import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_form_elements.dart';
import '../view_models/student_dashboard_view_model.dart';
import 'chat_room_view.dart';
import 'select_category_view.dart';
import 'report_detail_view.dart'; // Importamos la vista de detalle correcta

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

  void _onItemTapped(int index) {
    if (index == 1) {
      _openCreateReportDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _openCreateReportDialog() async {
    final ReportArea? selectedArea = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectCategoryView()),
    );

    if (selectedArea != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CreateReportBottomSheet(
          reportedBy: widget.user.name,
          initialArea: selectedArea,
          onReportCreated: (title, details, idEdificio, idAula, imageUrl) async {
            await _viewModel.addReport(
              title: title,
              details: details,
              idEdificio: idEdificio,
              idAula: idAula,
              reportedBy: widget.user.name,
              imagePath: imageUrl,
            );
          },
        ),
      );
    }
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
        builder: (context) => ReportDetailView(report: report, currentUser: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = _viewModel.notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ágora',
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
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.user.photoUrl != null
                ? NetworkImage(widget.user.photoUrl!)
                : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=60'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
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
          return bodyWidget;
        },
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
    final userIncidents = _viewModel.incidents.toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.offBlack : AppTheme.secondaryColor,
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
                            _selectedIndex = 3;
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
                  child: userIncidents.isEmpty
                      ? const Center(child: Text('No hay reportes', style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: userIncidents.take(4).length,
                          itemBuilder: (context, index) {
                            final item = userIncidents[index];
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
                _buildSectionHeader('Incidencias de Sistemas'),
                const SizedBox(height: 8),
                if (userIncidents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No hay reportes activos.'),
                  )
                else
                  ...userIncidents.map((r) => _buildCategoryCard(r, Icons.computer_outlined, const Color(0xFF3B82F6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final misChatsApi = _viewModel.chats; // Usamos los chats de la API

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Mensajes y Soporte',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D16) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8E2DA),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar chats...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 13.5,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tus Chats Activos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: isDark ? Colors.white70 : AppTheme.secondaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _viewModel.isLoadingChats 
              ? const Center(child: CircularProgressIndicator())
              : misChatsApi.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes chats de soporte aún.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : AppTheme.secondaryColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: misChatsApi.length,
                    itemBuilder: (context, index) {
                      return _buildChatChannelItem(misChatsApi[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatChannelItem(dynamic chat) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Extraemos la info del JSON de la API
    final int incidenciaId = chat['id'];
    final String titulo = chat['titulo'] ?? 'Sin título';
    final String aula = chat['aula'] ?? 'Sin ubicación';
    final String adminAsignado = chat['usuarioAdministrativo'] ?? 'Personal asignado';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFEBE7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Pasamos un objeto "mock" de reporte para no romper el ChatRoomView actual.
            // En el próximo paso, conectaremos ChatRoomView a la API GET /chats/:id
            final mockReport = Report(
              id: incidenciaId.toString(),
              title: titulo,
              classroom: aula,
              building: '', 
              dateTime: DateTime.now(),
              details: '',
              status: ReportStatus.enProceso,
              reportedBy: widget.user.name,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomView(
                  report: mockReport,
                  currentUser: widget.user,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                  child: const Icon(Icons.support_agent_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.2,
                          color: isDark ? Colors.white : AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Atendido por: $adminAsignado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EN CURSO',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildCuentaTab() {
    final theme = Theme.of(context);
    
    // Le pasamos tu usuario completo para que aplique la condición
    final myReports = _viewModel.getMyReports(widget.user);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de Perfil
          Card(
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: widget.user.photoUrl != null
                        ? NetworkImage(widget.user.photoUrl!)
                        : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=60'),
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
          
          // --- RESTAURADO: Sección de Mis Reportes ---
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
          // --- FIN DE SECCIÓN RESTAURADA ---

          const SizedBox(height: 48),
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
          color: AppTheme.darkSurface,
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
// CREATE REPORT BOTTOM SHEET (VERSIÓN CORRECTA)
// ----------------------------------------------------
class CreateReportBottomSheet extends StatefulWidget {
  final String reportedBy;
  final ReportArea initialArea; 
  final Function(
    String title,
    String details,
    int idEdificio,
    int idAula,
    String? imageUrl,
  ) onReportCreated;

  const CreateReportBottomSheet({
    super.key,
    required this.reportedBy,
    required this.initialArea,
    required this.onReportCreated,
  });

  @override
  State<CreateReportBottomSheet> createState() => _CreateReportBottomSheetState();
}

class _CreateReportBottomSheetState extends State<CreateReportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  
  bool _isSaving = false;
  String? _selectedImageUrl;
  final _picker = ImagePicker();
  
  final _viewModel = StudentDashboardViewModel();
  int? _selectedEdificioId;
  int? _selectedAulaId;

  @override
  void initState() {
    super.initState();
    _viewModel.loadUbicaciones();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _pickAndUploadImage() async {
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
                'Seleccionar Origen de Imagen',
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
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
                          backgroundColor: Colors.blue.withOpacity(0.12),
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

    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;

      setState(() {
        _selectedImageUrl = file.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error o permiso denegado: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedEdificioId != null && _selectedAulaId != null) {
      setState(() {
        _isSaving = true;
      });

      widget.onReportCreated(
        _titleController.text,
        _detailsController.text,
        _selectedEdificioId!,
        _selectedAulaId!,
        _selectedImageUrl,
      );
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos de ubicación')),
      );
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
                    'Nuevo reporte de Sistemas', 
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
              
              const CustomLabel(text: 'Título de Reporte'),
              CustomTextField(
                controller: _titleController,
                hintText: 'Ej: Proyector sin señal',
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el título de tu reporte' : null,
              ),
              const SizedBox(height: 16),
              
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  if (_viewModel.isLoadingUbicaciones) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                  }

                  final aulasDisponibles = _selectedEdificioId != null 
                      ? _viewModel.getAulasPorEdificio(_selectedEdificioId!) 
                      : [];

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomLabel(text: 'Edificio'),
                            CustomDropdown<int>(
                              value: _selectedEdificioId,
                              hintText: 'Ej: Edificio C',
                              items: _viewModel.edificios.map<DropdownMenuItem<int>>((edif) {
                                return DropdownMenuItem<int>(
                                  value: edif['id'],
                                  child: Text(edif['nombre'], overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedEdificioId = val;
                                  _selectedAulaId = null;
                                });
                              },
                              validator: (v) => v == null ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomLabel(text: 'Aula'),
                            CustomDropdown<int>(
                              value: _selectedAulaId,
                              hintText: 'Ej: Aula 102',
                              items: aulasDisponibles.map<DropdownMenuItem<int>>((aula) {
                                return DropdownMenuItem<int>(
                                  value: aula['id'],
                                  child: Text(aula['nombre'], overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: _selectedEdificioId == null ? null : (val) {
                                setState(() {
                                  _selectedAulaId = val;
                                });
                              },
                              validator: (v) => v == null ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 16),
              
              const CustomLabel(text: 'Imagen de Referencia'),
              if (_selectedImageUrl != null)
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImageUrl!)), 
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
                  label: const Text('Subir Imagen de Referencia'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              const SizedBox(height: 16),
              
              const CustomLabel(text: 'Detalles del Reporte'),
              CustomTextField(
                controller: _detailsController,
                hintText: 'Explica los detalles sobre el incidente...',
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa los detalles' : null,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Publicar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}