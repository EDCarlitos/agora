import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../core/theme.dart';
import '../view_models/users_view_model.dart';
import '../widgets/admin_drawer.dart';
import 'admin_incidencias_table_view.dart';
import 'admin_reports_table_view.dart';
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
  int _selectedIndex = 0; // 0: Resumen, 1: Usuarios, 2: Reportes, 3: Incidencias
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UsersViewModel _usersViewModel = UsersViewModel();

  String get _titleString {
    switch (_selectedIndex) {
      case 0:
        return 'Resumen General';
      case 1:
        return 'Gestión de Usuarios';
      case 2:
        return 'Tabla de Reportes';
      case 3:
        return 'Tabla de Incidencias';
      default:
        return 'Ágora Admin';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return AdminSummaryView(
          user: widget.user,
          onNavigateToUsers: () => setState(() => _selectedIndex = 1),
        );
      case 1:
        return UsersView(
          currentUser: widget.user,
          viewModel: _usersViewModel,
          onLogout: widget.onLogout,
        );
      case 2:
        return const AdminReportsTableView();
      case 3:
        return const AdminIncidenciasTableView();
      default:
        return AdminSummaryView(
          user: widget.user,
          onNavigateToUsers: () => setState(() => _selectedIndex = 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(_titleString),
          ],
        ),
      ),
      drawer: AdminDrawer(
        user: widget.user,
        selectedIndex: _selectedIndex,
        onSelectIndex: (index) => setState(() => _selectedIndex = index),
        onLogout: widget.onLogout,
      ),
      body: _buildBody(),
    );
  }
}
