import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/cloudinary_service.dart';
import '../../../core/theme.dart';
import '../view_models/student_dashboard_view_model.dart';
import 'chat_room_view.dart';
import 'select_category_view.dart';
import 'dart:io';

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
      // Tap index 1 triggers report creation form
      _openCreateReportDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _openCreateReportDialog() async {
    // 1. Abrimos la nueva pantalla y esperamos a que el usuario seleccione una categoría
    final ReportArea? selectedArea = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectCategoryView()),
    );

    // 2. Si regresó un área (le dio a Continuar), abrimos el formulario
    if (selectedArea != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CreateReportBottomSheet(
          reportedBy: widget.user.name,
          initialArea: selectedArea,
          onReportCreated: (title, area, subtype, classroom, building, details, imageUrl) async {
            await _viewModel.addReport(
              title: title,
              area: area,
              subtype: subtype,
              classroom: classroom,
              building: building,
              dateTime: DateTime.now(),
              details: details,
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
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.user.photoUrl != null 
                ? NetworkImage(widget.user.photoUrl!) 
                : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=60'),
            // Si no tiene foto de Google, muestra la de por defecto
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

    final userIncidents = _viewModel.incidents.toList();
    final listLimpieza = userIncidents.where((r) => r.area == ReportArea.limpieza).toList();
    final listSistemas = userIncidents.where((r) => r.area == ReportArea.sistema).toList();
    final listMantenimiento = userIncidents.where((r) => r.area == ReportArea.mantenimiento).toList();

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myIncidents = _viewModel.incidents.where((r) => r.reportedBy == widget.user.name).toList();

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

          // Custom search bar for messages
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D16) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8E2DA),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar chats por reporte...',
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
            'Chats por Reporte',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: isDark ? Colors.white70 : AppTheme.secondaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: myIncidents.isEmpty
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
                            'No tienes chats de reportes aún.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : AppTheme.secondaryColor.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea un nuevo reporte usando el botón "+" para iniciar un canal de comunicación con soporte.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white30 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: myIncidents.length,
                    itemBuilder: (context, index) {
                      final report = myIncidents[index];
                      final timeStr = '${report.dateTime.hour.toString().padLeft(2, '0')}:${report.dateTime.minute.toString().padLeft(2, '0')}';
                      return _buildChatReportChannelItem(report, timeStr);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatReportChannelItem(Report report, String timeStr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon = report.area == ReportArea.sistema
        ? Icons.laptop_mac_rounded
        : report.area == ReportArea.mantenimiento
            ? Icons.construction_rounded
            : Icons.cleaning_services_rounded;

    String statusMsg = '';
    switch (report.status) {
      case ReportStatus.pendiente:
        statusMsg = 'Esperando asignación de personal...';
        break;
      case ReportStatus.enProceso:
        statusMsg = 'Personal operativo asignado y en proceso.';
        break;
      case ReportStatus.resuelto:
        statusMsg = 'Resuelto: El reporte ha sido completado.';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFEBE7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomView(
                  report: report,
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
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
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
                        statusMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: report.status == ReportStatus.pendiente
                              ? AppTheme.primaryColor.withValues(alpha: 0.8)
                              : Colors.grey.shade600,
                          fontWeight: report.status == ReportStatus.pendiente ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: report.status == ReportStatus.resuelto
                            ? Colors.green.shade600.withValues(alpha: 0.15)
                            : report.status == ReportStatus.enProceso
                                ? Colors.blue.shade600.withValues(alpha: 0.15)
                                : AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.status.name.toUpperCase(),
                        style: TextStyle(
                          color: report.status == ReportStatus.resuelto
                              ? Colors.green.shade600
                              : report.status == ReportStatus.enProceso
                                  ? Colors.blue.shade600
                                  : AppTheme.primaryColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
// CREATE REPORT BOTTOM SHEET
// ----------------------------------------------------
// ----------------------------------------------------
// CREATE REPORT BOTTOM SHEET
// ----------------------------------------------------
class CreateReportBottomSheet extends StatefulWidget {
  
  final String reportedBy;
  final ReportArea initialArea; // <-- AQUÍ RECIBE EL ÁREA DE LA PANTALLA ANTERIOR
  final Function(
    String title,
    ReportArea? area,
    String subtype, // <-- AHORA PIDE EL SUBTIPO
    String classroom,
    String building,
    String details,
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
  final _classroomController = TextEditingController();
  final _buildingController = TextEditingController();
  final _detailsController = TextEditingController();

  late ReportArea _reportArea;
  String? _selectedSubtype;
  String? _selectedImageUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  final Map<ReportArea, List<String>> _subtypesOptions = {
    ReportArea.sistema: ['Proyector', 'Cortina de proyector', 'Pantalla', 'Equipo de cómputo', 'Cable HDMI'],
    ReportArea.limpieza: ['Limpieza de aula', 'Retiro de basura', 'Olor', 'Derrame'],
    ReportArea.mantenimiento: ['Pizarrón', 'Sillas', 'Escritorios', 'Puerta', 'Iluminación', 'Cerraduras'],
  };

  final _picker = ImagePicker();
  final _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    // <-- AQUÍ ES DONDE VA EL INIT STATE, SE ASIGNA EL ÁREA ELEGIDA
    _reportArea = widget.initialArea; 
  }

  @override
  void dispose() {
    _titleController.dispose();
    _classroomController.dispose();
    _buildingController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _pickAndUploadImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file == null) return;

      setState(() {
        _selectedImageUrl = file.path; // Guardamos la RUTA LOCAL en la variable
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedSubtype != null) {
      setState(() {
        _isSaving = true;
      });

      widget.onReportCreated(
        _titleController.text,
        _reportArea,
        _selectedSubtype!,
        _classroomController.text,
        _buildingController.text,
        _detailsController.text,
        _selectedImageUrl,
      );

      Navigator.pop(context);
    } else if (_selectedSubtype == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona un Subtipo')),
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
                  Text(
                    'Nuevo reporte de ${_reportArea.displayName}', // <-- Título dinámico
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
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

              // --- NUEVO DROPDOWN DE SUBTIPO ---
              const Text('Subtipo de Incidencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSubtype,
                hint: const Text('Selecciona el problema específico'),
                decoration: const InputDecoration(),
                items: _subtypesOptions[_reportArea]!.map((String subtype) {
                  return DropdownMenuItem<String>(
                    value: subtype,
                    child: Text(subtype),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSubtype = val;
                  });
                },
                validator: (v) => v == null ? 'Selecciona un subtipo' : null,
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
                          // Usamos File de dart:io para leer la ruta local del teléfono
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
// ... aquí sigue el OutlinedButton.icon original
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
