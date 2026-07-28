import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';
import '../view_models/users_view_model.dart';
import 'admin_summary_view.dart';
import 'users_view.dart';

class AdminDashboardShell extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const AdminDashboardShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0; // 0: Resumen, 1: Usuarios
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UsersViewModel _usersViewModel = UsersViewModel();

  void _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir del panel de administración?'),
        actions: [
          AgoraTextButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(context, false),
          ),
          AgoraPrimaryButton(
            text: 'Cerrar Sesión',
            backgroundColor: theme.colorScheme.error,
            onPressed: () => Navigator.pop(context, true),
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
    final titleString = _selectedIndex == 0 ? 'Resumen General' : 'Gestión de Usuarios';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menú principal',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(titleString),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),

      // Drawer (Menú Hamburguesa)
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              accountName: Text(
                widget.user.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.user.email, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.user.role.displayName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: AppTheme.primaryColor),
              title: const Text('Resumen General', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedIndex == 0,
              selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined, color: AppTheme.primaryColor),
              title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedIndex == 1,
              selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment_outlined),
              title: const Text('Reportes e Incidencias'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Pronto',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sección de Reportes en desarrollo para próximas fases.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración del Sistema'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración global del sistema.')),
                );
              },
            ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      // Cuerpo Principal según pestaña seleccionada
      body: _selectedIndex == 0
          ? AdminSummaryView(
              user: widget.user,
              onNavigateToUsers: () => setState(() => _selectedIndex = 1),
            )
          : UsersView(
              currentUser: widget.user,
              viewModel: _usersViewModel,
              onLogout: widget.onLogout,
            ),
    );
  }
}
