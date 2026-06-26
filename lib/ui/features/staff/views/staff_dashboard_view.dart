import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../normal_user/view_models/student_dashboard_view_model.dart';
import '../../normal_user/views/chat_room_view.dart';

class StaffDashboardView extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const StaffDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<StaffDashboardView> createState() => _StaffDashboardViewState();
}

class _StaffDashboardViewState extends State<StaffDashboardView> {
  int _selectedIndex = 0;
  final _viewModel = StudentDashboardViewModel(); // Shared singleton instance

  // Map the staff user role to the corresponding ReportArea
  ReportArea get _staffArea {
    switch (widget.user.role) {
      case UserRole.limpieza:
        return ReportArea.limpieza;
      case UserRole.mantenimiento:
        return ReportArea.mantenimiento;
      case UserRole.sistemas:
      default:
        return ReportArea.sistema;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      widget.onLogout();
    }
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
      case 1:
        bodyWidget = _buildChatTab();
        break;
      case 2:
      default:
        bodyWidget = _buildCuentaTab();
    }

    final String roleName = widget.user.role.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agora - $roleName',
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Incidencias',
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

    // Filter reports of their corresponding area
    final departmentIncidents = _viewModel.incidents.where((r) => r.area == _staffArea).toList();

    final pendingList = departmentIncidents.where((r) => r.status == ReportStatus.pendiente).toList();
    final inProgressList = departmentIncidents.where((r) => r.status == ReportStatus.enProceso).toList();
    final resolvedList = departmentIncidents.where((r) => r.status == ReportStatus.resuelto).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF140D09) : const Color(0xFF33261C),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asignaciones de ${_staffArea.displayName}',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tienes ${pendingList.length + inProgressList.length} reportes activos por atender.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inProgressList.isNotEmpty) ...[
                  _buildSectionHeader('En Proceso (${inProgressList.length})'),
                  const SizedBox(height: 8),
                  ...inProgressList.map((r) => _buildCategoryCard(r, Icons.play_circle_outline_rounded, Colors.blue.shade600)),
                  const SizedBox(height: 20),
                ],

                _buildSectionHeader('Pendientes (${pendingList.length})'),
                const SizedBox(height: 8),
                if (pendingList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No hay reportes nuevos pendientes.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                else
                  ...pendingList.map((r) => _buildCategoryCard(r, Icons.error_outline_rounded, AppTheme.primaryColor)),

                const SizedBox(height: 20),

                _buildSectionHeader('Resueltos (${resolvedList.length})'),
                const SizedBox(height: 8),
                if (resolvedList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No has resuelto reportes recientemente.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                else
                  ...resolvedList.take(5).map((r) => _buildCategoryCard(r, Icons.check_circle_outline_rounded, Colors.green.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: isDark ? Colors.white70 : AppTheme.secondaryColor.withOpacity(0.8),
      ),
    );
  }

  Widget _buildCategoryCard(Report report, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFEBE7),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
        ),
        subtitle: Text(
          '${report.classroom} • ${report.building}\nReportado por: ${report.reportedBy}',
          style: TextStyle(color: theme.hintColor, fontSize: 12, height: 1.3),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.hintColor),
        isThreeLine: true,
        onTap: () {
          // Tapping navigating to Chat Room to chat and resolve!
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
      ),
    );
  }

  Widget _buildChatTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter reports in their area for chatting
    final departmentIncidents = _viewModel.incidents.where((r) => r.area == _staffArea).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Mensajes de Soporte',
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
            'Chats del Departamento',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: isDark ? Colors.white70 : AppTheme.secondaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: departmentIncidents.isEmpty
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
                            'No hay chats asignados hoy.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : AppTheme.secondaryColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: departmentIncidents.length,
                    itemBuilder: (context, index) {
                      final report = departmentIncidents[index];
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
        statusMsg = 'Pendiente de atención.';
        break;
      case ReportStatus.enProceso:
        statusMsg = 'En proceso de solución.';
        break;
      case ReportStatus.resuelto:
        statusMsg = 'Resuelto y cerrado.';
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
    final myReports = _viewModel.incidents.where((r) => r.area == _staffArea).toList();
    final resolvedCount = myReports.where((r) => r.status == ReportStatus.resuelto).length;

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
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                    child: const Icon(Icons.engineering_rounded, size: 30, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                        ),
                        Text(
                          widget.user.email,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.user.role.displayName.toUpperCase(),
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

          const Text(
            'Estadísticas de Servicio',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Asignados', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                          '${myReports.length}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Resueltos', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                          '$resolvedCount',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
